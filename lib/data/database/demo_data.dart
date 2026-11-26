import 'package:sqflite/sqflite.dart';
import 'package:cashpilot/data/database/database_helper.dart';
import 'package:cashpilot/data/models/account_model.dart';
import 'package:cashpilot/data/models/budget_model.dart';
import 'package:cashpilot/data/models/goal_model.dart';
import 'package:cashpilot/data/models/transaction_model.dart';

/// Dummy data for Developer Mode. Every row id starts with [prefix] so the
/// whole set can be removed again without touching the user's own data.
class DemoData {
  static const prefix = 'demo_';

  static const _tables = [
    'transactions',
    'accounts',
    'budgets',
    'goals',
    'debts',
    'reminders',
    'categories',
  ];

  static const _main = '${prefix}acc_main';
  static const _savings = '${prefix}acc_savings';
  static const _business = '${prefix}acc_business';

  static Future<void> clear() async {
    final db = await DatabaseHelper.instance.database;
    await db.transaction((txn) async {
      // Also drop anything the user recorded against demo accounts.
      await txn.delete('transactions',
          where: 'id LIKE ? OR accountId LIKE ? OR toAccountId LIKE ?',
          whereArgs: ['$prefix%', '$prefix%', '$prefix%']);
      for (final t in _tables.skip(1)) {
        await txn.delete(t, where: 'id LIKE ?', whereArgs: ['$prefix%']);
      }
    });
  }

  static Future<void> seed() async {
    await clear();
    final db = await DatabaseHelper.instance.database;
    final now = DateTime.now();
    final catIds = await _categoryIds(db);
    String cat(String name) => catIds[name]!;

    final batch = db.batch();

    // ── Accounts ─────────────────────────────────────────────────────────
    final accounts = [
      AccountModel(id: _main, name: 'Main Wallet', type: AccountType.cash, icon: 'wallet', color: '#16A34A', balance: 2450.75, isDefault: false, createdAt: now.subtract(const Duration(days: 400))),
      AccountModel(id: _savings, name: 'Savings Account', type: AccountType.savings, icon: 'savings', color: '#F59E0B', balance: 850.00, createdAt: now.subtract(const Duration(days: 399))),
      AccountModel(id: _business, name: 'Business Account', type: AccountType.bank, icon: 'business', color: '#3B82F6', balance: 320.00, createdAt: now.subtract(const Duration(days: 398))),
    ];
    for (final a in accounts) {
      batch.insert('accounts', a.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    }

    // ── Transactions: four months of realistic activity ──────────────────
    // (day, category, type, amount, note, hour, minute, account)
    const template = <(int, String, TransactionType, double, String, int, int, String)>[
      (1, 'Salary', TransactionType.income, 2000, 'Salary', 9, 0, _main),
      (2, 'Rent', TransactionType.expense, 650, 'Apartment Rent', 10, 15, _main),
      (4, 'Food & Dining', TransactionType.expense, 45.50, 'Food & Dining', 8, 15, _main),
      (5, 'Transport', TransactionType.expense, 32, 'Uber Rides', 8, 40, _main),
      (7, 'Shopping', TransactionType.expense, 120, 'Shopping', 19, 10, _main),
      (9, 'Bills & Utilities', TransactionType.expense, 85.20, 'Electricity Bill', 11, 0, _main),
      (11, 'Freelance', TransactionType.income, 850, 'Logo Design Project', 16, 30, _business),
      (12, 'Food & Dining', TransactionType.expense, 62.30, 'Groceries', 18, 45, _main),
      (14, 'Entertainment', TransactionType.expense, 15.99, 'Netflix Subscription', 20, 0, _main),
      (16, 'Transport', TransactionType.expense, 48, 'Fuel', 7, 50, _main),
      (17, 'Health', TransactionType.expense, 40, 'Pharmacy', 12, 20, _main),
      (19, 'Shopping', TransactionType.expense, 89.90, 'Home Decor', 17, 30, _business),
      (20, 'Gift', TransactionType.income, 100, 'Gift', 21, 40, _main),
      (21, 'Food & Dining', TransactionType.expense, 38.75, 'Dinner with Friends', 20, 30, _main),
      (22, 'Freelance', TransactionType.income, 600, 'Website Maintenance', 15, 0, _business),
      (23, 'Food & Dining', TransactionType.expense, 54.20, 'Weekend Brunch', 11, 30, _main),
      (24, 'Education', TransactionType.expense, 29, 'Online Course', 10, 0, _main),
      (26, 'Transport', TransactionType.expense, 40, 'Metro Card', 8, 15, _main),
      (27, 'Investment', TransactionType.income, 250, 'Dividend Payout', 9, 30, _savings),
      (28, 'Shopping', TransactionType.expense, 74.50, 'Clothing', 18, 5, _main),
    ];

    var n = 0;
    for (var m = 3; m >= 0; m--) {
      final monthStart = DateTime(now.year, now.month - m, 1);
      final daysInMonth = DateTime(monthStart.year, monthStart.month + 1, 0).day;
      for (var i = 0; i < template.length; i++) {
        final t = template[i];
        final day = t.$1.clamp(1, daysInMonth);
        final date = DateTime(monthStart.year, monthStart.month, day, t.$6, t.$7);
        if (date.isAfter(now)) continue;
        // Wobble non-salary amounts so months & weeks look different.
        final wobble = t.$2 == 'Salary' || t.$2 == 'Rent'
            ? 1.0
            : 1 + 0.12 * (((m * 7 + i * 3) % 5) - 2);
        final amount = double.parse((t.$4 * wobble).toStringAsFixed(2));
        batch.insert(
          'transactions',
          TransactionModel(
            id: '${prefix}tx_${n++}',
            type: t.$3,
            amount: amount,
            categoryId: cat(t.$2),
            accountId: t.$8,
            date: date,
            note: t.$5,
            createdAt: date,
          ).toMap(),
        );
      }
      // Monthly transfer to savings
      final tDate = DateTime(monthStart.year, monthStart.month, 22.clamp(1, daysInMonth), 18, 20);
      if (!tDate.isAfter(now)) {
        batch.insert(
          'transactions',
          TransactionModel(
            id: '${prefix}tx_${n++}',
            type: TransactionType.transfer,
            amount: 200,
            categoryId: 'transfer',
            accountId: _main,
            toAccountId: _savings,
            date: tDate,
            note: 'Transfer to Savings',
            createdAt: tDate,
          ).toMap(),
        );
      }
    }

    // ── Budgets (current + two previous months) ──────────────────────────
    const budgets = {
      'Food & Dining': 500.0,
      'Shopping': 500.0,
      'Transport': 300.0,
      'Bills & Utilities': 200.0,
      'Entertainment': 100.0,
    };
    for (var m = 0; m < 3; m++) {
      final start = DateTime(now.year, now.month - m, 1);
      var j = 0;
      budgets.forEach((name, amount) {
        batch.insert(
          'budgets',
          BudgetModel(
            id: '${prefix}budget_${m}_${j++}',
            categoryId: cat(name),
            amount: amount,
            period: BudgetPeriod.monthly,
            startDate: start,
          ).toMap(),
        );
      });
    }

    // ── Goals ────────────────────────────────────────────────────────────
    final goals = [
      GoalModel(id: '${prefix}goal_laptop', name: 'New Laptop', targetAmount: 1500, currentAmount: 620, icon: 'laptop', color: '#6366F1', deadline: DateTime(now.year, now.month + 4, 1), createdAt: now),
      GoalModel(id: '${prefix}goal_trip', name: 'Dream Vacation', targetAmount: 3000, currentAmount: 1150, icon: 'flight', color: '#0EA5E9', deadline: DateTime(now.year, now.month + 8, 1), createdAt: now),
      GoalModel(id: '${prefix}goal_fund', name: 'Emergency Fund', targetAmount: 5000, currentAmount: 3200, icon: 'savings', color: '#16A34A', createdAt: now),
    ];
    for (final g in goals) {
      batch.insert('goals', g.toMap());
    }

    await batch.commit(noResult: true);
  }

  /// Resolves default category ids by name, creating demo categories for any
  /// the user has deleted.
  static Future<Map<String, String>> _categoryIds(Database db) async {
    const needed = {
      'Salary': ['income', 'wallet', '#16A34A'],
      'Freelance': ['income', 'laptop', '#F59E0B'],
      'Investment': ['income', 'trending_up', '#6366F1'],
      'Gift': ['income', 'card_giftcard', '#EC4899'],
      'Food & Dining': ['expense', 'restaurant', '#EF4444'],
      'Shopping': ['expense', 'shopping_bag', '#A855F7'],
      'Transport': ['expense', 'directions_car', '#3B82F6'],
      'Bills & Utilities': ['expense', 'receipt_long', '#F59E0B'],
      'Entertainment': ['expense', 'movie', '#EC4899'],
      'Health': ['expense', 'favorite', '#F43F5E'],
      'Education': ['expense', 'school', '#14B8A6'],
      'Rent': ['expense', 'home', '#F97316'],
    };
    final rows = await db.query('categories', columns: ['id', 'name', 'type']);
    final ids = <String, String>{};
    for (final entry in needed.entries) {
      final match = rows.where((r) => r['name'] == entry.key && r['type'] == entry.value[0]);
      if (match.isNotEmpty) {
        ids[entry.key] = match.first['id'] as String;
      } else {
        final id = '${prefix}cat_${entry.key.toLowerCase().replaceAll(RegExp(r'[^a-z]'), '')}';
        await db.insert(
          'categories',
          {
            'id': id,
            'name': entry.key,
            'icon': entry.value[1],
            'color': entry.value[2],
            'type': entry.value[0],
            'isCustom': 1,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
        ids[entry.key] = id;
      }
    }
    return ids;
  }
}
