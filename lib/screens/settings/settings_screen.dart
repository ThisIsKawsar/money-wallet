import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cashpilot/providers/settings_provider.dart';
import 'package:cashpilot/providers/transaction_provider.dart';
import 'package:cashpilot/providers/account_provider.dart';
import 'package:cashpilot/providers/category_provider.dart';
import 'package:cashpilot/core/theme/app_colors.dart';
import 'package:cashpilot/screens/passcode/passcode_screen.dart';
import 'package:cashpilot/core/utils/export_helper.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final settings = context.watch<SettingsProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text('Settings',
            style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF1a1a2e))),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
        children: [
          // ── Appearance ──────────────────────────────────────────────────
          _sectionHeader('Appearance', isDark),

          // Theme toggle (inline)
          _InlineTile(
            icon: Icons.dark_mode_rounded,
            iconColor: const Color(0xFF6c5ce7),
            title: 'Theme',
            isDark: isDark,
            trailing: _ThemeSegmented(settings: settings),
          ),

          const SizedBox(height: 8),

          // ── General ─────────────────────────────────────────────────────
          _sectionHeader('General', isDark),

          _SettingsTile(
            icon: Icons.attach_money_rounded,
            iconColor: AppColors.income,
            title: 'Currency',
            subtitle: '${settings.currency}  ${settings.currencySymbol}',
            isDark: isDark,
            onTap: () => context.push('/settings/currency'),
          ),

          // Decimal formatting (inline toggle)
          _InlineTile(
            icon: Icons.pin_outlined,
            iconColor: AppColors.primary,
            title: 'Decimal Places',
            isDark: isDark,
            trailing: _DecimalToggle(settings: settings, isDark: isDark),
          ),

          const SizedBox(height: 8),

          // ── Data ────────────────────────────────────────────────────────
          _sectionHeader('Data', isDark),

          _SettingsTile(
            icon: Icons.category_rounded,
            iconColor: AppColors.primary,
            title: 'Categories',
            subtitle: 'Create, edit & delete categories',
            isDark: isDark,
            onTap: () => context.push('/settings/categories'),
          ),

          _SettingsTile(
            icon: Icons.account_balance_wallet_rounded,
            iconColor: const Color(0xFF00d4aa),
            title: 'Accounts',
            subtitle: 'Manage your accounts',
            isDark: isDark,
            onTap: () => context.push('/accounts'),
          ),

          const SizedBox(height: 8),

          // ── Finance ─────────────────────────────────────────────────────
          _sectionHeader('Finance', isDark),

          _SettingsTile(
            icon: Icons.credit_score_rounded,
            iconColor: const Color(0xFFff7675),
            title: 'Debts & Loans',
            subtitle: 'Track money you owe or are owed',
            isDark: isDark,
            onTap: () => context.push('/settings/debts'),
          ),

          _SettingsTile(
            icon: Icons.alarm_rounded,
            iconColor: const Color(0xFFfdcb6e),
            title: 'Bill Reminders',
            subtitle: 'Set up recurring bill reminders',
            isDark: isDark,
            onTap: () => context.push('/settings/reminders'),
          ),

          const SizedBox(height: 8),

          // ── Security ────────────────────────────────────────────────────
          _sectionHeader('Security', isDark),

          _InlineTile(
            icon: Icons.lock_rounded,
            iconColor: const Color(0xFF00d4aa),
            title: 'App Lock',
            subtitle: settings.passcodeEnabled ? 'PIN enabled' : 'Disabled',
            isDark: isDark,
            trailing: Switch(
              value: settings.passcodeEnabled,
              onChanged: (v) async {
                if (v) {
                  context.push('/passcode-lock',
                      extra: {'mode': PasscodeMode.setup});
                } else {
                  await settings.disablePasscode();
                }
              },
            ),
          ),

          if (settings.passcodeEnabled)
            _SettingsTile(
              icon: Icons.password_rounded,
              iconColor: AppColors.primary,
              title: 'Change Passcode',
              isDark: isDark,
              onTap: () => context.push('/passcode-lock',
                  extra: {'mode': PasscodeMode.change}),
            ),

          const SizedBox(height: 8),

          // ── About ───────────────────────────────────────────────────────
          _sectionHeader('About', isDark),

          _SettingsTile(
            icon: Icons.info_outline_rounded,
            iconColor: AppColors.primary,
            title: 'Version',
            subtitle: '1.0.0',
            isDark: isDark,
            onTap: null,
          ),

          const SizedBox(height: 8),

          // ── Data Management ─────────────────────────────────────────────
          _sectionHeader('Data Management', isDark),

          _SettingsTile(
            icon: Icons.file_download_rounded,
            iconColor: const Color(0xFF00d4aa),
            title: 'Export Data',
            subtitle: 'Export transactions to CSV',
            isDark: isDark,
            onTap: () => _showExportDialog(context, settings),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title, bool isDark) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
        child: Text(
          title.toUpperCase(),
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
            letterSpacing: 1.0,
          ),
        ),
      );

  void _showExportDialog(BuildContext context, SettingsProvider settings) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Export Data',
            style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.receipt_long_rounded, color: AppColors.primary),
              title: Text('Transactions',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
              onTap: () {
                Navigator.pop(ctx);
                _exportTransactions(context, settings);
              },
            ),
            ListTile(
              leading: const Icon(Icons.account_balance_wallet_rounded, color: AppColors.income),
              title: Text('Accounts',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
              onTap: () {
                Navigator.pop(ctx);
                _exportAccounts(context, settings);
              },
            ),
            ListTile(
              leading: const Icon(Icons.category_rounded, color: AppColors.expense),
              title: Text('Categories',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
              onTap: () {
                Navigator.pop(ctx);
                _exportCategories(context, settings);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportTransactions(BuildContext context, SettingsProvider settings) async {
    try {
      final txProvider = context.read<TransactionProvider>();
      final accProvider = context.read<AccountProvider>();
      final catProvider = context.read<CategoryProvider>();

      final csv = ExportHelper.exportTransactionsToCSV(
        txProvider.transactions,
        accProvider.accounts,
        catProvider.categories,
      );

      final directory = await getTemporaryDirectory();
      final path = '${directory.path}/cashpilot_transactions.csv';
      final file = File(path);
      await file.writeAsString(csv);

      await Share.shareXFiles([XFile(path)], text: 'CashPilot Transactions Export');
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    }
  }

  Future<void> _exportAccounts(BuildContext context, SettingsProvider settings) async {
    try {
      final accProvider = context.read<AccountProvider>();

      final csv = ExportHelper.exportAccountsToCSV(accProvider.accounts);

      final directory = await getTemporaryDirectory();
      final path = '${directory.path}/cashpilot_accounts.csv';
      final file = File(path);
      await file.writeAsString(csv);

      await Share.shareXFiles([XFile(path)], text: 'CashPilot Accounts Export');
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    }
  }

  Future<void> _exportCategories(BuildContext context, SettingsProvider settings) async {
    try {
      final catProvider = context.read<CategoryProvider>();

      final csv = ExportHelper.exportCategoriesToCSV(catProvider.categories);

      final directory = await getTemporaryDirectory();
      final path = '${directory.path}/cashpilot_categories.csv';
      final file = File(path);
      await file.writeAsString(csv);

      await Share.shareXFiles([XFile(path)], text: 'CashPilot Categories Export');
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    }
  }
}

// Segmented theme control
class _ThemeSegmented extends StatelessWidget {
  final SettingsProvider settings;
  const _ThemeSegmented({required this.settings});

  @override
  Widget build(BuildContext context) {
    final options = [
      {'mode': ThemeMode.dark, 'icon': Icons.dark_mode_rounded, 'label': 'Dark'},
      {'mode': ThemeMode.system, 'icon': Icons.brightness_auto_rounded, 'label': 'Auto'},
      {'mode': ThemeMode.light, 'icon': Icons.light_mode_rounded, 'label': 'Light'},
    ];
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: options.map((o) {
        final mode = o['mode'] as ThemeMode;
        final isSelected = settings.themeMode == mode;
        return GestureDetector(
          onTap: () => settings.setThemeMode(mode),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primary
                  : AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              o['icon'] as IconData,
              size: 18,
              color: isSelected ? Colors.white : AppColors.primary,
            ),
          ),
        );
      }).toList(),
    );
  }
}

// Decimal places toggle
class _DecimalToggle extends StatelessWidget {
  final SettingsProvider settings;
  final bool isDark;
  const _DecimalToggle({required this.settings, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [0, 2].map((places) {
        final isSelected = settings.decimalPlaces == places;
        return GestureDetector(
          onTap: () => settings.setDecimalPlaces(places),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.only(left: 6),
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primary
                  : AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              places == 0 ? '1,000' : '1,000.00',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : AppColors.primary,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final bool isDark;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.subtitle,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        title: Text(title,
            style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color:
                    isDark ? Colors.white : const Color(0xFF1a1a2e))),
        subtitle: subtitle != null
            ? Text(subtitle!,
                style: GoogleFonts.inter(
                    fontSize: 12,
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.45)
                        : Colors.black.withValues(alpha: 0.45)))
            : null,
        trailing: onTap != null
            ? Icon(Icons.chevron_right_rounded,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.3)
                    : Colors.black.withValues(alpha: 0.3))
            : null,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}

class _InlineTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final Widget trailing;
  final bool isDark;

  const _InlineTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.subtitle,
    required this.trailing,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? Colors.white
                            : const Color(0xFF1a1a2e))),
                if (subtitle != null)
                  Text(subtitle!,
                      style: GoogleFonts.inter(
                          fontSize: 12,
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.45)
                              : Colors.black.withValues(alpha: 0.45))),
              ],
            ),
          ),
          trailing,
        ],
      ),
    );
  }
}
