import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:cashpilot/data/models/debt_model.dart';
import 'package:cashpilot/data/database/database_helper.dart';

class DebtProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper.instance;
  static const _uuid = Uuid();

  List<DebtModel> _debts = [];
  bool _isLoading = false;
  String? _error;

  List<DebtModel> get debts => List.unmodifiable(_debts);
  bool get isLoading => _isLoading;
  String? get error => _error;

  List<DebtModel> get iOwe =>
      _debts.where((d) => d.type == DebtType.owe && !d.isSettled).toList();

  List<DebtModel> get owedToMe =>
      _debts.where((d) => d.type == DebtType.owed && !d.isSettled).toList();

  double get totalOwed =>
      iOwe.fold(0, (sum, d) => sum + d.remaining);

  double get totalOwedToMe =>
      owedToMe.fold(0, (sum, d) => sum + d.remaining);

  Future<void> loadDebts() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _debts = await _db.getDebts();
    } catch (e) {
      _error = 'Failed to load debts: $e';
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> addDebt(DebtModel debt) async {
    try {
      final withId = debt.copyWith(id: _uuid.v4());
      await _db.insertDebt(withId);
      _debts.add(withId);
      notifyListeners();
    } catch (e) {
      _error = 'Failed to add debt: $e';
      notifyListeners();
    }
  }

  Future<void> updateDebt(DebtModel debt) async {
    try {
      await _db.updateDebt(debt);
      final idx = _debts.indexWhere((d) => d.id == debt.id);
      if (idx != -1) {
        _debts[idx] = debt;
        notifyListeners();
      }
    } catch (e) {
      _error = 'Failed to update debt: $e';
      notifyListeners();
    }
  }

  Future<void> recordPayment(String debtId, double amount) async {
    final debt = _debts.firstWhere((d) => d.id == debtId);
    final updated =
        debt.copyWith(paid: (debt.paid + amount).clamp(0, debt.amount));
    await updateDebt(updated);
  }

  Future<void> deleteDebt(String id) async {
    try {
      await _db.deleteDebt(id);
      _debts.removeWhere((d) => d.id == id);
      notifyListeners();
    } catch (e) {
      _error = 'Failed to delete debt: $e';
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
