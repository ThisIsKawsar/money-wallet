import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

class SeedData {
  static const _uuid = Uuid();

  /// Legacy default category look (name -> [icon, color]); used only by the
  /// v2 migration for databases created before the current defaults.
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

  /// Default categories, matching the CashPilot CSV format / demo data.
  /// (name, icon, color) per type.
  static const List<List<String>> incomeCategories = [
    ['Salary', 'wallet', '#16A34A'],
    ['Home M', 'home', '#0EA5E9'],
    ['Home F', 'home', '#14B8A6'],
    ['Ar', 'account_balance', '#6366F1'],
    ['Loan', 'payments', '#F59E0B'],
    ['Grants', 'card_giftcard', '#EC4899'],
    ['Miss', 'add_circle', '#64748B'],
  ];

  static const List<List<String>> expenseCategories = [
    ['O Food', 'fastfood', '#EF4444'],
    ['Transportation ⭐', 'directions_car', '#3B82F6'],
    ['Entertainment', 'movie', '#EC4899'],
    ['Bazar⭐', 'local_grocery_store', '#22C55E'],
    ['Medicine', 'local_hospital', '#F43F5E'],
    ['Baby ⭐', 'child_care', '#F472B6'],
    ['Telephone ⭐', 'phone', '#0EA5E9'],
    ['Bills ⭐', 'electric_bolt', '#F59E0B'],
    ['Home M', 'home', '#F97316'],
    ['Home F', 'home', '#FB923C'],
    ['Social', 'celebration', '#A855F7'],
    ['Shopping', 'shopping_bag', '#8B5CF6'],
    ['Hospital', 'favorite', '#E11D48'],
    ['Loan', 'payments', '#D97706'],
    ['Ar', 'account_balance', '#6366F1'],
    ['Tax', 'receipt_long', '#78716C'],
    ['Donation', 'volunteer_activism', '#10B981'],
    ['Beauty', 'favorite', '#DB2777'],
    ['Sport & Gym', 'fitness_center', '#0D9488'],
    ['Fis', 'school', '#14B8A6'],
    ['Miss', 'remove_circle', '#64748B'],
    ['others', 'remove_circle', '#94A3B8'],
  ];

  /// Default accounts: (name, type, icon, color, isDefault).
  static const List<List<Object>> defaultAccounts = [
    ['Cash', 'cash', 'wallet', '#16A34A', 1],
    ['IB Card', 'bank', 'credit_card', '#3B82F6', 0],
    ['Bkash', 'mobile', 'phone_android', '#E2136E', 0],
    ['Nagad', 'mobile', 'phone_android', '#F7941D', 0],
  ];

  static Future<void> seedCategories(Database db) async {
    final batch = db.batch();
    for (final (type, list) in [('income', incomeCategories), ('expense', expenseCategories)]) {
      for (final c in list) {
        batch.insert(
          'categories',
          {'id': _uuid.v4(), 'name': c[0], 'icon': c[1], 'color': c[2], 'type': type, 'isCustom': 0},
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );
      }
    }
    await batch.commit(noResult: true);
  }

  static Future<void> seedAccounts(Database db) async {
    final now = DateTime.now().toIso8601String();
    final batch = db.batch();
    for (final a in defaultAccounts) {
      batch.insert(
        'accounts',
        {
          'id': _uuid.v4(),
          'name': a[0],
          'type': a[1],
          'icon': a[2],
          'color': a[3],
          'balance': 0.0,
          'currency': 'USD',
          'isDefault': a[4],
          'createdAt': now,
        },
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
    await batch.commit(noResult: true);
  }
}
