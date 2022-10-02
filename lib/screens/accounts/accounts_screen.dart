import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:cashpilot/providers/account_provider.dart';
import 'package:cashpilot/providers/settings_provider.dart';
import 'package:cashpilot/data/models/account_model.dart';
import 'package:cashpilot/core/theme/app_colors.dart';
import 'package:cashpilot/core/constants/app_icons.dart';
import 'package:cashpilot/widgets/empty_state.dart';
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
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accProvider = context.watch<AccountProvider>();
    final settings = context.watch<SettingsProvider>();
    final formatter = NumberFormat('#,##0.00', 'en_US');

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Accounts',
          style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF1a1a2e)),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: () => AddAccountSheet.show(context),
          ),
        ],
      ),
      body: accProvider.accounts.isEmpty
          ? EmptyState(
              icon: Icons.account_balance_wallet_rounded,
              title: 'No accounts yet',
              subtitle: 'Add your first account to get started',
              actionLabel: 'Add Account',
              onAction: () => AddAccountSheet.show(context),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: AppColors.primaryGradient,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Total Balance',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${settings.currencySymbol}${formatter.format(accProvider.totalBalance)}',
                        style: GoogleFonts.inter(
                          fontSize: 32,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                ...accProvider.accounts.map((acc) => _AccountCard(
                      account: acc,
                      currencySymbol: settings.currencySymbol,
                      isDark: isDark,
                      onTap: () =>
                          context.push('/accounts/${acc.id}'),
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

  const _AccountCard({
    required this.account,
    required this.currencySymbol,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = AppColors.fromHex(account.color);
    final formatter = NumberFormat('#,##0.00', 'en_US');
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(AppIcons.fromName(account.icon),
                  color: color, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    account.name,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? Colors.white
                          : const Color(0xFF1a1a2e),
                    ),
                  ),
                  Text(
                    account.type.name.toUpperCase(),
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: color.withValues(alpha: 0.8),
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '$currencySymbol${formatter.format(account.balance)}',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: account.balance >= 0
                    ? (isDark ? Colors.white : const Color(0xFF1a1a2e))
                    : AppColors.expense,
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right_rounded,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.3)
                    : Colors.black.withValues(alpha: 0.3)),
          ],
        ),
      ),
    );
  }
}
