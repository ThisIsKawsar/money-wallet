import 'package:intl/intl.dart';
import 'package:cashpilot/data/models/transaction_model.dart';
import 'package:cashpilot/data/models/account_model.dart';
import 'package:cashpilot/data/models/category_model.dart';

class ExportHelper {
  static String exportTransactionsToCSV(
    List<TransactionModel> transactions,
    List<AccountModel> accounts,
    List<CategoryModel> categories,
  ) {
    final buffer = StringBuffer();
    
    // Header
    buffer.writeln('Date,Type,Category,Account,Amount,Note,Payment Method');
    
    // Sort by date
    final sorted = List.from(transactions)..sort((a, b) => a.date.compareTo(b.date));
    
    for (final tx in sorted) {
      final account = accounts.firstWhere(
        (a) => a.id == tx.accountId,
        orElse: () => AccountModel(
          id: '',
          name: 'Unknown',
          type: AccountType.cash,
          icon: 'account_balance_wallet',
          color: '#000000',
          createdAt: DateTime.now(),
        ),
      );
      
      final category = categories.firstWhere(
        (c) => c.id == tx.categoryId,
        orElse: () => CategoryModel(
          id: '',
          name: 'Unknown',
          icon: 'help',
          color: '#000000',
          type: CategoryType.expense,
          isCustom: false,
        ),
      );
      
      final date = DateFormat('yyyy-MM-dd').format(tx.date);
      final type = tx.type.name.toUpperCase();
      final amount = tx.amount.toStringAsFixed(2);
      final note = tx.note?.replaceAll(',', ';') ?? '';
      final paymentMethod = tx.paymentMethod?.replaceAll(',', ';') ?? '';
      
      buffer.writeln('$date,$type,${category.name},${account.name},$amount,$note,$paymentMethod');
    }
    
    return buffer.toString();
  }
  
  static String exportAccountsToCSV(List<AccountModel> accounts) {
    final buffer = StringBuffer();
    
    buffer.writeln('Name,Type,Balance,Currency,Is Default');
    
    for (final acc in accounts) {
      final name = acc.name.replaceAll(',', ';');
      final type = acc.type.name.toUpperCase();
      final balance = acc.balance.toStringAsFixed(2);
      final isDefault = acc.isDefault ? 'Yes' : 'No';
      
      buffer.writeln('$name,$type,$balance,${acc.currency},$isDefault');
    }
    
    return buffer.toString();
  }
  
  static String exportCategoriesToCSV(List<CategoryModel> categories) {
    final buffer = StringBuffer();
    
    buffer.writeln('Name,Type,Icon,Color,Is Custom,Budget Amount');
    
    for (final cat in categories) {
      final name = cat.name.replaceAll(',', ';');
      final type = cat.type.name.toUpperCase();
      final isCustom = cat.isCustom ? 'Yes' : 'No';
      final budget = cat.budgetAmount?.toStringAsFixed(2) ?? '0.00';
      
      buffer.writeln('$name,$type,${cat.icon},${cat.color},$isCustom,$budget');
    }
    
    return buffer.toString();
  }
}
