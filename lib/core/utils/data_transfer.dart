import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import 'package:cashpilot/core/constants/app_constants.dart';
import 'package:cashpilot/data/database/database_helper.dart';
import 'package:cashpilot/data/models/account_model.dart';
import 'package:cashpilot/data/models/category_model.dart';
import 'package:cashpilot/data/models/transaction_model.dart';
import 'package:cashpilot/providers/account_provider.dart';
import 'package:cashpilot/providers/budget_provider.dart';
import 'package:cashpilot/providers/category_provider.dart';
import 'package:cashpilot/providers/goal_provider.dart';
import 'package:cashpilot/providers/settings_provider.dart';
import 'package:cashpilot/providers/transaction_provider.dart';

/// One transaction row read from a CSV file (names, not ids).
class CsvTx {
  final TransactionType type;
  final double amount;
  final DateTime date;
  final String category; // empty for transfers
  final String account; // source account for transfers
  final String? toAccount;
  final String? note;
  const CsvTx({
    required this.type,
    required this.amount,
    required this.date,
    required this.category,
    required this.account,
    this.toAccount,
    this.note,
  });
}

class CsvParseResult {
  final List<CsvTx> rows;
  final int skipped;

  /// "(=) Opening Balance" rows: account name -> amount (may be negative).
  final Map<String, double> openings;
  const CsvParseResult(this.rows, this.skipped, [this.openings = const {}]);
}

class ImportResult {
  final int added;
  final int skipped;
  final String kind;
  const ImportResult(this.added, this.skipped, this.kind);
}

/// Export (CSV / JSON backup) and import (JSON backup or CSV) of app data.
class DataTransfer {
  static const _uuid = Uuid();
  static const _backupTables = ['accounts', 'categories', 'transactions', 'budgets', 'goals'];
  static const _csvHeader = ['TIME', 'TYPE', 'AMOUNT', 'CATEGORY', 'ACCOUNT', 'NOTES'];

  /// TYPE label of the per-account opening balance rows.
  static const openingTypeLabel = '(=) Opening Balance';

  // ── Reload ───────────────────────────────────────────────────────────────

  static Future<void> reloadAll(BuildContext context) => reloader(context)();

  /// Captures providers now so the reload can run after async gaps.
  static Future<void> Function() reloader(BuildContext context) {
    final loaders = <Future<void> Function()>[
      context.read<TransactionProvider>().loadTransactions,
      context.read<AccountProvider>().loadAccounts,
      context.read<CategoryProvider>().loadCategories,
      context.read<BudgetProvider>().loadBudgets,
      context.read<GoalProvider>().loadGoals,
      context.read<SettingsProvider>().reloadReminders,
    ];
    return () => Future.wait(loaders.map((f) => f()));
  }

  // ── Export ───────────────────────────────────────────────────────────────

  static String _quotedCell(String v) => '"${v.replaceAll('"', '""')}"';

  static String _exportTypeLabel(TransactionType type) {
    switch (type) {
      case TransactionType.income:
        return '(+) Income';
      case TransactionType.expense:
        return '(-) Expense';
      case TransactionType.transfer:
        return '(*) Transfer';
    }
  }

  static String buildCsv(
    List<TransactionModel> txs,
    List<AccountModel> accounts,
    List<CategoryModel> categories,
  ) {
    final accName = {for (final a in accounts) a.id: a.name};
    final catName = {for (final c in categories) c.id: c.name};
    final b = StringBuffer()..writeln(_csvHeader.map(_quotedCell).join(','));
    final sorted = [...txs]..sort((a, c) => a.date.compareTo(c.date));
    final timeFmt = DateFormat('MMM dd, yyyy h:mm a', 'en_US');

    // Opening balance = current balance minus what the transactions explain.
    // Written first so re-importing the file reproduces the balances.
    final net = <String, double>{};
    for (final t in txs) {
      addBalanceDelta(net, t.type, t.amount, t.accountId, t.toAccountId);
    }
    final openingTime = sorted.isEmpty
        ? DateTime.now()
        : sorted.first.date.subtract(const Duration(minutes: 1));
    for (final a in accounts) {
      final opening = a.balance - (net[a.id] ?? 0);
      if (opening.abs() < 0.005) continue;
      b.writeln([
        timeFmt.format(openingTime),
        openingTypeLabel,
        opening.toStringAsFixed(2),
        '  -  ',
        a.name,
        '',
      ].map(_quotedCell).join(','));
    }

    for (final t in sorted) {
      final fromAcc = accName[t.accountId] ?? '';
      final toAcc = t.toAccountId != null ? (accName[t.toAccountId] ?? '') : '';
      final accountCol = t.type == TransactionType.transfer && toAcc.isNotEmpty
          ? '$fromAcc->$toAcc'
          : fromAcc;
      final categoryCol = t.type == TransactionType.transfer
          ? '  -  '
          : (catName[t.categoryId] ?? '');
      b.writeln([
        timeFmt.format(t.date),
        _exportTypeLabel(t.type),
        t.amount.toStringAsFixed(2),
        categoryCol,
        accountCol,
        t.note ?? '',
      ].map(_quotedCell).join(','));
    }
    return b.toString();
  }

  /// Column names of the transactions CSV (same for export and import).
  static List<String> get csvColumns => List.unmodifiable(_csvHeader);

  /// A ready-to-fill import template in exactly the export format, with one
  /// example row per transaction type.
  static String buildTemplateCsv() {
    const samples = [
      ['Nov 01, 2026 9:00 AM', '(+) Income', '30000.00', 'Salary', 'Bank', ''],
      ['Nov 01, 2026 1:30 PM', '(-) Expense', '120.00', 'Food', 'Cash', 'lunch'],
      ['Nov 02, 2026 7:45 PM', '(*) Transfer', '1000.00', '  -  ', 'Bank->Cash', ''],
      ['Nov 03, 2026 8:15 PM', '(-) Expense', '525.00', 'Bills', 'Bank', 'internet'],
    ];
    final b = StringBuffer()..writeln(_csvHeader.map(_quotedCell).join(','));
    for (final r in samples) {
      b.writeln(r.map(_quotedCell).join(','));
    }
    return b.toString();
  }

  static Future<String> buildBackupJson() async {
    final db = await DatabaseHelper.instance.database;
    final data = <String, dynamic>{
      'app': AppConstants.appName,
      'format': 1,
      'version': AppConstants.appVersion,
      'exportedAt': DateTime.now().toIso8601String(),
    };
    for (final t in _backupTables) {
      data[t] = await db.query(t);
    }
    return const JsonEncoder.withIndent('  ').convert(data);
  }

  /// Writes [content] to a temp file and opens the system share sheet.
  /// [origin] anchors the sheet (required on iPad / recent iOS).
  static Future<void> shareFile(String fileName, String content, {required Rect origin, String? text}) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$fileName');
    await file.writeAsString(content);
    await Share.shareXFiles(
      [XFile(file.path, mimeType: fileName.endsWith('.json') ? 'application/json' : 'text/csv')],
      text: text,
      sharePositionOrigin: origin,
    );
  }

  static String stamp() => DateFormat('yyyyMMdd_HHmm').format(DateTime.now());

  // ── Import ───────────────────────────────────────────────────────────────

  /// Lets the user pick a .json backup or .csv file and imports it.
  /// Returns null if the user cancelled.
  static Future<ImportResult?> pickAndImport() async {
    final picked = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['json', 'csv'],
      withData: true,
    );
    if (picked == null || picked.files.isEmpty) return null;
    final f = picked.files.single;
    final bytes = f.bytes ?? (f.path != null ? await File(f.path!).readAsBytes() : null);
    if (bytes == null) throw const FormatException('Could not read the selected file');
    final text = utf8.decode(bytes, allowMalformed: true).replaceFirst('﻿', '');
    final name = f.name.toLowerCase();
    if (name.endsWith('.json') || text.trimLeft().startsWith('{')) {
      return _importBackup(text);
    }
    return _importCsv(text);
  }

  static Future<ImportResult> _importBackup(String text) async {
    final data = jsonDecode(text);
    if (data is! Map<String, dynamic> || data['transactions'] is! List) {
      throw const FormatException('This is not a CashPilot backup file');
    }
    final db = await DatabaseHelper.instance.database;
    var added = 0;
    await db.transaction((txn) async {
      for (final t in _backupTables) {
        final rows = data[t];
        if (rows is! List) continue;
        for (final r in rows) {
          if (r is Map<String, dynamic>) {
            await txn.insert(t, r, conflictAlgorithm: ConflictAlgorithm.replace);
            if (t == 'transactions') added++;
          }
        }
      }
    });
    return ImportResult(added, 0, 'backup');
  }

  static List<List<String>> _parseCsv(String text) {
    final rows = <List<String>>[];
    var row = <String>[];
    final cell = StringBuffer();
    var quoted = false;
    for (var i = 0; i < text.length; i++) {
      final ch = text[i];
      if (quoted) {
        if (ch == '"') {
          if (i + 1 < text.length && text[i + 1] == '"') {
            cell.write('"');
            i++;
          } else {
            quoted = false;
          }
        } else {
          cell.write(ch);
        }
      } else if (ch == '"') {
        quoted = true;
      } else if (ch == ',') {
        row.add(cell.toString());
        cell.clear();
      } else if (ch == '\n' || ch == '\r') {
        if (ch == '\r' && i + 1 < text.length && text[i + 1] == '\n') i++;
        row.add(cell.toString());
        cell.clear();
        if (row.any((c) => c.trim().isNotEmpty)) rows.add(row);
        row = <String>[];
      } else {
        cell.write(ch);
      }
    }
    if (cell.isNotEmpty || row.isNotEmpty) {
      row.add(cell.toString());
      if (row.any((c) => c.trim().isNotEmpty)) rows.add(row);
    }
    return rows;
  }

  static TransactionType? _parseType(String raw) {
    final lower = raw.toLowerCase();
    if (lower.contains('income')) return TransactionType.income;
    if (lower.contains('expense')) return TransactionType.expense;
    if (lower.contains('transfer')) return TransactionType.transfer;
    return null;
  }

  static DateTime? _parseDateTime(String rawTime, String rawDate) {
    final t = rawTime.trim();
    if (rawDate.isEmpty && t.isNotEmpty) {
      for (final pattern in [
        'MMM dd, yyyy h:mm a',
        'MMM d, yyyy h:mm a',
        'MMM dd, yyyy hh:mm a',
        'yyyy-MM-dd HH:mm',
        'yyyy-MM-dd',
      ]) {
        try {
          return DateFormat(pattern, 'en_US').parse(t);
        } catch (_) {}
      }
      return DateTime.tryParse(t);
    }
    final d = DateTime.tryParse(rawDate.trim());
    if (d == null) return null;
    final parts = t.split(':');
    if (parts.length == 2) {
      return DateTime(d.year, d.month, d.day, int.tryParse(parts[0]) ?? 0,
          int.tryParse(parts[1]) ?? 0);
    }
    return d;
  }

  /// Parses a transactions CSV (the export format) into rows. Rows with an
  /// unknown type, bad amount, unreadable time or a transfer without a
  /// destination are counted in [CsvParseResult.skipped].
  static CsvParseResult parseTransactionsCsv(String text) {
    final rows = _parseCsv(text.replaceFirst('﻿', ''));
    if (rows.length < 2) throw const FormatException('The CSV file has no rows');
    final header = rows.first.map((h) => h.trim().toLowerCase()).toList();
    int col(String name) => header.indexOf(name);
    final iDate = col('date'), iTime = col('time'), iType = col('type'), iCat = col('category');
    final iAcc = col('account'), iTo = col('to account'), iAmt = col('amount');
    final iNote = col('notes') >= 0
        ? col('notes')
        : (col('note') >= 0 ? col('note') : col('description'));
    if ((iDate < 0 && iTime < 0) || iType < 0 || iAmt < 0) {
      throw const FormatException('CSV needs TIME/DATE, TYPE and AMOUNT columns');
    }

    String cell(List<String> r, int i) => i >= 0 && i < r.length ? r[i].trim() : '';
    final out = <CsvTx>[];
    final openings = <String, double>{};
    var skipped = 0;
    for (final r in rows.skip(1)) {
      if (cell(r, iType).toLowerCase().contains('opening')) {
        final amount = double.tryParse(cell(r, iAmt).replaceAll(RegExp(r'[^0-9.\-]'), ''));
        final acc = cell(r, iAcc);
        if (amount == null || acc.isEmpty) {
          skipped++;
        } else {
          openings[acc] = (openings[acc] ?? 0) + amount;
        }
        continue;
      }
      final type = _parseType(cell(r, iType));
      final amount = double.tryParse(cell(r, iAmt).replaceAll(RegExp(r'[^0-9.\-]'), ''));
      final when = _parseDateTime(cell(r, iTime), cell(r, iDate));
      if (type == null || amount == null || amount <= 0 || when == null) {
        skipped++;
        continue;
      }
      final note = cell(r, iNote);
      final accRaw = cell(r, iAcc);
      var fromName = accRaw;
      var toName = cell(r, iTo);
      if (type == TransactionType.transfer && accRaw.contains('->')) {
        final parts = accRaw.split('->');
        fromName = parts[0].trim();
        if (parts.length > 1) toName = parts[1].trim();
      }
      if (type == TransactionType.transfer && toName.isEmpty) {
        skipped++;
        continue;
      }
      final rawCat = cell(r, iCat);
      out.add(CsvTx(
        type: type,
        amount: amount,
        date: when,
        category: type == TransactionType.transfer || rawCat == '-' ? '' : rawCat,
        account: fromName,
        toAccount: type == TransactionType.transfer ? toName : null,
        note: note.isEmpty ? null : note,
      ));
    }
    return CsvParseResult(out, skipped, openings);
  }

  /// Adds [t]'s effect on account balances to [delta].
  static void addBalanceDelta(Map<String, double> delta, TransactionType type, double amount, String from, String? to) {
    switch (type) {
      case TransactionType.income:
        delta[from] = (delta[from] ?? 0) + amount;
      case TransactionType.expense:
        delta[from] = (delta[from] ?? 0) - amount;
      case TransactionType.transfer:
        delta[from] = (delta[from] ?? 0) - amount;
        if (to != null) delta[to] = (delta[to] ?? 0) + amount;
    }
  }

  static Future<ImportResult> _importCsv(String text) async {
    final parsed = parseTransactionsCsv(text);
    final db = await DatabaseHelper.instance.database;
    final accounts = (await db.query('accounts')).map(AccountModel.fromMap).toList();
    final categories = (await db.query('categories')).map(CategoryModel.fromMap).toList();
    final existing = await DatabaseHelper.instance.getTransactions();
    // Accounts that already have history keep their balance: an opening
    // balance is only applied to accounts with no transactions yet, so
    // importing the same file twice does not add it twice.
    final usedAccounts = {
      for (final t in existing) ...[t.accountId, if (t.toAccountId != null) t.toAccountId!],
    };
    String key(DateTime d, TransactionType type, double amount, String? note) =>
        '${DateFormat('yyyy-MM-dd HH:mm').format(d)}|${type.name}|${amount.toStringAsFixed(2)}|${note ?? ''}';
    final seen = {for (final t in existing) key(t.date, t.type, t.amount, t.note)};
    final balanceDelta = <String, double>{};
    var added = 0, skipped = parsed.skipped;

    Future<String> accountId(String name) async {
      final n = name.isEmpty ? 'Imported' : name;
      final match = accounts.where((a) => a.name.toLowerCase() == n.toLowerCase());
      if (match.isNotEmpty) return match.first.id;
      final a = AccountModel(
          id: _uuid.v4(), name: n, type: AccountType.cash, icon: 'wallet', color: '#10A352', createdAt: DateTime.now());
      await db.insert('accounts', a.toMap());
      accounts.add(a);
      return a.id;
    }

    Future<String> categoryId(String name, CategoryType type) async {
      final n = name.isEmpty ? (type == CategoryType.income ? 'Other Income' : 'Other Expense') : name;
      final match = categories.where((c) => c.name.toLowerCase() == n.toLowerCase() && c.type == type);
      if (match.isNotEmpty) return match.first.id;
      final c = CategoryModel(
        id: _uuid.v4(),
        name: n,
        icon: type == CategoryType.income ? 'add_circle' : 'receipt_long',
        color: type == CategoryType.income ? '#16A34A' : '#64748B',
        type: type,
        isCustom: true,
      );
      await db.insert('categories', c.toMap());
      categories.add(c);
      return c.id;
    }

    for (final r in parsed.rows) {
      final k = key(r.date, r.type, r.amount, r.note);
      if (!seen.add(k)) {
        skipped++;
        continue;
      }
      final from = await accountId(r.account);
      final to = r.toAccount != null ? await accountId(r.toAccount!) : null;
      final catId = r.type == TransactionType.transfer
          ? 'transfer'
          : await categoryId(r.category, r.type == TransactionType.income ? CategoryType.income : CategoryType.expense);
      final tx = TransactionModel(
        id: _uuid.v4(),
        type: r.type,
        amount: r.amount,
        categoryId: catId,
        accountId: from,
        toAccountId: to,
        date: r.date,
        note: r.note,
        createdAt: DateTime.now(),
      );
      await db.insert('transactions', tx.toMap());
      added++;
      addBalanceDelta(balanceDelta, r.type, r.amount, from, to);
    }

    for (final o in parsed.openings.entries) {
      final id = await accountId(o.key);
      if (usedAccounts.contains(id)) continue;
      balanceDelta[id] = (balanceDelta[id] ?? 0) + o.value;
    }

    for (final e in balanceDelta.entries) {
      await db.rawUpdate('UPDATE accounts SET balance = balance + ? WHERE id = ?', [e.value, e.key]);
    }
    return ImportResult(added, skipped, 'csv');
  }
}
