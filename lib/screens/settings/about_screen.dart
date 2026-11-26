import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:cashpilot/core/constants/app_constants.dart';
import 'package:cashpilot/core/theme/app_colors.dart';
import 'package:cashpilot/core/utils/developer_mode.dart';
import 'package:cashpilot/providers/settings_provider.dart';
import 'package:cashpilot/widgets/cashpilot_logo.dart';
import 'package:cashpilot/widgets/ui_kit.dart';
import 'package:cashpilot/widgets/wavy_background.dart';

/// About page. Tapping the version row 3 times unlocks Developer Options,
/// where Developer Mode seeds demo data (on) or removes it (off).
class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  static const _tapsNeeded = 3;
  int _taps = 0;
  DateTime _lastTap = DateTime.fromMillisecondsSinceEpoch(0);
  bool _busy = false;
  bool _revealed = false; // shown only after 3 taps, every visit
  final _devKey = GlobalKey();

  Future<void> _onVersionTap() async {
    if (_revealed) return;
    final now = DateTime.now();
    _taps = now.difference(_lastTap) > const Duration(seconds: 2) ? 1 : _taps + 1;
    _lastTap = now;
    HapticFeedback.selectionClick();

    final left = _tapsNeeded - _taps;
    if (left > 0) {
      showToast(context, 'You are $left tap${left == 1 ? '' : 's'} away from developer options',
          icon: Icons.touch_app_rounded);
      return;
    }
    _taps = 0;
    HapticFeedback.heavyImpact();
    setState(() => _revealed = true);
    showToast(context, 'Developer options unlocked!', icon: Icons.code_rounded);
    await Future.delayed(const Duration(milliseconds: 250));
    final ctx = _devKey.currentContext;
    if (ctx != null && ctx.mounted) {
      Scrollable.ensureVisible(ctx, duration: const Duration(milliseconds: 400), curve: Curves.easeOut);
    }
  }

  Future<void> _setDevMode(bool on) async {
    if (!on) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Turn off Developer Mode?'),
          content: const Text(
              'All demo accounts, transactions, budgets, goals, debts and reminders will be removed. Your own data stays untouched.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Remove demo data', style: TextStyle(color: AppColors.expense))),
          ],
        ),
      );
      if (ok != true || !mounted) return;
    }
    if (await _run(on)) {
      if (!mounted) return;
      showToast(context, on ? 'Demo data loaded — explore the app!' : 'Demo data removed',
          icon: on ? Icons.auto_awesome_rounded : Icons.cleaning_services_rounded);
    }
  }

  /// Runs [DeveloperMode.set]; shows the error instead of failing silently.
  Future<bool> _run(bool on) async {
    setState(() => _busy = true);
    try {
      await DeveloperMode.set(context, on);
      return true;
    } catch (e) {
      if (mounted) showToast(context, 'Could not ${on ? 'load' : 'remove'} demo data: $e', error: true);
      return false;
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _reseed() async {
    if (await _run(true) && mounted) showToast(context, 'Demo data refreshed');
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();

    return Scaffold(
      body: WavyBackground(
        showTopWaves: true,
        child: SafeArea(
          child: Column(
            children: [
              ScreenHeader(title: 'About App'),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 40),
                  children: [
                    const Center(child: CashPilotLogo(size: 104, glow: true)),
                    const SizedBox(height: 14),
                    Text(AppConstants.appName,
                        textAlign: TextAlign.center,
                        style: jakarta(30, weight: FontWeight.w800, color: context.textPrimary, spacing: -0.6)),
                    const SizedBox(height: 4),
                    Text(AppConstants.tagline,
                        textAlign: TextAlign.center, style: jakarta(14, color: context.textSecondary)),
                    const SizedBox(height: 26),

                    SoftCard(
                      padding: EdgeInsets.zero,
                      child: Column(
                        children: [
                          _InfoRow(
                            icon: Icons.verified_outlined,
                            label: 'Version',
                            value: '${AppConstants.appVersion} (${AppConstants.buildNumber})',
                            onTap: _onVersionTap,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    SoftCard(
                      child: Text(
                        '${AppConstants.appName} helps you track income and expenses, plan monthly budgets, '
                        'move money between accounts and understand your spending with clear analytics.',
                        style: jakarta(13.5, color: context.textSecondary, height: 1.55),
                      ),
                    ),

                    // ── Developer options ─────────────────────────────────
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 350),
                      transitionBuilder: (child, a) => SizeTransition(
                        sizeFactor: a,
                        child: FadeTransition(opacity: a, child: child),
                      ),
                      child: !_revealed
                          ? const SizedBox.shrink()
                          : Column(
                              key: _devKey,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const SizedBox(height: 24),
                                Padding(
                                  padding: const EdgeInsets.only(left: 4, bottom: 10),
                                  child: Text('DEVELOPER OPTIONS',
                                      style: jakarta(11.5,
                                          weight: FontWeight.w700, color: context.textTertiary, spacing: 1)),
                                ),
                                Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(20),
                                    gradient: LinearGradient(colors: [
                                      const Color(0xFFF59E0B).withValues(alpha: context.isDark ? 0.16 : 0.07),
                                      const Color(0xFFF59E0B).withValues(alpha: context.isDark ? 0.10 : 0.14),
                                    ]),
                                    border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.25)),
                                  ),
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          const GlossyIcon(
                                              icon: Icons.developer_mode_rounded,
                                              color: Color(0xFFF59E0B),
                                              size: 44),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text('Developer Mode',
                                                    style: jakarta(15.5,
                                                        weight: FontWeight.w700, color: context.textPrimary)),
                                                Text(settings.developerMode ? 'Demo data is loaded' : 'Off',
                                                    style: jakarta(12.5, color: context.textSecondary)),
                                              ],
                                            ),
                                          ),
                                          _busy
                                              ? const Padding(
                                                  padding: EdgeInsets.all(10),
                                                  child: SizedBox(
                                                    width: 22,
                                                    height: 22,
                                                    child: CircularProgressIndicator(strokeWidth: 2.4),
                                                  ),
                                                )
                                              : Switch.adaptive(
                                                  value: settings.developerMode,
                                                  activeTrackColor: const Color(0xFFF59E0B),
                                                  onChanged: _setDevMode,
                                                ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        'Turning this on fills the app with 4 months of sample accounts, '
                                        'transactions, budgets, goals, debts and reminders. Turning it off '
                                        'removes only that demo data.',
                                        style: jakarta(12.5, color: context.textSecondary, height: 1.5),
                                      ),
                                      if (settings.developerMode) ...[
                                        const SizedBox(height: 12),
                                        Align(
                                          alignment: Alignment.centerLeft,
                                          child: TextButton.icon(
                                            onPressed: _busy ? null : _reseed,
                                            icon: const Icon(Icons.refresh_rounded, size: 18, color: Color(0xFFD97706)),
                                            label: Text('Refresh demo data',
                                                style: jakarta(13,
                                                    weight: FontWeight.w700, color: const Color(0xFFD97706))),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                    ),
                    const SizedBox(height: 28),
                    Text('Made with 💚 for better money habits',
                        textAlign: TextAlign.center, style: jakarta(12, color: context.textTertiary)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onTap;

  const _InfoRow({required this.icon, required this.label, required this.value, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        child: Row(
          children: [
            Icon(icon, size: 22, color: AppColors.primary),
            const SizedBox(width: 18),
            Expanded(child: Text(label, style: jakarta(15, weight: FontWeight.w600, color: context.textPrimary))),
            Text(value, style: jakarta(14, color: context.textSecondary)),
          ],
        ),
      ),
    );
  }
}
