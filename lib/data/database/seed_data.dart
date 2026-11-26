import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

class SeedData {
  static const _uuid = Uuid();

  /// Default category look (name -> [icon, color]); used by the v2 migration.
  static const Map<String, List<String>> defaultCategoryStyle = {
    'Salary': ['wallet', '#16A34A'],
    'Freelance': ['laptop', '#F59E0B'],
    'Investment': ['trending_up', '#6366F1'],
    'Gift': ['card_giftcard', '#EC4899'],
    'Interest': ['account_balance', '#0EA5E9'],
    'Other Income': ['add_circle', '#64748B'],
    'Food & Dining': ['restaurant', '#EF4444'],
    'Shopping': ['shopping_bag', '#A855F7'],
    'Transport': ['directions_car', '#3B82F6'],
    'Bills & Utilities': ['receipt_long', '#F59E0B'],
    'Entertainment': ['movie', '#EC4899'],
    'Health': ['favorite', '#F43F5E'],
    'Education': ['school', '#14B8A6'],
    'Savings': ['savings', '#10B981'],
    'Rent': ['home', '#F97316'],
    'Other Expense': ['remove_circle', '#64748B'],
  };

  static Future<void> seedCategories(Database db) async {
    final categories = [
      // Income
      {'id': _uuid.v4(), 'name': 'Salary', 'icon': 'wallet', 'color': '#16A34A', 'type': 'income', 'isCustom': 0},
      {'id': _uuid.v4(), 'name': 'Freelance', 'icon': 'laptop', 'color': '#F59E0B', 'type': 'income', 'isCustom': 0},
      {'id': _uuid.v4(), 'name': 'Investment', 'icon': 'trending_up', 'color': '#6366F1', 'type': 'income', 'isCustom': 0},
      {'id': _uuid.v4(), 'name': 'Gift', 'icon': 'card_giftcard', 'color': '#EC4899', 'type': 'income', 'isCustom': 0},
      {'id': _uuid.v4(), 'name': 'Interest', 'icon': 'account_balance', 'color': '#0EA5E9', 'type': 'income', 'isCustom': 0},
      {'id': _uuid.v4(), 'name': 'Other Income', 'icon': 'add_circle', 'color': '#64748B', 'type': 'income', 'isCustom': 0},
      // Expense
      {'id': _uuid.v4(), 'name': 'Food & Dining', 'icon': 'restaurant', 'color': '#EF4444', 'type': 'expense', 'isCustom': 0},
      {'id': _uuid.v4(), 'name': 'Shopping', 'icon': 'shopping_bag', 'color': '#A855F7', 'type': 'expense', 'isCustom': 0},
      {'id': _uuid.v4(), 'name': 'Transport', 'icon': 'directions_car', 'color': '#3B82F6', 'type': 'expense', 'isCustom': 0},
      {'id': _uuid.v4(), 'name': 'Bills & Utilities', 'icon': 'receipt_long', 'color': '#F59E0B', 'type': 'expense', 'isCustom': 0},
      {'id': _uuid.v4(), 'name': 'Entertainment', 'icon': 'movie', 'color': '#EC4899', 'type': 'expense', 'isCustom': 0},
      {'id': _uuid.v4(), 'name': 'Health', 'icon': 'favorite', 'color': '#F43F5E', 'type': 'expense', 'isCustom': 0},
      {'id': _uuid.v4(), 'name': 'Education', 'icon': 'school', 'color': '#14B8A6', 'type': 'expense', 'isCustom': 0},
      {'id': _uuid.v4(), 'name': 'Savings', 'icon': 'savings', 'color': '#10B981', 'type': 'expense', 'isCustom': 0},
      {'id': _uuid.v4(), 'name': 'Rent', 'icon': 'home', 'color': '#F97316', 'type': 'expense', 'isCustom': 0},
      {'id': _uuid.v4(), 'name': 'Other Expense', 'icon': 'remove_circle', 'color': '#64748B', 'type': 'expense', 'isCustom': 0},
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
        'color': '#16A34A',
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
