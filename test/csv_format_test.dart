import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:cashpilot/core/utils/data_transfer.dart';
import 'package:cashpilot/data/models/account_model.dart';
import 'package:cashpilot/data/models/category_model.dart';
import 'package:cashpilot/data/models/transaction_model.dart';

void main() {
  test('bundled demo CSV parses every row', () {
    final text = File('assets/demo/demo_transactions.csv').readAsStringSync();
    final res = DataTransfer.parseTransactionsCsv(text);
    expect(res.skipped, 0);
    expect(res.rows.length, 2325);

    final first = res.rows.first;
    expect(first.date, DateTime(2025, 1, 1, 11, 57));
    expect(first.type, TransactionType.income);
    expect(first.amount, 3355);
    expect(first.category, 'Home M');
    expect(first.account, 'Cash');

    final transfer = res.rows.firstWhere((r) => r.type == TransactionType.transfer);
    expect(transfer.account, 'IB Card');
    expect(transfer.toAccount, 'Cash');
    expect(transfer.category, '');

    // Multi-line quoted note.
    expect(res.rows.any((r) => r.note == 'baby'), isTrue);
    expect(res.rows.last.date, DateTime(2026, 11, 25, 19, 47));
  });

  test('template parses', () {
    final res = DataTransfer.parseTransactionsCsv(DataTransfer.buildTemplateCsv());
    expect(res.skipped, 0);
    expect(res.rows.map((r) => r.type), [
      TransactionType.income,
      TransactionType.expense,
      TransactionType.transfer,
      TransactionType.expense,
    ]);
    expect(res.rows[2].account, 'Bank');
    expect(res.rows[2].toAccount, 'Cash');
  });

  test('export round-trips through the importer parser', () {
    final now = DateTime(2026, 11, 25, 19, 47);
    final accs = [
      AccountModel(id: 'a', name: 'IB Card', type: AccountType.bank, icon: 'x', color: '#000', createdAt: now),
      AccountModel(id: 'b', name: 'Cash', type: AccountType.cash, icon: 'x', color: '#000', createdAt: now),
    ];
    final cats = [CategoryModel(id: 'c', name: 'Bazar⭐', icon: 'x', color: '#000', type: CategoryType.expense)];
    final csv = DataTransfer.buildCsv([
      TransactionModel(id: '1', type: TransactionType.expense, amount: 150, categoryId: 'c', accountId: 'b', date: now, note: 'a "quoted"\nnote', createdAt: now),
      TransactionModel(id: '2', type: TransactionType.transfer, amount: 500, categoryId: 'transfer', accountId: 'a', toAccountId: 'b', date: now, createdAt: now),
    ], accs, cats);
    expect(csv.split('\n').first, '"TIME","TYPE","AMOUNT","CATEGORY","ACCOUNT","NOTES"');
    final res = DataTransfer.parseTransactionsCsv(csv);
    expect(res.rows[0].category, 'Bazar⭐');
    expect(res.rows[0].note, 'a "quoted"\nnote');
    expect(res.rows[1].account, 'IB Card');
    expect(res.rows[1].toAccount, 'Cash');
  });
}
