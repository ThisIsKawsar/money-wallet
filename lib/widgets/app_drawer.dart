import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cashpilot/core/theme/app_colors.dart';
import 'package:cashpilot/core/constants/app_constants.dart';
import 'package:cashpilot/data/database/database_helper.dart';
import 'package:cashpilot/providers/transaction_provider.dart';
import 'package:cashpilot/providers/account_provider.dart';
import 'package:cashpilot/providers/category_provider.dart';
import 'package:cashpilot/providers/budget_provider.dart';
import 'package:cashpilot/providers/goal_provider.dart';
import 'package:cashpilot/providers/settings_provider.dart';
import 'package:cashpilot/widgets/cashpilot_logo.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Drawer(
      backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightBg,
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
              child: Row(
                children: [
                  const CashPilotLogo(size: 38),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppConstants.appName,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : AppColors.lightTextPrimary,
                        ),
                      ),
                      Text(
                        'v1.0.0',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            const SizedBox(height: 6),

            _DrawerTile(
              icon: Icons.settings_outlined,
              label: 'Preferences',
              isDark: isDark,
              onTap: () {
                Navigator.pop(context);
                context.push('/settings');
              },
            ),
            const Divider(height: 16),

            _sectionLabel('Management', isDark),
            _DrawerTile(
              icon: Icons.file_download_outlined,
              label: 'Export records',
              isDark: isDark,
              onTap: () async {
                Navigator.pop(context);
                await _exportRecords(context);
              },
            ),
            _DrawerTile(
              icon: Icons.save_outlined,
              label: 'Backup & Restore',
              isDark: isDark,
              onTap: () {
                Navigator.pop(context);
                _showBackupRestoreDialog(context);
              },
            ),
            _DrawerTile(
              icon: Icons.delete_outline_rounded,
              label: 'Delete & Reset',
              isDark: isDark,
              onTap: () {
                Navigator.pop(context);
                _showResetDialog(context);
              },
            ),
            const Divider(height: 16),

            _sectionLabel('Finance & Tools', isDark),
            _DrawerTile(
              icon: Icons.calendar_month_outlined,
              label: 'Calendar & Reminders',
              isDark: isDark,
              onTap: () {
                Navigator.pop(context);
                context.push('/settings/reminders');
              },
            ),
            _DrawerTile(
              icon: Icons.credit_score_outlined,
              label: 'Debts & Loans',
              isDark: isDark,
              onTap: () {
                Navigator.pop(context);
                context.push('/settings/debts');
              },
            ),
            _DrawerTile(
              icon: Icons.swap_horiz_rounded,
              label: 'Transfer Money',
              isDark: isDark,
              onTap: () {
                Navigator.pop(context);
                context.push('/transfer');
              },
            ),
            const Divider(height: 16),

            _sectionLabel('Application', isDark),
            _DrawerTile(
              icon: Icons.help_outline_rounded,
              label: 'Help',
              isDark: isDark,
              onTap: () {
                Navigator.pop(context);
                _showHelpDialog(context);
              },
            ),
            _DrawerTile(
              icon: Icons.info_outline_rounded,
              label: 'About ${AppConstants.appName}',
              isDark: isDark,
              onTap: () {
                Navigator.pop(context);
                _showHelpDialog(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String text, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
      child: Text(
        text,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: isDark
              ? AppColors.darkTextTertiary
              : AppColors.lightTextSecondary,
        ),
      ),
    );
  }

  Future<void> _exportRecords(BuildContext context) async {
    final txs = context.read<TransactionProvider>().transactions;
    final accs = context.read<AccountProvider>().accounts;
    final cats = context.read<CategoryProvider>().categories;
    final buf = StringBuffer('Date,Type,Category,Account,Amount,Note\n');
    for (final t in txs) {
      final cat = cats.where((c) => c.id == t.categoryId).firstOrNull?.name ?? '';
      final acc = accs.where((a) => a.id == t.accountId).firstOrNull?.name ?? '';
      final note = (t.note ?? '').replaceAll('"', '""');
      buf.writeln('${t.date.toIso8601String()},${t.type.name},"$cat","$acc",${t.amount},"$note"');
    }
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/cashpilot_records.csv');
    await file.writeAsString(buf.toString());
    await Share.shareXFiles([XFile(file.path)], text: 'CashPilot Records');
  }

  Future<void> _showBackupRestoreDialog(BuildContext context) async {
    final restoreCtrl = TextEditingController();
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Backup & Restore'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton.icon(
              onPressed: () async {
                final json = await DatabaseHelper.instance.exportBackupJson();
                final dir = await getTemporaryDirectory();
                final file = File('${dir.path}/cashpilot_backup.json');
                await file.writeAsString(json);
                await Clipboard.setData(ClipboardData(text: json));
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Backup copied to clipboard & saved!'),
                      backgroundColor: AppColors.primary,
                    ),
                  );
                }
                await Share.shareXFiles([XFile(file.path)],
                    text: 'CashPilot Backup');
              },
              icon: const Icon(Icons.upload_file_rounded),
              label: const Text('Export Backup (JSON)'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: restoreCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Paste Backup JSON to Restore',
                hintText: '{"version": 1, ...}',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () async {
              final text = restoreCtrl.text.trim();
              if (text.isEmpty) return;
              try {
                await DatabaseHelper.instance.importBackupJson(text);
                if (!context.mounted) return;
                await Future.wait([
                  context.read<TransactionProvider>().loadTransactions(),
                  context.read<AccountProvider>().loadAccounts(),
                  context.read<CategoryProvider>().loadCategories(),
                  context.read<BudgetProvider>().loadBudgets(),
                  context.read<GoalProvider>().loadGoals(),
                  context.read<SettingsProvider>().loadSettings(),
                ]);
                if (ctx.mounted) Navigator.pop(ctx);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Backup restored successfully!'),
                      backgroundColor: AppColors.primary,
                    ),
                  );
                }
              } catch (e) {
                if (ctx.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Invalid backup JSON: $e'),
                      backgroundColor: AppColors.expense,
                    ),
                  );
                }
              }
            },
            child: const Text('Restore'),
          ),
        ],
      ),
    );
  }

  Future<void> _showResetDialog(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete & Reset'),
        content: const Text(
          'This will delete all transactions, budgets, goals, debts, and reminders, and reset account balances to 0. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await DatabaseHelper.instance.resetAllData();
              if (!context.mounted) return;
              await Future.wait([
                context.read<TransactionProvider>().loadTransactions(),
                context.read<AccountProvider>().loadAccounts(),
                context.read<BudgetProvider>().loadBudgets(),
                context.read<GoalProvider>().loadGoals(),
                context.read<SettingsProvider>().loadSettings(),
              ]);
              if (ctx.mounted) Navigator.pop(ctx);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('All records cleared'),
                    backgroundColor: AppColors.primary,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.expense,
              foregroundColor: Colors.white,
            ),
            child: const Text('Reset All'),
          ),
        ],
      ),
    );
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('${AppConstants.appName} Guide'),
        content: const Text(
          '• Records: View daily transactions & period totals.\n'
          '• Analysis: Track expense/income breakdown & trends.\n'
          '• Budgets: Set category spending limits per month.\n'
          '• Accounts: Manage wallets, cards & transfers.\n'
          '• Categories: Customize income & expense categories.\n'
          '• Tap + anytime to log a new transaction.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }
}

class _DrawerTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDark;
  final VoidCallback onTap;

  const _DrawerTile({
    required this.icon,
    required this.label,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Icon(
        icon,
        color: AppColors.primary,
        size: 22,
      ),
      title: Text(
        label,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: isDark ? Colors.white : AppColors.lightTextPrimary,
        ),
      ),
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
    );
  }
}
