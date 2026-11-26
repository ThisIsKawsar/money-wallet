import 'package:flutter/material.dart';
import 'package:cashpilot/core/theme/app_colors.dart';

/// Clean white→mint backdrop with soft layered green hills at the bottom.
/// [showTopWaves] adds a mint wash with a gentle curve across the top
/// (used on hero screens like Home and Welcome).
class WavyBackground extends StatelessWidget {
  final Widget child;
  final bool showTopWaves;

  const WavyBackground({
    super.key,
    required this.child,
    this.showTopWaves = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Stack(
      children: [
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: isDark
                    ? [Color.lerp(AppColors.darkBg, AppColors.primary, 0.05)!, AppColors.darkBg]
                    : [AppColors.tint(0.01), AppColors.tint(0.06)],
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: RepaintBoundary(
              child: CustomPaint(
                painter: _HillsPainter(isDark: isDark, showTop: showTopWaves, brand: AppColors.primary),
              ),
            ),
          ),
        ),
        child,
      ],
    );
  }
}

class _HillsPainter extends CustomPainter {
  final bool isDark;
  final bool showTop;
  final Color brand;

  _HillsPainter({required this.isDark, required this.showTop, required this.brand});

  Paint _fill(Rect r, Color top, Color bottom) => Paint()
    ..shader = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [top, bottom],
    ).createShader(r);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final full = Offset.zero & size;

    Color g(double lightT, double darkAlpha) =>
        isDark ? brand.withValues(alpha: darkAlpha) : AppColors.tint(lightT);

    // ── Top mint wash ────────────────────────────────────────────────────
    if (showTop) {
      final top = Path()
        ..moveTo(0, 0)
        ..lineTo(w, 0)
        ..lineTo(w, h * 0.30)
        ..cubicTo(w * 0.80, h * 0.36, w * 0.55, h * 0.26, w * 0.30, h * 0.31)
        ..cubicTo(w * 0.15, h * 0.34, w * 0.05, h * 0.30, 0, h * 0.27)
        ..close();
      canvas.drawPath(
          top,
          _fill(Rect.fromLTWH(0, 0, w, h * 0.36),
              g(0.14, 0.10), g(0.05, 0.02)));
    }

    // Soft glow top-right
    final glowC = Offset(w * 0.95, h * 0.08);
    canvas.drawCircle(
      glowC,
      w * 0.7,
      Paint()
        ..shader = RadialGradient(colors: [
          isDark
              ? AppColors.primary.withValues(alpha: 0.08)
              : AppColors.tint(0.15).withValues(alpha: 0.8),
          // Fade to the same hue (not transparent black) to avoid a grey halo.
          isDark
              ? AppColors.primary.withValues(alpha: 0)
              : AppColors.tint(0.15).withValues(alpha: 0),
        ]).createShader(Rect.fromCircle(center: glowC, radius: w * 0.7)),
    );

    // ── Layered hills ────────────────────────────────────────────────────
    // Back hill: rises on the right
    final back = Path()
      ..moveTo(0, h * 0.86)
      ..cubicTo(w * 0.30, h * 0.84, w * 0.55, h * 0.80, w * 0.78, h * 0.78)
      ..cubicTo(w * 0.90, h * 0.77, w * 0.97, h * 0.79, w, h * 0.80)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(back, _fill(full, g(0.11, 0.05), g(0.17, 0.08)));

    // Middle hill: rises on the left
    final mid = Path()
      ..moveTo(0, h * 0.84)
      ..cubicTo(w * 0.18, h * 0.82, w * 0.36, h * 0.86, w * 0.55, h * 0.90)
      ..cubicTo(w * 0.75, h * 0.94, w * 0.90, h * 0.90, w, h * 0.88)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(
        mid,
        _fill(Rect.fromLTWH(0, h * 0.82, w, h * 0.18),
            g(0.18, 0.07), g(0.24, 0.10)));

    // Front hill: low, broad
    final front = Path()
      ..moveTo(0, h * 0.95)
      ..cubicTo(w * 0.25, h * 0.91, w * 0.50, h * 0.93, w * 0.70, h * 0.955)
      ..cubicTo(w * 0.85, h * 0.97, w * 0.95, h * 0.95, w, h * 0.935)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(
        front,
        _fill(Rect.fromLTWH(0, h * 0.91, w, h * 0.09),
            g(0.26, 0.10), g(0.31, 0.14)));
  }

  @override
  bool shouldRepaint(covariant _HillsPainter old) =>
      old.isDark != isDark || old.showTop != showTop || old.brand != brand;
}
