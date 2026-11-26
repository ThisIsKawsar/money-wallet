import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:cashpilot/data/database/demo_data.dart';
import 'package:cashpilot/providers/account_provider.dart';
import 'package:cashpilot/providers/budget_provider.dart';
import 'package:cashpilot/providers/category_provider.dart';
import 'package:cashpilot/providers/goal_provider.dart';
import 'package:cashpilot/providers/transaction_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('providers see demo data after seed', () async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    await databaseFactory.setDatabasesPath('.dart_tool/test_db/demo_providers');
    await databaseFactory.deleteDatabase('${await databaseFactory.getDatabasesPath()}/cashpilot.db');
    SharedPreferences.setMockInitialValues({});

    await DemoData.seed();

    final tx = TransactionProvider();
    await tx.loadTransactions();
    final acc = AccountProvider();
    await acc.loadAccounts();
    final cat = CategoryProvider();
    await cat.loadCategories();
    final bud = BudgetProvider();
    await bud.loadBudgets();
    final goal = GoalProvider();
    await goal.loadGoals();
    // ignore: avoid_print
    print('tx=${tx.transactions.length} err=${tx.error} | acc=${acc.accounts.length} err=${acc.error} '
        '| cat=${cat.categories.length} err=${cat.error} | budgets=${bud.budgets.length} err=${bud.error} '
        '| goals=${goal.goals.length} err=${goal.error}');
    expect(tx.error, isNull);
    expect(tx.transactions.length, 2325);
  });
}
