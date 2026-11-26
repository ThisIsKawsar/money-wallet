import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:cashpilot/providers/settings_provider.dart';
import 'package:cashpilot/core/theme/app_colors.dart';
import 'package:cashpilot/core/constants/app_constants.dart';
import 'package:cashpilot/screens/passcode/passcode_screen.dart';
import 'package:cashpilot/widgets/cashpilot_logo.dart';
import 'package:cashpilot/widgets/wavy_background.dart';
import 'package:cashpilot/widgets/ui_kit.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  static String themeLabel(ThemeMode m) => switch (m) {
        ThemeMode.light => 'Light',
        ThemeMode.dark => 'Dark',
        ThemeMode.system => 'System',
      };

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();

    return Scaffold(
      body: WavyBackground(
        child: SafeArea(
          bottom: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 120),
            children: [
              const ScreenHeader(title: 'Preferences', showBack: true),
              const SizedBox(height: 8),

              const _GroupLabel('Preferences'),
              _Tile(
                icon: Icons.palette_outlined,
                title: 'Appearance',
                subtitle: 'Light, Dark, System',
                trailing: '${themeLabel(settings.themeMode)} · ${settings.accentName}',
                onTap: () => context.push('/settings/appearance'),
              ),
              _Tile(
                icon: Icons.attach_money_rounded,
                title: 'Currency',
                subtitle: 'Display currency',
                trailing: '${settings.currency} ${settings.currencySymbol}',
                onTap: () => context.push('/settings/currency'),
              ),
              _Tile(
                icon: Icons.shield_outlined,
                title: 'Security',
                subtitle: settings.passcodeEnabled ? 'PIN lock is on' : 'Protect the app with a PIN',
                trailingWidget: Switch.adaptive(
                  value: settings.passcodeEnabled,
                  activeTrackColor: AppColors.primary,
                  onChanged: (_) => _toggleSecurity(context, settings),
                ),
                onTap: () => _toggleSecurity(context, settings),
              ),
              const SizedBox(height: 14),

              const _GroupLabel('Money'),
              _Tile(
                icon: Icons.account_balance_wallet_outlined,
                title: 'My Wallet',
                subtitle: 'Accounts & balances',
                onTap: () => context.push('/accounts'),
              ),
              _Tile(
                icon: Icons.receipt_long_outlined,
                title: 'All Transactions',
                subtitle: 'Search & filter history',
                onTap: () => context.push('/transactions'),
              ),
              _Tile(
                icon: Icons.category_outlined,
                title: 'Categories',
                subtitle: 'Customize income & expense types',
                onTap: () => context.push('/settings/categories'),
              ),
              const SizedBox(height: 14),

              const _GroupLabel('Data'),
              _Tile(
                icon: Icons.upload_file_rounded,
                title: 'Export Data',
                subtitle: 'CSV spreadsheet or full backup',
                onTap: () => context.push('/settings/data?tab=export'),
              ),
              _Tile(
                icon: Icons.download_rounded,
                title: 'Import Data',
                subtitle: 'CSV template, instructions & backup restore',
                onTap: () => context.push('/settings/data'),
              ),
              const SizedBox(height: 14),

              const _GroupLabel('App'),
              _Tile(
                icon: Icons.info_outline_rounded,
                title: 'About App',
                subtitle: 'Version ${AppConstants.appVersion}',
                onTap: () => context.push('/settings/about'),
              ),
              const SizedBox(height: 16),

              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  gradient: LinearGradient(colors: [
                    AppColors.primary.withValues(alpha: context.isDark ? 0.16 : 0.06),
                    AppColors.primary.withValues(alpha: context.isDark ? 0.10 : 0.13),
                  ]),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.12)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CashPilotLogo(size: 44),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(AppConstants.appName,
                            style: jakarta(18, weight: FontWeight.w800, color: context.textPrimary)),
                        Text(AppConstants.tagline, style: jakarta(12, color: context.textSecondary)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _toggleSecurity(BuildContext context, SettingsProvider settings) {
    if (settings.passcodeEnabled) {
      settings.disablePasscode();
      showToast(context, 'PIN lock turned off');
    } else {
      context.push('/passcode-lock', extra: {'mode': PasscodeMode.setup});
    }
  }
}

class _GroupLabel extends StatelessWidget {
  final String text;
  const _GroupLabel(this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 10),
        child: Text(text.toUpperCase(),
            style: jakarta(11.5, weight: FontWeight.w700, color: context.textTertiary, spacing: 1)),
      );
}

class _Tile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? trailing;
  final Widget? trailingWidget;
  final VoidCallback onTap;

  const _Tile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.trailingWidget,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      margin: const EdgeInsets.only(bottom: 10),
      radius: 18,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: context.isDark ? 0.15 : 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 21, color: context.isDark ? AppColors.accent : AppColors.primaryDark),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: jakarta(15, weight: FontWeight.w600, color: context.textPrimary)),
                const SizedBox(height: 1),
                Text(subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: jakarta(12, color: context.textSecondary)),
              ],
            ),
          ),
          if (trailingWidget != null)
            trailingWidget!
          else ...[
            if (trailing != null)
              Text(trailing!, style: jakarta(12, weight: FontWeight.w600, color: context.textSecondary)),
            const SizedBox(width: 2),
            Icon(Icons.chevron_right_rounded, color: context.textTertiary),
          ],
        ],
      ),
    );
  }
}
