import 'package:flutter/foundation.dart';
import 'package:cashpilot/data/models/transaction_model.dart';
import 'package:cashpilot/data/database/database_helper.dart';
import 'package:intl/intl.dart';

class TransactionProvider extends ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  List<TransactionModel> _transactions = [];
  bool _isLoading = false;
  String? _error;

  List<TransactionModel> get transactions => List.unmodifiable(_transactions);
  bool get isLoading => _isLoading;
  String? get error => _error;

  // ---------------------------------------------------------------------------
  // Current-month aggregates
  // ---------------------------------------------------------------------------

  double get totalIncome {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, 1);
    final end = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
    return _transactions
        .where((t) =>
            t.type == TransactionType.income &&
            !t.date.isBefore(start) &&
            !t.date.isAfter(end))
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  double get totalExpense {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, 1);
    final end = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
    return _transactions
        .where((t) =>
            t.type == TransactionType.expense &&
            !t.date.isBefore(start) &&
            !t.date.isAfter(end))
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  // ---------------------------------------------------------------------------
  // CRUD
  // ---------------------------------------------------------------------------

  Future<void> loadTransactions() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _transactions = await _dbHelper.getTransactions();
      _transactions.sort((a, b) => b.date.compareTo(a.date));
    } catch (e) {
      _error = 'Failed to load transactions: $e';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> addTransaction(TransactionModel transaction) async {
    try {
      await _dbHelper.insertTransaction(transaction);
      _transactions.insert(0, transaction);
      _transactions.sort((a, b) => b.date.compareTo(a.date));
      notifyListeners();
    } catch (e) {
      _error = 'Failed to add transaction: $e';
      notifyListeners();
    }
  }

  Future<void> updateTransaction(TransactionModel transaction) async {
    try {
      await _dbHelper.updateTransaction(transaction);
      final index = _transactions.indexWhere((t) => t.id == transaction.id);
      if (index != -1) {
        _transactions[index] = transaction;
        _transactions.sort((a, b) => b.date.compareTo(a.date));
        notifyListeners();
      }
    } catch (e) {
      _error = 'Failed to update transaction: $e';
      notifyListeners();
    }
  }

  Future<void> deleteTransaction(String id) async {
    try {
      await _dbHelper.deleteTransaction(id);
      _transactions.removeWhere((t) => t.id == id);
      notifyListeners();
    } catch (e) {
      _error = 'Failed to delete transaction: $e';
      notifyListeners();
    }
  }

  // ---------------------------------------------------------------------------
  // Filters
  // ---------------------------------------------------------------------------

  List<TransactionModel> getTransactionsByDateRange(
      DateTime start, DateTime end) {
    return _transactions
        .where((t) => !t.date.isBefore(start) && !t.date.isAfter(end))
        .toList();
  }

  List<TransactionModel> getTransactionsByPeriod(String period) {
    final now = DateTime.now();
    late DateTime start;
    switch (period) {
      case 'daily':
        start = DateTime(now.year, now.month, now.day);
      case 'weekly':
        start = now.subtract(Duration(days: now.weekday - 1));
        start = DateTime(start.year, start.month, start.day);
      case 'monthly':
        start = DateTime(now.year, now.month, 1);
      case 'yearly':
        start = DateTime(now.year, 1, 1);
      default:
        return List.unmodifiable(_transactions);
    }
    return _transactions
        .where((t) => !t.date.isBefore(start))
        .toList();
  }

  double getPeriodIncome(String period) {
    return getTransactionsByPeriod(period)
        .where((t) => t.type == TransactionType.income)
        .fold(0.0, (s, t) => s + t.amount);
  }

  double getPeriodExpense(String period) {
    return getTransactionsByPeriod(period)
        .where((t) => t.type == TransactionType.expense)
        .fold(0.0, (s, t) => s + t.amount);
  }

  List<TransactionModel> getTransactionsByCategory(String categoryId) {
    return _transactions.where((t) => t.categoryId == categoryId).toList();
  }

  List<TransactionModel> getTransactionsByAccount(String accountId) {
    return _transactions.where((t) => t.accountId == accountId).toList();
  }

  List<TransactionModel> searchTransactions(String query) {
    final q = query.toLowerCase().trim();
    if (q.isEmpty) return List.unmodifiable(_transactions);
    return _transactions
        .where((t) =>
            (t.note?.toLowerCase().contains(q) ?? false) ||
            t.amount.toString().contains(q))
        .toList();
  }

  // ---------------------------------------------------------------------------
  // Chart data helpers
  // ---------------------------------------------------------------------------

  /// Returns monthly totals keyed by "MMM yyyy" (e.g. "Jan 2026") for the
  /// given [type]. Covers the last [months] months including the current one.
  Map<String, double> getMonthlyData({
    TransactionType type = TransactionType.expense,
    int months = 6,
  }) {
    final now = DateTime.now();
    final formatter = DateFormat('MMM yyyy');
    final Map<String, double> data = {};

    for (int i = months - 1; i >= 0; i--) {
      final month = DateTime(now.year, now.month - i, 1);
      data[formatter.format(month)] = 0.0;
    }

    final cutoff = DateTime(now.year, now.month - months + 1, 1);
    for (final t in _transactions) {
      if (t.type == type && !t.date.isBefore(cutoff)) {
        final key = formatter.format(t.date);
        if (data.containsKey(key)) {
          data[key] = data[key]! + t.amount;
        }
      }
    }

    return data;
  }

  /// Returns daily totals for the current month keyed by "dd" (e.g. "01").
  Map<String, double> getDailyData({
    TransactionType type = TransactionType.expense,
  }) {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, 1);
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final Map<String, double> data = {};

    for (int d = 1; d <= daysInMonth; d++) {
      data[d.toString().padLeft(2, '0')] = 0.0;
    }

    for (final t in _transactions) {
      if (t.type == type && !t.date.isBefore(start) && t.date.month == now.month && t.date.year == now.year) {
        final key = t.date.day.toString().padLeft(2, '0');
        data[key] = data[key]! + t.amount;
      }
    }

    return data;
  }

  /// Returns spending per category for the current month. Key is categoryId as
  /// String, value is total amount.
  Map<String, double> getCategorySpending() {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, 1);
    final end = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
    final Map<String, double> data = {};

    for (final t in _transactions) {
      if (t.type == TransactionType.expense &&
          !t.date.isBefore(start) &&
          !t.date.isAfter(end)) {
        final key = t.categoryId;
        data[key] = (data[key] ?? 0.0) + t.amount;
      }
    }

    return data;
  }

  /// Income vs expense bucketed by [period]: daily (last 7 days),
  /// weekly (last 8 weeks), monthly (last 6 months), yearly (last 3 years).
  List<Map<String, dynamic>> getIncomeVsExpenseByPeriod(String period) {
    final now = DateTime.now();
    final List<Map<String, dynamic>> result = [];

    switch (period) {
      case 'daily':
        for (int i = 6; i >= 0; i--) {
          final day = now.subtract(Duration(days: i));
          final start = DateTime(day.year, day.month, day.day);
          final end = start.add(const Duration(days: 1));
          final label = DateFormat('EEE').format(start);
          double income = 0, expense = 0;
          for (final t in _transactions) {
            if (!t.date.isBefore(start) && t.date.isBefore(end)) {
              if (t.type == TransactionType.income) income += t.amount;
              if (t.type == TransactionType.expense) expense += t.amount;
            }
          }
          result.add({'month': label, 'income': income, 'expense': expense});
        }
      case 'weekly':
        for (int i = 7; i >= 0; i--) {
          final weekStart = now
              .subtract(Duration(days: now.weekday - 1 + i * 7));
          final start = DateTime(weekStart.year, weekStart.month, weekStart.day);
          final end = start.add(const Duration(days: 7));
          final label = 'W${DateFormat('d/M').format(start)}';
          double income = 0, expense = 0;
          for (final t in _transactions) {
            if (!t.date.isBefore(start) && t.date.isBefore(end)) {
              if (t.type == TransactionType.income) income += t.amount;
              if (t.type == TransactionType.expense) expense += t.amount;
            }
          }
          result.add({'month': label, 'income': income, 'expense': expense});
        }
      case 'yearly':
        for (int i = 2; i >= 0; i--) {
          final year = now.year - i;
          final start = DateTime(year, 1, 1);
          final end = DateTime(year + 1, 1, 1);
          double income = 0, expense = 0;
          for (final t in _transactions) {
            if (!t.date.isBefore(start) && t.date.isBefore(end)) {
              if (t.type == TransactionType.income) income += t.amount;
              if (t.type == TransactionType.expense) expense += t.amount;
            }
          }
          result.add({'month': year.toString(), 'income': income, 'expense': expense});
        }
      default: // monthly
        return getIncomeVsExpense(months: 6);
    }
    return result;
  }

  Map<String, double> getCategorySpendingByPeriod(String period) {
    final txs = getTransactionsByPeriod(period)
        .where((t) => t.type == TransactionType.expense);
    final Map<String, double> data = {};
    for (final t in txs) {
      data[t.categoryId] = (data[t.categoryId] ?? 0.0) + t.amount;
    }
    return data;
  }

  Map<String, double> getCategorySpendingForMonth(int year, int month) {
    final start = DateTime(year, month, 1);
    final end = DateTime(year, month + 1, 1);
    final Map<String, double> data = {};
    for (final t in _transactions) {
      if (t.type == TransactionType.expense &&
          !t.date.isBefore(start) &&
          t.date.isBefore(end)) {
        data[t.categoryId] = (data[t.categoryId] ?? 0.0) + t.amount;
      }
    }
    return data;
  }

  /// Income vs expense for each of the last [months] months.
  /// Returns a list of maps with keys: month, income, expense.
  List<Map<String, dynamic>> getIncomeVsExpense({int months = 6}) {
    final now = DateTime.now();
    final formatter = DateFormat('MMM yyyy');
    final List<Map<String, dynamic>> result = [];

    for (int i = months - 1; i >= 0; i--) {
      final month = DateTime(now.year, now.month - i, 1);
      final nextMonth = DateTime(now.year, now.month - i + 1, 1);
      final label = formatter.format(month);

      double income = 0;
      double expense = 0;

      for (final t in _transactions) {
        if (!t.date.isBefore(month) && t.date.isBefore(nextMonth)) {
          if (t.type == TransactionType.income) {
            income += t.amount;
          } else if (t.type == TransactionType.expense) {
            expense += t.amount;
          }
        }
      }

      result.add({'month': label, 'income': income, 'expense': expense});
    }

    return result;
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
