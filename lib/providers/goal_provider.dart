import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:cashpilot/data/models/goal_model.dart';
import 'package:cashpilot/data/database/database_helper.dart';

class GoalProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper.instance;
  static const _uuid = Uuid();

  List<GoalModel> _goals = [];
  bool _isLoading = false;
  String? _error;

  List<GoalModel> get goals => List.unmodifiable(_goals);
  bool get isLoading => _isLoading;
  String? get error => _error;

  List<GoalModel> get activeGoals => _goals.where((g) => !g.isCompleted).toList();
  List<GoalModel> get completedGoals => _goals.where((g) => g.isCompleted).toList();

  Future<void> loadGoals() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _goals = await _db.getGoals();
    } catch (e) {
      _error = 'Failed to load goals: $e';
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> addGoal(GoalModel goal) async {
    try {
      final withId = goal.copyWith(id: _uuid.v4());
      await _db.insertGoal(withId);
      _goals.add(withId);
      notifyListeners();
    } catch (e) {
      _error = 'Failed to add goal: $e';
      notifyListeners();
    }
  }

  Future<void> updateGoal(GoalModel goal) async {
    try {
      await _db.updateGoal(goal);
      final idx = _goals.indexWhere((g) => g.id == goal.id);
      if (idx != -1) {
        _goals[idx] = goal;
        notifyListeners();
      }
    } catch (e) {
      _error = 'Failed to update goal: $e';
      notifyListeners();
    }
  }

  Future<void> addToGoal(String goalId, double amount) async {
    final goal = _goals.firstWhere((g) => g.id == goalId);
    final updated = goal.copyWith(
        currentAmount: (goal.currentAmount + amount).clamp(0, goal.targetAmount));
    await updateGoal(updated);
  }

  Future<void> deleteGoal(String id) async {
    try {
      await _db.deleteGoal(id);
      _goals.removeWhere((g) => g.id == id);
      notifyListeners();
    } catch (e) {
      _error = 'Failed to delete goal: $e';
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
