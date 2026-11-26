import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cashpilot/core/theme/app_colors.dart';
import 'package:cashpilot/core/constants/app_constants.dart';
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
                Navigator.pop(context);
                context.push('/settings/data?tab=export');
              },
            ),
            _DrawerTile(
              icon: Icons.download_rounded,
              label: 'Import Data',
              isDark: isDark,
              onTap: () {
                Navigator.pop(context);
                context.push('/settings/data');
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
