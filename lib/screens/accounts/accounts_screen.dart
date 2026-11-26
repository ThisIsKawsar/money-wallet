import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:cashpilot/providers/account_provider.dart';
import 'package:cashpilot/providers/transaction_provider.dart';
import 'package:cashpilot/providers/settings_provider.dart';
import 'package:cashpilot/data/models/account_model.dart';
import 'package:cashpilot/data/models/transaction_model.dart';
import 'package:cashpilot/core/theme/app_colors.dart';
import 'package:cashpilot/core/constants/app_icons.dart';
import 'package:cashpilot/widgets/empty_state.dart';
import 'package:cashpilot/widgets/wavy_background.dart';
import 'package:cashpilot/screens/accounts/widgets/add_account_sheet.dart';

class AccountsScreen extends StatefulWidget {
  const AccountsScreen({super.key});

  @override
  State<AccountsScreen> createState() => _AccountsScreenState();
}

class _AccountsScreenState extends State<AccountsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AccountProvider>().loadAccounts();
      context.read<TransactionProvider>().loadTransactions();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accProvider = context.watch<AccountProvider>();
    final txProvider = context.watch<TransactionProvider>();
    final settings = context.watch<SettingsProvider>();
    final fmt = NumberFormat('#,##0.00', 'en_US');

    final totalExpenseSoFar = txProvider.transactions
        .where((t) => t.type == TransactionType.expense)
        .fold(0.0, (s, t) => s + t.amount);
    final totalIncomeSoFar = txProvider.transactions
        .where((t) => t.type == TransactionType.income)
        .fold(0.0, (s, t) => s + t.amount);

    return WavyBackground(
      child: accProvider.accounts.isEmpty
          ? EmptyState(
              icon: Icons.account_balance_wallet_rounded,
              title: 'No accounts yet',
              subtitle: 'Add your first account to get started',
              actionLabel: 'Add Account',
              onAction: () => AddAccountSheet.show(context),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
              children: [
                Text(
                  'Overall',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : AppColors.lightTextPrimary,
                  ),
                ),
                const SizedBox(height: 10),

                // Overall Summary Card (EXPENSE SO FAR | INCOME SO FAR | TOTAL BALANCE)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkCard : AppColors.mintSoft,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              children: [
                                Text(
                                  'EXPENSE SO FAR',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: isDark
                                        ? AppColors.darkTextSecondary
                                        : AppColors.lightTextSecondary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '-${settings.currencySymbol}${fmt.format(totalExpenseSoFar)}',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.expense,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            width: 1,
                            height: 36,
                            color: AppColors.primary.withValues(alpha: 0.2),
                          ),
                          Expanded(
                            child: Column(
                              children: [
                                Text(
                                  'INCOME SO FAR',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: isDark
                                        ? AppColors.darkTextSecondary
                                        : AppColors.lightTextSecondary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${settings.currencySymbol}${fmt.format(totalIncomeSoFar)}',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.income,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Divider(
                        height: 1,
                        color: AppColors.primary.withValues(alpha: 0.2),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'TOTAL BALANCE',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${settings.currencySymbol}${fmt.format(accProvider.totalBalance)}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Accounts',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : AppColors.lightTextPrimary,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => AddAccountSheet.show(context),
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text('Add Account'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                ...accProvider.accounts.map((acc) => _AccountCard(
                      account: acc,
                      currencySymbol: settings.currencySymbol,
                      isDark: isDark,
                      onTap: () => context.push('/accounts/${acc.id}'),
                      onTransfer: () => context.push('/transfer'),
                      onDelete: () => accProvider.deleteAccount(acc.id),
                    )),
              ],
            ),
    );
  }
}

class _AccountCard extends StatelessWidget {
  final AccountModel account;
  final String currencySymbol;
  final bool isDark;
  final VoidCallback onTap;
  final VoidCallback onTransfer;
  final VoidCallback onDelete;

  const _AccountCard({
    required this.account,
    required this.currencySymbol,
    required this.isDark,
    required this.onTap,
    required this.onTransfer,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final color = AppColors.fromHex(account.color);
    final fmt = NumberFormat('#,##0.00', 'en_US');

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            AppIcons.fromName(account.icon),
            color: color,
            size: 22,
          ),
        ),
        title: Text(
          account.name,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : AppColors.lightTextPrimary,
          ),
        ),
        subtitle: Text(
          'Balance: $currencySymbol${fmt.format(account.balance)}',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: account.balance < 0 ? AppColors.expense : AppColors.income,
          ),
        ),
        trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.more_horiz_rounded),
          onSelected: (v) {
            if (v == 'details') onTap();
            if (v == 'transfer') onTransfer();
            if (v == 'delete') onDelete();
          },
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'details', child: Text('View Details')),
            PopupMenuItem(value: 'transfer', child: Text('Transfer Money')),
            PopupMenuItem(value: 'delete', child: Text('Delete')),
          ],
        ),
      ),
    );
  }
}
