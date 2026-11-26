import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cashpilot/core/theme/app_colors.dart';
import 'package:cashpilot/core/constants/app_constants.dart';
import 'package:cashpilot/core/utils/data_transfer.dart';
import 'package:cashpilot/providers/transaction_provider.dart';
import 'package:cashpilot/providers/account_provider.dart';
import 'package:cashpilot/providers/category_provider.dart';
import 'package:cashpilot/providers/settings_provider.dart';
import 'package:cashpilot/screens/passcode/passcode_screen.dart';
import 'package:cashpilot/widgets/cashpilot_logo.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  String _themeLabel(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
      case ThemeMode.system:
        return 'System';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final settings = context.watch<SettingsProvider>();

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
                        'v${AppConstants.appVersion}',
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

            _sectionLabel('Preferences', isDark),
            _DrawerTile(
              icon: Icons.palette_outlined,
              label: 'Appearance',
              trailing: '${_themeLabel(settings.themeMode)} · ${settings.accentName}',
              isDark: isDark,
              onTap: () {
                Navigator.pop(context);
                context.push('/settings/appearance');
              },
            ),
            _DrawerTile(
              icon: Icons.attach_money_rounded,
              label: 'Currency',
              trailing: '${settings.currency} ${settings.currencySymbol}',
              isDark: isDark,
              onTap: () {
                Navigator.pop(context);
                context.push('/settings/currency');
              },
            ),
            _DrawerTile(
              icon: Icons.shield_outlined,
              label: 'Security (PIN)',
              trailing: settings.passcodeEnabled ? 'On' : 'Off',
              isDark: isDark,
              onTap: () {
                Navigator.pop(context);
                if (settings.passcodeEnabled) {
                  settings.disablePasscode();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('PIN lock turned off'),
                      backgroundColor: AppColors.primary,
                    ),
                  );
                } else {
                  context.push('/passcode-lock',
                      extra: {'mode': PasscodeMode.setup});
                }
              },
            ),
            _DrawerTile(
              icon: Icons.local_offer_outlined,
              label: 'Categories',
              isDark: isDark,
              onTap: () {
                Navigator.pop(context);
                context.push('/categories');
              },
            ),
            const Divider(height: 16),

            _sectionLabel('Data & Management', isDark),
            _DrawerTile(
              icon: Icons.upload_file_rounded,
              label: 'Export Data',
              isDark: isDark,
              onTap: () {
                final nav = Navigator.of(context);
                nav.pop();
                _showExportDialog(nav.context);
              },
            ),
            _DrawerTile(
              icon: Icons.download_rounded,
              label: 'Import Data',
              isDark: isDark,
              onTap: () {
                final nav = Navigator.of(context);
                nav.pop();
                _showImportDialog(nav.context);
              },
            ),
            const Divider(height: 16),

            _sectionLabel('Finance & Tools', isDark),
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
              label: 'About App',
              trailing: 'v${AppConstants.appVersion}',
              isDark: isDark,
              onTap: () {
                Navigator.pop(context);
                context.push('/settings/about');
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

  void _showExportDialog(BuildContext context) {
    final txp = context.read<TransactionProvider>();
    final accs = context.read<AccountProvider>().accounts;
    final cats = context.read<CategoryProvider>().categories;
    final size = MediaQuery.of(context).size;
    final origin = Rect.fromCenter(
        center: Offset(size.width / 2, size.height / 2), width: 2, height: 2);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Export Data'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading:
                  const Icon(Icons.table_chart_rounded, color: AppColors.income),
              title: const Text('Export CSV'),
              subtitle: const Text('Open in Excel, Numbers or Sheets'),
              onTap: () async {
                Navigator.pop(ctx);
                if (txp.transactions.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('No transactions to export'),
                      backgroundColor: AppColors.expense,
                    ),
                  );
                  return;
                }
                await DataTransfer.shareFile(
                  'cashpilot_transactions_${DataTransfer.stamp()}.csv',
                  DataTransfer.buildCsv(txp.transactions, accs, cats),
                  origin: origin,
                  text: 'CashPilot transactions',
                );
              },
            ),
            ListTile(
              leading:
                  const Icon(Icons.backup_rounded, color: AppColors.transfer),
              title: const Text('Full Backup (JSON)'),
              subtitle:
                  const Text('Accounts, categories, transactions & budgets'),
              onTap: () async {
                Navigator.pop(ctx);
                await DataTransfer.shareFile(
                  'cashpilot_backup_${DataTransfer.stamp()}.json',
                  await DataTransfer.buildBackupJson(),
                  origin: origin,
                  text: 'CashPilot backup',
                );
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showImportDialog(BuildContext context) {
    final reload = DataTransfer.reloader(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Import Data'),
        content: const Text(
          '• Choose a CSV file ("TIME","TYPE","AMOUNT","CATEGORY","ACCOUNT","NOTES") to import transactions.\n'
          '• Or choose a CashPilot backup (.json) to restore all data.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                final res = await DataTransfer.pickAndImport();
                if (res == null) return;
                await reload();
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      res.kind == 'backup'
                          ? 'Backup restored · ${res.added} transactions'
                          : 'Imported ${res.added} transactions${res.skipped > 0 ? ' · ${res.skipped} skipped' : ''}',
                    ),
                    backgroundColor: AppColors.primary,
                  ),
                );
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          e is FormatException ? e.message : 'Import failed: $e'),
                      backgroundColor: AppColors.expense,
                    ),
                  );
                }
              }
            },
            icon: const Icon(Icons.folder_open_rounded),
            label: const Text('Choose File'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
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
          '• Home: Overview of balance, quick actions & chart.\n'
          '• Budgets: Set category spending limits per month.\n'
          '• Accounts: Manage wallets, cards & transfers.\n'
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
  final String? trailing;
  final bool isDark;
  final VoidCallback onTap;

  const _DrawerTile({
    required this.icon,
    required this.label,
    this.trailing,
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
      trailing: trailing != null
          ? Text(
              trailing!,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
              ),
            )
          : null,
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
    );
  }
}
