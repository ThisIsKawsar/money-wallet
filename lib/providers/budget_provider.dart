import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:cashpilot/data/models/budget_model.dart';
import 'package:cashpilot/data/database/database_helper.dart';

class BudgetProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper.instance;
  static const _uuid = Uuid();

  List<BudgetModel> _budgets = [];
  bool _isLoading = false;
  String? _error;

  List<BudgetModel> get budgets => List.unmodifiable(_budgets);
  bool get isLoading => _isLoading;
  String? get error => _error;

  BudgetModel? get overallBudget {
    try {
      return _budgets.firstWhere((b) => b.categoryId == null);
    } catch (_) {
      return null;
    }
  }

  List<BudgetModel> get categoryBudgets =>
      _budgets.where((b) => b.categoryId != null).toList();

  Future<void> loadBudgets() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _budgets = await _db.getBudgets();
    } catch (e) {
      _error = 'Failed to load budgets: $e';
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> addBudget(BudgetModel budget) async {
    try {
      final withId = budget.copyWith(id: _uuid.v4());
      await _db.insertBudget(withId);
      _budgets.add(withId);
      notifyListeners();
    } catch (e) {
      _error = 'Failed to add budget: $e';
      notifyListeners();
    }
  }

  Future<void> updateBudget(BudgetModel budget) async {
    try {
      await _db.updateBudget(budget);
      final idx = _budgets.indexWhere((b) => b.id == budget.id);
      if (idx != -1) {
        _budgets[idx] = budget;
        notifyListeners();
      }
    } catch (e) {
      _error = 'Failed to update budget: $e';
      notifyListeners();
    }
  }

  Future<void> deleteBudget(String id) async {
    try {
      await _db.deleteBudget(id);
      _budgets.removeWhere((b) => b.id == id);
      notifyListeners();
    } catch (e) {
      _error = 'Failed to delete budget: $e';
      notifyListeners();
    }
  }

  BudgetModel? getBudgetForCategory(String categoryId) {
    try {
      return _budgets.firstWhere((b) => b.categoryId == categoryId);
    } catch (_) {
      return null;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
