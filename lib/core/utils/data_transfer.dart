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
  static const _csvHeader = ['Date', 'Time', 'Type', 'Category', 'Account', 'To Account', 'Amount', 'Note'];

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

  static String _csvCell(String v) =>
      v.contains(RegExp(r'[",\n\r]')) ? '"${v.replaceAll('"', '""')}"' : v;

  static String buildCsv(
    List<TransactionModel> txs,
    List<AccountModel> accounts,
    List<CategoryModel> categories,
  ) {
    final accName = {for (final a in accounts) a.id: a.name};
    final catName = {for (final c in categories) c.id: c.name};
    final rows = [..._csvHeader.map(_csvCell)].join(',');
    final b = StringBuffer()..writeln(rows);
    final sorted = [...txs]..sort((a, c) => a.date.compareTo(c.date));
    for (final t in sorted) {
      b.writeln([
        DateFormat('yyyy-MM-dd').format(t.date),
        DateFormat('HH:mm').format(t.date),
        t.type.name,
        t.type == TransactionType.transfer ? 'Transfer' : (catName[t.categoryId] ?? ''),
        accName[t.accountId] ?? '',
        t.toAccountId == null ? '' : (accName[t.toAccountId] ?? ''),
        t.amount.toStringAsFixed(2),
        t.note ?? '',
      ].map(_csvCell).join(','));
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

  static Future<ImportResult> _importCsv(String text) async {
    final rows = _parseCsv(text);
    if (rows.length < 2) throw const FormatException('The CSV file has no rows');
    final header = rows.first.map((h) => h.trim().toLowerCase()).toList();
    int col(String name) => header.indexOf(name);
    final iDate = col('date'), iTime = col('time'), iType = col('type'), iCat = col('category');
    final iAcc = col('account'), iTo = col('to account'), iAmt = col('amount');
    final iNote = col('note') >= 0 ? col('note') : col('description');
    if (iDate < 0 || iType < 0 || iAmt < 0) {
      throw const FormatException('CSV needs at least Date, Type and Amount columns');
    }

    final db = await DatabaseHelper.instance.database;
    final accounts = (await db.query('accounts')).map(AccountModel.fromMap).toList();
    final categories = (await db.query('categories')).map(CategoryModel.fromMap).toList();
    final existing = (await db.query('transactions')).map(TransactionModel.fromMap).toList();
    final seen = {
      for (final t in existing)
        '${DateFormat('yyyy-MM-dd').format(t.date)}|${t.type.name}|${t.amount.toStringAsFixed(2)}|${t.note ?? ''}'
    };
    final balanceDelta = <String, double>{};
    var added = 0, skipped = 0;

    String cell(List<String> r, int i) => i >= 0 && i < r.length ? r[i].trim() : '';

    Future<String> accountId(String name) async {
      final n = name.isEmpty ? 'Imported' : name;
      final match = accounts.where((a) => a.name.toLowerCase() == n.toLowerCase());
      if (match.isNotEmpty) return match.first.id;
      final a = AccountModel(
          id: _uuid.v4(), name: n, type: AccountType.cash, icon: 'wallet', color: '#3B82F6', createdAt: DateTime.now());
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

    for (final r in rows.skip(1)) {
      final typeName = cell(r, iType).toLowerCase();
      final type = TransactionType.values.where((t) => t.name == typeName).firstOrNull;
      final amount = double.tryParse(cell(r, iAmt).replaceAll(RegExp(r'[^0-9.\-]'), ''));
      final date = DateTime.tryParse(cell(r, iDate));
      if (type == null || amount == null || amount <= 0 || date == null) {
        skipped++;
        continue;
      }
      final timeParts = cell(r, iTime).split(':');
      final when = timeParts.length == 2
          ? DateTime(date.year, date.month, date.day, int.tryParse(timeParts[0]) ?? 0, int.tryParse(timeParts[1]) ?? 0)
          : date;
      final note = cell(r, iNote).isEmpty ? null : cell(r, iNote);
      final key = '${DateFormat('yyyy-MM-dd').format(when)}|${type.name}|${amount.toStringAsFixed(2)}|${note ?? ''}';
      if (seen.contains(key)) {
        skipped++;
        continue;
      }
      seen.add(key);

      final from = await accountId(cell(r, iAcc));
      String? to;
      String catId;
      if (type == TransactionType.transfer) {
        final toName = cell(r, iTo);
        if (toName.isEmpty) {
          skipped++;
          continue;
        }
        to = await accountId(toName);
        catId = 'transfer';
      } else {
        catId = await categoryId(
            cell(r, iCat), type == TransactionType.income ? CategoryType.income : CategoryType.expense);
      }
      final tx = TransactionModel(
        id: _uuid.v4(),
        type: type,
        amount: amount,
        categoryId: catId,
        accountId: from,
        toAccountId: to,
        date: when,
        note: note,
        createdAt: DateTime.now(),
      );
      await db.insert('transactions', tx.toMap());
      added++;
      switch (type) {
        case TransactionType.income:
          balanceDelta[from] = (balanceDelta[from] ?? 0) + amount;
        case TransactionType.expense:
          balanceDelta[from] = (balanceDelta[from] ?? 0) - amount;
        case TransactionType.transfer:
          balanceDelta[from] = (balanceDelta[from] ?? 0) - amount;
          balanceDelta[to!] = (balanceDelta[to] ?? 0) + amount;
      }
    }

    for (final e in balanceDelta.entries) {
      await db.rawUpdate('UPDATE accounts SET balance = balance + ? WHERE id = ?', [e.value, e.key]);
    }
    return ImportResult(added, skipped, 'csv');
  }
}
