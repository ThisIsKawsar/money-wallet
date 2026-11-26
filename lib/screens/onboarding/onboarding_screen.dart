import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:cashpilot/core/theme/app_colors.dart';
import 'package:cashpilot/core/constants/app_constants.dart';
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
  final _controller = PageController();
  int _page = 0;

  static const _slides = [
    (title: AppConstants.appName, subtitle: AppConstants.tagline),
    (title: 'Track Effortlessly', subtitle: 'Income, expenses and transfers —\nall in one beautiful place.'),
    (title: 'Grow Your Savings', subtitle: 'Smart budgets, clear insights and\ngoals that keep you on track.'),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _next() async {
    if (_page < _slides.length - 1) {
      _controller.nextPage(
          duration: const Duration(milliseconds: 380), curve: Curves.easeOutCubic);
      return;
    }
    await context.read<SettingsProvider>().setOnboardingSeen();
    if (mounted) context.go('/');
  }

  Widget _illustration(int i) {
    switch (i) {
      case 0:
        return const CashPilotLogo(size: 120, glow: true);
      case 1:
        return _FloatingCluster(
          center: (Icons.bar_chart_rounded, AppColors.primary),
          satellites: [
            (Icons.arrow_downward_rounded, AppColors.income, Offset(-78, -46)),
            (Icons.arrow_upward_rounded, AppColors.expense, Offset(80, -30)),
            (Icons.swap_horiz_rounded, AppColors.transfer, Offset(-62, 64)),
            (Icons.receipt_long_rounded, Color(0xFFF59E0B), Offset(72, 70)),
          ],
        );
      default:
        return _FloatingCluster(
          center: (Icons.savings_rounded, AppColors.primary),
          satellites: [
            (Icons.flag_rounded, Color(0xFFA855F7), Offset(-80, -40)),
            (Icons.emoji_events_rounded, Color(0xFFF59E0B), Offset(78, -48)),
            (Icons.trending_up_rounded, AppColors.transfer, Offset(-66, 66)),
            (Icons.pie_chart_rounded, Color(0xFFEC4899), Offset(74, 62)),
          ],
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final last = _page == _slides.length - 1;
    return Scaffold(
      body: WavyBackground(
        showTopWaves: true,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(28, 12, 28, 20),
            child: Column(
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: AnimatedOpacity(
                    opacity: last ? 0 : 1,
                    duration: const Duration(milliseconds: 200),
                    child: TextButton(
                      onPressed: last
                          ? null
                          : () => _controller.animateToPage(_slides.length - 1,
                              duration: const Duration(milliseconds: 420),
                              curve: Curves.easeOutCubic),
                      child: Text('Skip',
                          style: jakarta(14,
                              weight: FontWeight.w600, color: context.textSecondary)),
                    ),
                  ),
                ),
                Expanded(
                  child: PageView.builder(
                    controller: _controller,
                    itemCount: _slides.length,
                    onPageChanged: (i) => setState(() => _page = i),
                    itemBuilder: (context, i) {
                      final s = _slides[i];
                      return Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(height: 230, child: Center(child: _illustration(i))),
                          const SizedBox(height: 18),
                          Text(s.title,
                              textAlign: TextAlign.center,
                              style: jakarta(i == 0 ? 40 : 30,
                                  weight: FontWeight.w800,
                                  color: context.textPrimary,
                                  spacing: -0.8)),
                          const SizedBox(height: 10),
                          Text(s.subtitle,
                              textAlign: TextAlign.center,
                              style: jakarta(15.5,
                                  weight: FontWeight.w500,
                                  color: context.textSecondary,
                                  height: 1.5)),
                        ],
                      );
                    },
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_slides.length, (i) {
                    final active = i == _page;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: active ? 22 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: active
                            ? AppColors.primary
                            : AppColors.primary.withValues(alpha: 0.22),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 30),
                GradientButton(
                  label: last ? 'Get Started' : 'Next',
                  trailingIcon: Icons.arrow_forward_rounded,
                  onPressed: _next,
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

/// Big glossy icon with smaller badges orbiting and gently bobbing.
class _FloatingCluster extends StatefulWidget {
  final (IconData, Color) center;
  final List<(IconData, Color, Offset)> satellites;

  const _FloatingCluster({required this.center, required this.satellites});

  @override
  State<_FloatingCluster> createState() => _FloatingClusterState();
}

class _FloatingClusterState extends State<_FloatingCluster>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 3),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final t = Curves.easeInOut.transform(_c.value);
        return SizedBox(
          width: 240,
          height: 230,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 190,
                height: 190,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [
                    AppColors.primary.withValues(alpha: 0.16),
                    AppColors.primary.withValues(alpha: 0.0),
                  ]),
                ),
              ),
              Transform.translate(
                offset: Offset(0, -4 + 8 * t),
                child: GlossyIcon(
                    icon: widget.center.$1,
                    color: widget.center.$2,
                    size: 104,
                    iconSize: 54),
              ),
              for (var i = 0; i < widget.satellites.length; i++)
                Transform.translate(
                  offset: widget.satellites[i].$3 +
                      Offset(0, (i.isEven ? 6 : -6) * (t - 0.5)),
                  child: GlossyIcon(
                    icon: widget.satellites[i].$1,
                    color: widget.satellites[i].$2,
                    size: 46,
                    circle: true,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
