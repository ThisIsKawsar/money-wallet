import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:cashpilot/data/models/account_model.dart';
import 'package:cashpilot/data/models/transaction_model.dart';
import 'package:cashpilot/data/database/database_helper.dart';

const _uuid = Uuid();

class AccountProvider extends ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  List<AccountModel> _accounts = [];
  bool _isLoading = false;
  String? _error;

  List<AccountModel> get accounts => List.unmodifiable(_accounts);
  bool get isLoading => _isLoading;
  String? get error => _error;

  double get totalBalance =>
      _accounts.fold(0.0, (sum, a) => sum + a.balance);

  // ---------------------------------------------------------------------------
  // CRUD
  // ---------------------------------------------------------------------------

  Future<void> loadAccounts() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _accounts = await _dbHelper.getAccounts();
    } catch (e) {
      _error = 'Failed to load accounts: $e';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> addAccount(AccountModel account) async {
    try {
      await _dbHelper.insertAccount(account);
      _accounts.add(account);
      notifyListeners();
    } catch (e) {
      _error = 'Failed to add account: $e';
      notifyListeners();
    }
  }

  Future<void> updateAccount(AccountModel account) async {
    try {
      await _dbHelper.updateAccount(account);
      final index = _accounts.indexWhere((a) => a.id == account.id);
      if (index != -1) {
        _accounts[index] = account;
        notifyListeners();
      }
    } catch (e) {
      _error = 'Failed to update account: $e';
      notifyListeners();
    }
  }

  Future<void> deleteAccount(String id) async {
    try {
      await _dbHelper.deleteAccount(id);
      _accounts.removeWhere((a) => a.id == id);
      notifyListeners();
    } catch (e) {
      _error = 'Failed to delete account: $e';
      notifyListeners();
    }
  }

  // ---------------------------------------------------------------------------
  // Account lookup
  // ---------------------------------------------------------------------------

  AccountModel? getAccountById(String id) {
    try {
      return _accounts.firstWhere((a) => a.id == id);
    } catch (_) {
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // Transfer between accounts
  // ---------------------------------------------------------------------------

  /// Creates a transfer by debiting [fromId], crediting [toId], and recording
  /// a transfer transaction. Returns the created transaction id.
  Future<String?> transferBetweenAccounts({
    required String fromId,
    required String toId,
    required double amount,
    String? note,
  }) async {
    if (amount <= 0) {
      _error = 'Transfer amount must be greater than zero';
      notifyListeners();
      return null;
    }

    final fromAccount = getAccountById(fromId);
    final toAccount = getAccountById(toId);

    if (fromAccount == null || toAccount == null) {
      _error = 'Invalid account(s) for transfer';
      notifyListeners();
      return null;
    }

    try {
      // Update balances
      final updatedFrom =
          fromAccount.copyWith(balance: fromAccount.balance - amount);
      final updatedTo =
          toAccount.copyWith(balance: toAccount.balance + amount);

      await _dbHelper.updateAccount(updatedFrom);
      await _dbHelper.updateAccount(updatedTo);

      // Create transfer transaction
      final transaction = TransactionModel(
        id: _uuid.v4(),
        amount: amount,
        type: TransactionType.transfer,
        categoryId: 'transfer',
        accountId: fromId,
        toAccountId: toId,
        date: DateTime.now(),
        note: note ?? 'Transfer from ${fromAccount.name} to ${toAccount.name}',
        createdAt: DateTime.now(),
      );

      final txId = await _dbHelper.insertTransaction(transaction);

      final fromIdx = _accounts.indexWhere((a) => a.id == fromId);
      final toIdx = _accounts.indexWhere((a) => a.id == toId);
      if (fromIdx != -1) _accounts[fromIdx] = updatedFrom;
      if (toIdx != -1) _accounts[toIdx] = updatedTo;

      notifyListeners();
      return txId;
    } catch (e) {
      _error = 'Failed to complete transfer: $e';
      notifyListeners();
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // Recalculate balance from transactions
  // ---------------------------------------------------------------------------

  Future<void> updateAccountBalance(String accountId) async {
    try {
      final transactions = await _dbHelper.getTransactions();
      double balance = 0.0;

      // Find the account to get its initial balance if applicable
      final account = getAccountById(accountId);
      if (account == null) return;

      for (final t in transactions) {
        if (t.accountId == accountId) {
          switch (t.type) {
            case TransactionType.income:
              balance += t.amount;
              break;
            case TransactionType.expense:
              balance -= t.amount;
              break;
            case TransactionType.transfer:
              balance -= t.amount; // outgoing transfer
              break;
          }
        }
        // Incoming transfers
        if (t.type == TransactionType.transfer && t.toAccountId == accountId) {
          balance += t.amount;
        }
      }

      final updated = account.copyWith(balance: balance);
      await _dbHelper.updateAccount(updated);

      final index = _accounts.indexWhere((a) => a.id == accountId);
      if (index != -1) {
        _accounts[index] = updated;
        notifyListeners();
      }
    } catch (e) {
      _error = 'Failed to update account balance: $e';
      notifyListeners();
    }
  }

  /// Applies (or reverts) a transaction's effect on account balances.
  Future<void> applyTransaction(TransactionModel t, {bool revert = false}) async {
    final sign = revert ? -1 : 1;
    final from = getAccountById(t.accountId);
    switch (t.type) {
      case TransactionType.income:
        if (from != null) await updateAccount(from.copyWith(balance: from.balance + sign * t.amount));
      case TransactionType.expense:
        if (from != null) await updateAccount(from.copyWith(balance: from.balance - sign * t.amount));
      case TransactionType.transfer:
        if (from != null) await updateAccount(from.copyWith(balance: from.balance - sign * t.amount));
        final to = t.toAccountId == null ? null : getAccountById(t.toAccountId!);
        if (to != null) await updateAccount(to.copyWith(balance: to.balance + sign * t.amount));
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
