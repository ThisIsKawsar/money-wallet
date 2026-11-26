import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:cashpilot/core/theme/app_colors.dart';
import 'package:cashpilot/providers/settings_provider.dart';
import 'package:cashpilot/widgets/cashpilot_logo.dart';
import 'package:cashpilot/widgets/ui_kit.dart';
import 'package:cashpilot/widgets/wavy_background.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _nameCtrl = TextEditingController();
  bool _askingName = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _finishSetup() async {
    final settings = context.read<SettingsProvider>();
    final name = _nameCtrl.text.trim();
    if (name.isNotEmpty) {
      await settings.setUserName(name);
    }
    await settings.setOnboardingSeen();
    if (mounted) context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    if (_askingName) {
      return Scaffold(
        body: WavyBackground(
          showTopWaves: true,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(28, 20, 28, 24),
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back_rounded),
                      onPressed: () => setState(() => _askingName = false),
                    ),
                  ),
                  const Spacer(),
                  const CashPilotLogo(size: 84, glow: true),
                  const SizedBox(height: 24),
                  Text(
                    'What should we call you?',
                    textAlign: TextAlign.center,
                    style: jakarta(26,
                        weight: FontWeight.w800,
                        color: context.textPrimary,
                        spacing: -0.5),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Personalize your Cash Flow home screen.',
                    textAlign: TextAlign.center,
                    style: jakarta(14.5,
                        weight: FontWeight.w500, color: context.textSecondary),
                  ),
                  const SizedBox(height: 28),
                  TextField(
                    controller: _nameCtrl,
                    autofocus: true,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _finishSetup(),
                    style: jakarta(16,
                        weight: FontWeight.w600, color: context.textPrimary),
                    decoration: InputDecoration(
                      hintText: 'Enter your name',
                      prefixIcon: Icon(Icons.person_outline_rounded,
                          color: AppColors.primary),
                      filled: true,
                      fillColor: Theme.of(context).brightness == Brightness.dark
                          ? AppColors.darkCard
                          : AppColors.lightSurface,
                    ),
                  ),
                  const Spacer(flex: 2),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.22),
                          shape: BoxShape.circle,
                        ),
                      ),
                      Container(
                        width: 8,
                        height: 8,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  GradientButton(
                    label: 'Continue',
                    trailingIcon: Icons.arrow_forward_rounded,
                    onPressed: _finishSetup,
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: WavyBackground(
        showTopWaves: true,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(28, 24, 28, 24),
            child: Column(
              children: [
                const Spacer(flex: 2),
                const CashPilotLogo(size: 100, glow: true),
                const SizedBox(height: 24),
                Text(
                  'Cash Flow',
                  textAlign: TextAlign.center,
                  style: jakarta(38,
                      weight: FontWeight.w800,
                      color: context.textPrimary,
                      spacing: -0.8),
                ),
                const SizedBox(height: 8),
                Text(
                  'Smart Wallet. Better Life.',
                  textAlign: TextAlign.center,
                  style: jakarta(15.5,
                      weight: FontWeight.w500, color: context.textSecondary),
                ),
                const Spacer(flex: 2),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.22),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                GradientButton(
                  label: 'Get Started',
                  trailingIcon: Icons.arrow_forward_rounded,
                  onPressed: () => setState(() => _askingName = true),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
