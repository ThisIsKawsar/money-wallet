import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:cashpilot/core/utils/data_transfer.dart';
import 'package:cashpilot/data/database/database_helper.dart';
import 'package:cashpilot/data/database/seed_data.dart';
import 'package:cashpilot/data/models/budget_model.dart';
import 'package:cashpilot/data/models/goal_model.dart';
import 'package:cashpilot/data/models/transaction_model.dart';

/// Dummy data for Developer Mode, loaded from the bundled CSV
/// ([csvAsset], same format as Export CSV). Every row id starts with [prefix]
/// so the whole set can be removed again without touching the user's own data.
class DemoData {
  static const prefix = 'demo_';
  static const csvAsset = 'assets/demo/demo_transactions.csv';

  /// Opening balances added to accounts by [seed] ({accountId: amount}),
  /// kept so [clear] can take exactly that amount back out.
  static const _kOpenings = 'demoOpeningBalances';

  static const _tables = [
    'transactions',
    'accounts',
    'budgets',
    'goals',
    'debts',
    'reminders',
    'categories',
  ];

  static bool _isDemo(String? id) => id != null && id.startsWith(prefix);

  static Future<void> clear() async {
    final db = await DatabaseHelper.instance.database;
    final prefs = await SharedPreferences.getInstance();
    final openings = _readOpenings(prefs);
    await db.transaction((txn) async {
      for (final e in openings.entries) {
        await txn.rawUpdate('UPDATE accounts SET balance = balance - ? WHERE id = ?', [e.value, e.key]);
      }

      // Also drop anything the user recorded against demo accounts.
      const where = 'id LIKE ? OR accountId LIKE ? OR toAccountId LIKE ?';
      const args = ['$prefix%', '$prefix%', '$prefix%'];

      // Undo the balance effect these transactions had on real accounts.
      final rows = await txn.query('transactions', where: where, whereArgs: args);
      final delta = <String, double>{};
      for (final t in rows.map(TransactionModel.fromMap)) {
        DataTransfer.addBalanceDelta(delta, t.type, t.amount, t.accountId, t.toAccountId);
      }
      for (final e in delta.entries) {
        if (_isDemo(e.key)) continue;
        await txn.rawUpdate('UPDATE accounts SET balance = balance - ? WHERE id = ?', [e.value, e.key]);
      }

      await txn.delete('transactions', where: where, whereArgs: args);
      for (final t in _tables.skip(1)) {
        await txn.delete(t, where: 'id LIKE ?', whereArgs: ['$prefix%']);
      }
    });
    await prefs.remove(_kOpenings);
  }

  static Map<String, double> _readOpenings(SharedPreferences prefs) {
    try {
      final raw = prefs.getString(_kOpenings);
      if (raw == null) return {};
      return (jsonDecode(raw) as Map<String, dynamic>)
          .map((k, v) => MapEntry(k, (v as num).toDouble()));
    } catch (_) {
      return {};
    }
  }

  /// The CSV has no opening balances, so replaying it alone drives accounts
  /// below zero. Give each account a round opening amount that keeps its
  /// running balance at or above zero for the whole history.
  static Map<String, double> _openingBalances(List<(DateTime, String, String?, TransactionType, double)> txs) {
    final sorted = [...txs]..sort((a, b) => a.$1.compareTo(b.$1));
    final running = <String, double>{};
    final lowest = <String, double>{};
    for (final t in sorted) {
      DataTransfer.addBalanceDelta(running, t.$4, t.$5, t.$2, t.$3);
      for (final id in [t.$2, if (t.$3 != null) t.$3!]) {
        final v = running[id] ?? 0;
        if (v < (lowest[id] ?? 0)) lowest[id] = v;
      }
    }
    return {
      for (final e in lowest.entries)
        if (e.value < 0) e.key: ((-e.value / 1000).ceil() * 1000).toDouble(),
    };
  }

  static Future<void> seed() async {
    await clear();
    final parsed = DataTransfer.parseTransactionsCsv(await rootBundle.loadString(csvAsset));
    final db = await DatabaseHelper.instance.database;
    final now = DateTime.now();
    var openings = <String, double>{};

    await db.transaction((txn) async {
      final accIds = await _accountIds(txn, parsed.rows);
      final catIds = await _categoryIds(txn, parsed.rows);
      String cat(String name, String type) => catIds['$type|${name.toLowerCase()}']!;

      // ── Transactions (from the CSV) ────────────────────────────────────
      final batch = txn.batch();
      final delta = <String, double>{};
      final replay = <(DateTime, String, String?, TransactionType, double)>[];
      var n = 0;
      for (final r in parsed.rows) {
        final from = accIds[r.account.toLowerCase()]!;
        final to = r.toAccount != null ? accIds[r.toAccount!.toLowerCase()] : null;
        final type = r.type;
        batch.insert(
          'transactions',
          TransactionModel(
            id: '${prefix}tx_${n++}',
            type: type,
            amount: r.amount,
            categoryId: type == TransactionType.transfer ? 'transfer' : cat(r.category, type.name),
            accountId: from,
            toAccountId: to,
            date: r.date,
            note: r.note,
            createdAt: r.date,
          ).toMap(),
        );
        DataTransfer.addBalanceDelta(delta, type, r.amount, from, to);
        replay.add((r.date, from, to, type, r.amount));
      }
      openings = _openingBalances(replay);
      for (final e in openings.entries) {
        delta[e.key] = (delta[e.key] ?? 0) + e.value;
      }
      for (final e in delta.entries) {
        batch.rawUpdate('UPDATE accounts SET balance = balance + ? WHERE id = ?', [e.value, e.key]);
      }

      // ── Budgets (current + two previous months) ────────────────────────
      const budgets = {
        'O Food': 3000.0,
        'Bazar⭐': 3000.0,
        'Transportation ⭐': 2500.0,
        'Baby ⭐': 3000.0,
        'Bills ⭐': 1500.0,
        'Entertainment': 1000.0,
      };
      for (var m = 0; m < 3; m++) {
        final start = DateTime(now.year, now.month - m, 1);
        var j = 0;
        for (final b in budgets.entries) {
          final id = catIds['expense|${b.key.toLowerCase()}'];
          if (id == null) continue;
          batch.insert(
            'budgets',
            BudgetModel(
              id: '${prefix}budget_${m}_${j++}',
              categoryId: id,
              amount: b.value,
              period: BudgetPeriod.monthly,
              startDate: start,
            ).toMap(),
          );
        }
      }

      // ── Goals ──────────────────────────────────────────────────────────
      final goals = [
        GoalModel(id: '${prefix}goal_laptop', name: 'New Laptop', targetAmount: 60000, currentAmount: 24000, icon: 'laptop', color: '#6366F1', deadline: DateTime(now.year, now.month + 4, 1), createdAt: now),
        GoalModel(id: '${prefix}goal_trip', name: 'Family Trip', targetAmount: 50000, currentAmount: 18000, icon: 'flight', color: '#0EA5E9', deadline: DateTime(now.year, now.month + 8, 1), createdAt: now),
        GoalModel(id: '${prefix}goal_fund', name: 'Emergency Fund', targetAmount: 100000, currentAmount: 65000, icon: 'savings', color: '#16A34A', createdAt: now),
      ];
      for (final g in goals) {
        batch.insert('goals', g.toMap());
      }

      await batch.commit(noResult: true);
    });

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kOpenings, jsonEncode(openings));
  }

  static String _slug(String s) => s.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');

  /// Resolves account ids by name (lower-cased). Uses the user's accounts when
  /// the name exists, otherwise creates a demo account.
  static Future<Map<String, String>> _accountIds(Transaction txn, List<CsvTx> rows) async {
    final names = <String>{
      for (final r in rows) ...[r.account, if (r.toAccount != null) r.toAccount!],
    }.map((n) => n.isEmpty ? 'Imported' : n);
    final existing = await txn.query('accounts', columns: ['id', 'name']);
    final ids = <String, String>{};
    final defaults = {for (final a in SeedData.defaultAccounts) (a[0] as String).toLowerCase(): a};
    for (final name in names) {
      final key = name.toLowerCase();
      if (ids.containsKey(key)) continue;
      final match = existing.where((r) => (r['name'] as String).toLowerCase() == key);
      if (match.isNotEmpty) {
        ids[key] = match.first['id'] as String;
        continue;
      }
      final d = defaults[key];
      final id = '${prefix}acc_${_slug(name)}';
      await txn.insert(
        'accounts',
        {
          'id': id,
          'name': name,
          'type': d?[1] ?? 'cash',
          'icon': d?[2] ?? 'wallet',
          'color': d?[3] ?? '#16A34A',
          'balance': 0.0,
          'currency': 'USD',
          'isDefault': 0,
          'createdAt': DateTime.now().toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      ids[key] = id;
    }
    // Rows with an empty account name fall back to 'Imported'.
    if (ids.containsKey('imported')) ids[''] = ids['imported']!;
    return ids;
  }

  /// Resolves category ids keyed by "type|name" (lower-cased), creating demo
  /// categories for any the user does not have.
  static Future<Map<String, String>> _categoryIds(Transaction txn, List<CsvTx> rows) async {
    final style = <String, List<String>>{
      for (final c in SeedData.incomeCategories) 'income|${c[0].toLowerCase()}': c,
      for (final c in SeedData.expenseCategories) 'expense|${c[0].toLowerCase()}': c,
    };
    final existing = await txn.query('categories', columns: ['id', 'name', 'type']);
    final ids = <String, String>{};
    for (final r in rows) {
      if (r.type == TransactionType.transfer) continue;
      final type = r.type.name;
      final name = r.category;
      final key = '$type|${name.toLowerCase()}';
      if (ids.containsKey(key)) continue;
      final match = existing.where(
          (c) => c['type'] == type && (c['name'] as String).toLowerCase() == name.toLowerCase());
      if (match.isNotEmpty) {
        ids[key] = match.first['id'] as String;
        continue;
      }
      final s = style[key];
      final id = '${prefix}cat_${type}_${_slug(name)}_${ids.length}';
      await txn.insert(
        'categories',
        {
          'id': id,
          'name': name.isEmpty ? (type == 'income' ? 'Other Income' : 'Other Expense') : name,
          'icon': s?[1] ?? (type == 'income' ? 'add_circle' : 'receipt_long'),
          'color': s?[2] ?? '#64748B',
          'type': type,
          'isCustom': 1,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      ids[key] = id;
    }
    return ids;
  }
}
