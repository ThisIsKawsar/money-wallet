import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:cashpilot/providers/account_provider.dart';
import 'package:cashpilot/providers/transaction_provider.dart';
import 'package:cashpilot/providers/category_provider.dart';
import 'package:cashpilot/providers/settings_provider.dart';
import 'package:cashpilot/core/theme/app_colors.dart';
import 'package:cashpilot/core/constants/app_icons.dart';
import 'package:cashpilot/data/models/transaction_model.dart';
import 'package:cashpilot/widgets/category_icon.dart';
import 'package:cashpilot/screens/accounts/widgets/add_account_sheet.dart';

class AccountDetailScreen extends StatelessWidget {
  final String accountId;
  const AccountDetailScreen({super.key, required this.accountId});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accProvider = context.watch<AccountProvider>();
    final txProvider = context.watch<TransactionProvider>();
    final catProvider = context.watch<CategoryProvider>();
    final settings = context.watch<SettingsProvider>();

    final account = accProvider.getAccountById(accountId);
    if (account == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Account not found')),
      );
    }

    final accountTxs = txProvider.getTransactionsByAccount(accountId);
    final color = AppColors.fromHex(account.color);
    final formatter = NumberFormat('#,##0.00', 'en_US');

    return Scaffold(
      appBar: AppBar(
        title: Text(account.name,
            style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF1a1a2e))),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_rounded),
            onPressed: () =>
                AddAccountSheet.show(context, account: account),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded,
                color: AppColors.expense),
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Delete Account'),
                  content: const Text(
                      'Delete this account? This action cannot be undone.'),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Cancel')),
                    TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('Delete',
                            style:
                                TextStyle(color: AppColors.expense))),
                  ],
                ),
              );
              if (confirmed == true && context.mounted) {
                await accProvider.deleteAccount(accountId);
                if (context.mounted) context.pop();
              }
            },
          ),
        ],
      ),
      body: ListView(
        children: [
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  color.withValues(alpha: 0.8),
                  color.withValues(alpha: 0.5),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                Icon(AppIcons.fromName(account.icon),
                    color: Colors.white, size: 36),
                const SizedBox(height: 12),
                Text(account.name,
                    style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withValues(alpha: 0.8))),
                const SizedBox(height: 8),
                Text(
                  '${settings.currencySymbol}${formatter.format(account.balance)}',
                  style: GoogleFonts.inter(
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      color: Colors.white),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Text('Transactions',
                style: GoogleFonts.inter(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF1a1a2e))),
          ),
          ...accountTxs.map((tx) {
            final cat = catProvider.getCategoryById(tx.categoryId);
            final amountColor = tx.type == TransactionType.income
                ? AppColors.income
                : tx.type == TransactionType.transfer
                    ? AppColors.transfer
                    : AppColors.expense;
            final prefix =
                tx.type == TransactionType.income ? '+' : '-';
            return ListTile(
              leading: CategoryIcon(
                  iconName: cat?.icon, colorHex: cat?.color),
              title: Text(cat?.name ?? 'Transfer',
                  style: GoogleFonts.inter(
                      fontSize: 14, fontWeight: FontWeight.w600)),
              subtitle: Text(
                  DateFormat('d MMM yyyy').format(tx.date),
                  style: GoogleFonts.inter(fontSize: 12)),
              trailing: Text(
                '$prefix${settings.currencySymbol}${tx.amount.toStringAsFixed(2)}',
                style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: amountColor),
              ),
            );
          }),
          if (accountTxs.isEmpty)
            Padding(
              padding: const EdgeInsets.all(40),
              child: Center(
                child: Text('No transactions for this account',
                    style: GoogleFonts.inter(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.4)
                            : Colors.black.withValues(alpha: 0.4))),
              ),
            ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}
