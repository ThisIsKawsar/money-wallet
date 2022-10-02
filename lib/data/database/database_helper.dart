import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:cashpilot/data/models/transaction_model.dart';
import 'package:cashpilot/data/models/account_model.dart';
import 'package:cashpilot/data/models/category_model.dart';
import 'package:cashpilot/data/models/budget_model.dart';
import 'package:cashpilot/data/models/goal_model.dart';
import 'package:cashpilot/data/models/debt_model.dart';
import 'package:cashpilot/data/models/reminder_model.dart';
import 'package:cashpilot/data/database/seed_data.dart';

class DatabaseHelper {
  static const _dbName = 'cashpilot.db';
  static const _dbVersion = 1;

  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();

  Database? _db;

  Future<Database> get database async {
    _db ??= await _initDatabase();
    return _db!;
  }

  Future<Database> _initDatabase() async {
    final path = join(await getDatabasesPath(), _dbName);
    return openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE transactions (
        id TEXT PRIMARY KEY,
        type TEXT NOT NULL,
        amount REAL NOT NULL,
        categoryId TEXT NOT NULL,
        accountId TEXT NOT NULL,
        toAccountId TEXT,
        date TEXT NOT NULL,
        note TEXT,
        paymentMethod TEXT,
        attachmentPath TEXT,
        isRecurring INTEGER NOT NULL DEFAULT 0,
        recurringFrequency TEXT,
        createdAt TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE accounts (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        icon TEXT NOT NULL,
        color TEXT NOT NULL,
        balance REAL NOT NULL DEFAULT 0.0,
        currency TEXT NOT NULL DEFAULT 'USD',
        isDefault INTEGER NOT NULL DEFAULT 0,
        createdAt TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE categories (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        icon TEXT NOT NULL,
        color TEXT NOT NULL,
        type TEXT NOT NULL,
        isCustom INTEGER NOT NULL DEFAULT 0,
        budgetAmount REAL
      )
    ''');

    await db.execute('''
      CREATE TABLE budgets (
        id TEXT PRIMARY KEY,
        categoryId TEXT,
        amount REAL NOT NULL,
        period TEXT NOT NULL,
        startDate TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE goals (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        targetAmount REAL NOT NULL,
        currentAmount REAL NOT NULL DEFAULT 0.0,
        icon TEXT NOT NULL,
        color TEXT NOT NULL,
        deadline TEXT,
        createdAt TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE debts (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        amount REAL NOT NULL,
        paid REAL NOT NULL DEFAULT 0.0,
        person TEXT NOT NULL,
        dueDate TEXT,
        note TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE reminders (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        amount REAL NOT NULL,
        dueDate TEXT NOT NULL,
        isRecurring INTEGER NOT NULL DEFAULT 0,
        recurringFrequency TEXT,
        isPaid INTEGER NOT NULL DEFAULT 0,
        categoryId TEXT
      )
    ''');

    await db.execute('CREATE INDEX idx_tx_date ON transactions(date)');
    await db.execute('CREATE INDEX idx_tx_type ON transactions(type)');
    await db.execute('CREATE INDEX idx_tx_cat ON transactions(categoryId)');
    await db.execute('CREATE INDEX idx_tx_acc ON transactions(accountId)');

    await SeedData.seedCategories(db);
    await SeedData.seedAccounts(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {}

  // ── Transactions ───────────────────────────────────────────────────────────

  Future<String> insertTransaction(TransactionModel t) async {
    final db = await database;
    await db.insert('transactions', t.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
    return t.id;
  }

  Future<List<TransactionModel>> getTransactions() async {
    final db = await database;
    final rows = await db.query('transactions', orderBy: 'date DESC');
    return rows.map(TransactionModel.fromMap).toList();
  }

  Future<void> updateTransaction(TransactionModel t) async {
    final db = await database;
    await db.update('transactions', t.toMap(),
        where: 'id = ?', whereArgs: [t.id]);
  }

  Future<void> deleteTransaction(String id) async {
    final db = await database;
    await db.delete('transactions', where: 'id = ?', whereArgs: [id]);
  }

  // ── Accounts ───────────────────────────────────────────────────────────────

  Future<String> insertAccount(AccountModel a) async {
    final db = await database;
    await db.insert('accounts', a.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
    return a.id;
  }

  Future<List<AccountModel>> getAccounts() async {
    final db = await database;
    final rows = await db.query('accounts', orderBy: 'createdAt ASC');
    return rows.map(AccountModel.fromMap).toList();
  }

  Future<void> updateAccount(AccountModel a) async {
    final db = await database;
    await db.update('accounts', a.toMap(),
        where: 'id = ?', whereArgs: [a.id]);
  }

  Future<void> deleteAccount(String id) async {
    final db = await database;
    await db.delete('accounts', where: 'id = ?', whereArgs: [id]);
  }

  // ── Categories ─────────────────────────────────────────────────────────────

  Future<String> insertCategory(CategoryModel c) async {
    final db = await database;
    await db.insert('categories', c.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
    return c.id;
  }

  Future<List<CategoryModel>> getCategories() async {
    final db = await database;
    final rows = await db.query('categories');
    return rows.map(CategoryModel.fromMap).toList();
  }

  Future<void> updateCategory(CategoryModel c) async {
    final db = await database;
    await db.update('categories', c.toMap(),
        where: 'id = ?', whereArgs: [c.id]);
  }

  Future<void> deleteCategory(String id) async {
    final db = await database;
    await db.delete('categories', where: 'id = ?', whereArgs: [id]);
  }

  // ── Budgets ────────────────────────────────────────────────────────────────

  Future<String> insertBudget(BudgetModel b) async {
    final db = await database;
    await db.insert('budgets', b.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
    return b.id;
  }

  Future<List<BudgetModel>> getBudgets() async {
    final db = await database;
    final rows = await db.query('budgets');
    return rows.map(BudgetModel.fromMap).toList();
  }

  Future<void> updateBudget(BudgetModel b) async {
    final db = await database;
    await db.update('budgets', b.toMap(),
        where: 'id = ?', whereArgs: [b.id]);
  }

  Future<void> deleteBudget(String id) async {
    final db = await database;
    await db.delete('budgets', where: 'id = ?', whereArgs: [id]);
  }

  // ── Goals ──────────────────────────────────────────────────────────────────

  Future<String> insertGoal(GoalModel g) async {
    final db = await database;
    await db.insert('goals', g.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
    return g.id;
  }

  Future<List<GoalModel>> getGoals() async {
    final db = await database;
    final rows = await db.query('goals', orderBy: 'createdAt ASC');
    return rows.map(GoalModel.fromMap).toList();
  }

  Future<void> updateGoal(GoalModel g) async {
    final db = await database;
    await db.update('goals', g.toMap(), where: 'id = ?', whereArgs: [g.id]);
  }

  Future<void> deleteGoal(String id) async {
    final db = await database;
    await db.delete('goals', where: 'id = ?', whereArgs: [id]);
  }

  // ── Debts ──────────────────────────────────────────────────────────────────

  Future<String> insertDebt(DebtModel d) async {
    final db = await database;
    await db.insert('debts', d.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
    return d.id;
  }

  Future<List<DebtModel>> getDebts() async {
    final db = await database;
    final rows = await db.query('debts', orderBy: 'dueDate ASC');
    return rows.map(DebtModel.fromMap).toList();
  }

  Future<void> updateDebt(DebtModel d) async {
    final db = await database;
    await db.update('debts', d.toMap(), where: 'id = ?', whereArgs: [d.id]);
  }

  Future<void> deleteDebt(String id) async {
    final db = await database;
    await db.delete('debts', where: 'id = ?', whereArgs: [id]);
  }

  // ── Reminders ─────────────────────────────────────────────────────────────

  Future<String> insertReminder(ReminderModel r) async {
    final db = await database;
    await db.insert('reminders', r.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
    return r.id;
  }

  Future<List<ReminderModel>> getReminders() async {
    final db = await database;
    final rows = await db.query('reminders', orderBy: 'dueDate ASC');
    return rows.map(ReminderModel.fromMap).toList();
  }

  Future<void> updateReminder(ReminderModel r) async {
    final db = await database;
    await db.update('reminders', r.toMap(),
        where: 'id = ?', whereArgs: [r.id]);
  }

  Future<void> deleteReminder(String id) async {
    final db = await database;
    await db.delete('reminders', where: 'id = ?', whereArgs: [id]);
  }
}
