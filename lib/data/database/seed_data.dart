import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

class SeedData {
  static const _uuid = Uuid();

  static Future<void> seedCategories(Database db) async {
    final categories = [
      // Income
      {'id': _uuid.v4(), 'name': 'Salary', 'icon': 'work', 'color': '#00d4aa', 'type': 'income', 'isCustom': 0},
      {'id': _uuid.v4(), 'name': 'Freelance', 'icon': 'laptop', 'color': '#4facfe', 'type': 'income', 'isCustom': 0},
      {'id': _uuid.v4(), 'name': 'Investment', 'icon': 'trending_up', 'color': '#a29bfe', 'type': 'income', 'isCustom': 0},
      {'id': _uuid.v4(), 'name': 'Gift', 'icon': 'card_giftcard', 'color': '#fd79a8', 'type': 'income', 'isCustom': 0},
      {'id': _uuid.v4(), 'name': 'Interest', 'icon': 'account_balance', 'color': '#ffeaa7', 'type': 'income', 'isCustom': 0},
      {'id': _uuid.v4(), 'name': 'Other Income', 'icon': 'add_circle', 'color': '#636e72', 'type': 'income', 'isCustom': 0},
      // Expense
      {'id': _uuid.v4(), 'name': 'Food & Dining', 'icon': 'restaurant', 'color': '#ff6b6b', 'type': 'expense', 'isCustom': 0},
      {'id': _uuid.v4(), 'name': 'Shopping', 'icon': 'shopping_bag', 'color': '#e17055', 'type': 'expense', 'isCustom': 0},
      {'id': _uuid.v4(), 'name': 'Transport', 'icon': 'directions_car', 'color': '#fdcb6e', 'type': 'expense', 'isCustom': 0},
      {'id': _uuid.v4(), 'name': 'Bills & Utilities', 'icon': 'receipt_long', 'color': '#74b9ff', 'type': 'expense', 'isCustom': 0},
      {'id': _uuid.v4(), 'name': 'Entertainment', 'icon': 'movie', 'color': '#a29bfe', 'type': 'expense', 'isCustom': 0},
      {'id': _uuid.v4(), 'name': 'Health', 'icon': 'favorite', 'color': '#ff7675', 'type': 'expense', 'isCustom': 0},
      {'id': _uuid.v4(), 'name': 'Education', 'icon': 'school', 'color': '#55efc4', 'type': 'expense', 'isCustom': 0},
      {'id': _uuid.v4(), 'name': 'Savings', 'icon': 'savings', 'color': '#00cec9', 'type': 'expense', 'isCustom': 0},
      {'id': _uuid.v4(), 'name': 'Rent', 'icon': 'home', 'color': '#fab1a0', 'type': 'expense', 'isCustom': 0},
      {'id': _uuid.v4(), 'name': 'Other Expense', 'icon': 'remove_circle', 'color': '#636e72', 'type': 'expense', 'isCustom': 0},
    ];

    final batch = db.batch();
    for (final cat in categories) {
      batch.insert('categories', cat, conflictAlgorithm: ConflictAlgorithm.ignore);
    }
    await batch.commit(noResult: true);
  }

  static Future<void> seedAccounts(Database db) async {
    final now = DateTime.now().toIso8601String();
    final accounts = [
      {
        'id': _uuid.v4(),
        'name': 'Cash Wallet',
        'type': 'cash',
        'icon': 'wallet',
        'color': '#00d4aa',
        'balance': 0.0,
        'currency': 'USD',
        'isDefault': 1,
        'createdAt': now,
      },
      {
        'id': _uuid.v4(),
        'name': 'Bank Account',
        'type': 'bank',
        'icon': 'account_balance',
        'color': '#4facfe',
        'balance': 0.0,
        'currency': 'USD',
        'isDefault': 0,
        'createdAt': now,
      },
      {
        'id': _uuid.v4(),
        'name': 'Credit Card',
        'type': 'credit',
        'icon': 'credit_card',
        'color': '#ff6b6b',
        'balance': 0.0,
        'currency': 'USD',
        'isDefault': 0,
        'createdAt': now,
      },
      {
        'id': _uuid.v4(),
        'name': 'Mobile Banking',
        'type': 'mobile',
        'icon': 'phone_android',
        'color': '#a29bfe',
        'balance': 0.0,
        'currency': 'USD',
        'isDefault': 0,
        'createdAt': now,
      },
      {
        'id': _uuid.v4(),
        'name': 'Savings Account',
        'type': 'savings',
        'icon': 'savings',
        'color': '#ffeaa7',
        'balance': 0.0,
        'currency': 'USD',
        'isDefault': 0,
        'createdAt': now,
      },
      {
        'id': _uuid.v4(),
        'name': 'E-Wallet',
        'type': 'ewallet',
        'icon': 'payments',
        'color': '#fd79a8',
        'balance': 0.0,
        'currency': 'USD',
        'isDefault': 0,
        'createdAt': now,
      },
    ];

    final batch = db.batch();
    for (final acc in accounts) {
      batch.insert('accounts', acc, conflictAlgorithm: ConflictAlgorithm.ignore);
    }
    await batch.commit(noResult: true);
  }
}
