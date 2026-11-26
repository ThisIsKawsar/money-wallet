import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Glossy green wallet with a sprouting leaf. The same painter renders the
/// launcher icon (see tool/generate_icons_test.dart), so app + icon match.
class CashPilotLogo extends StatelessWidget {
  final double size;
  final bool glow;

  const CashPilotLogo({super.key, this.size = 84, this.glow = false});

  @override
  Widget build(BuildContext context) {
    final logo = CustomPaint(
      size: Size.square(size),
      painter: const CashPilotLogoPainter(),
    );
    if (!glow) return logo;
    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        Container(
          width: size * 1.5,
          height: size * 1.5,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(colors: [
              const Color(0xFF2BD27A).withValues(alpha: 0.28),
              const Color(0xFF2BD27A).withValues(alpha: 0.0),
            ]),
          ),
        ),
        logo,
      ],
    );
  }
}

class CashPilotLogoPainter extends CustomPainter {
  const CashPilotLogoPainter();

  static const _deep = Color(0xFF0A7A3C);
  static const _mid = Color(0xFF14A453);
  static const _bright = Color(0xFF3BD57F);

  Path _leaf(Offset base, Offset tip, double width) {
    final d = tip - base;
    final len = d.distance;
    final n = Offset(-d.dy / len, d.dx / len) * width;
    return Path()
      ..moveTo(base.dx, base.dy)
      ..cubicTo(
        base.dx + d.dx * 0.15 + n.dx * 1.3, base.dy + d.dy * 0.15 + n.dy * 1.3,
        base.dx + d.dx * 0.70 + n.dx * 1.1, base.dy + d.dy * 0.70 + n.dy * 1.1,
        tip.dx, tip.dy,
      )
      ..cubicTo(
        base.dx + d.dx * 0.70 - n.dx * 1.1, base.dy + d.dy * 0.70 - n.dy * 1.1,
        base.dx + d.dx * 0.15 - n.dx * 1.3, base.dy + d.dy * 0.15 - n.dy * 1.3,
        base.dx, base.dy,
      )
      ..close();
  }

  void _drawLeaf(Canvas canvas, Offset base, Offset tip, double width,
      List<Color> colors, double s) {
    final path = _leaf(base, tip, width);
    final bounds = path.getBounds();
    canvas.drawPath(
      path.shift(Offset(0, s * 0.012)),
      Paint()
        ..color = _deep.withValues(alpha: 0.25)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, s * 0.012),
    );
    canvas.drawPath(
      path,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.bottomLeft,
          end: Alignment.topRight,
          colors: colors,
        ).createShader(bounds),
    );
    // Midrib
    final mid = Offset.lerp(base, tip, 0.82)!;
    canvas.drawLine(
      Offset.lerp(base, tip, 0.12)!,
      mid,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.55)
        ..strokeWidth = s * 0.012
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;

    // ── Back pocket (darker, tilted, peeking above the body) ─────────────
    canvas.save();
    final pocketCenter = Offset(s * 0.42, s * 0.33);
    canvas.translate(pocketCenter.dx, pocketCenter.dy);
    canvas.rotate(-10 * math.pi / 180);
    final pocket = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset.zero, width: s * 0.58, height: s * 0.26),
      Radius.circular(s * 0.09),
    );
    canvas.drawRRect(
      pocket,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1DB862), _deep],
        ).createShader(pocket.outerRect),
    );
    canvas.restore();

    // ── Leaves sprouting from behind the body ────────────────────────────
    _drawLeaf(canvas, Offset(s * 0.62, s * 0.30), Offset(s * 0.86, s * 0.05),
        s * 0.085, const [Color(0xFF16A853), Color(0xFF7BEAA9)], s);
    _drawLeaf(canvas, Offset(s * 0.60, s * 0.31), Offset(s * 0.48, s * 0.10),
        s * 0.055, const [Color(0xFF1FB45E), Color(0xFF8FF0B6)], s);

    // ── Body shadow ──────────────────────────────────────────────────────
    final body = RRect.fromRectAndRadius(
      Rect.fromLTWH(s * 0.08, s * 0.30, s * 0.80, s * 0.58),
      Radius.circular(s * 0.17),
    );
    canvas.drawRRect(
      body.shift(Offset(0, s * 0.035)),
      Paint()
        ..color = _deep.withValues(alpha: 0.35)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, s * 0.04),
    );

    // ── Body ─────────────────────────────────────────────────────────────
    canvas.drawRRect(
      body,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_bright, _mid, _deep],
          stops: [0, 0.55, 1],
        ).createShader(body.outerRect),
    );

    // Gloss sheen on the upper half
    canvas.save();
    canvas.clipRRect(body);
    final sheen = Rect.fromLTWH(body.left, body.top, body.width, body.height * 0.5);
    canvas.drawRect(
      sheen,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withValues(alpha: 0.30),
            Colors.white.withValues(alpha: 0.0),
          ],
        ).createShader(sheen),
    );
    // Stitch line
    final stitch = RRect.fromRectAndRadius(
      body.outerRect.deflate(s * 0.045),
      Radius.circular(s * 0.13),
    );
    final dash = Paint()
      ..color = Colors.white.withValues(alpha: 0.28)
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.008;
    final stitchPath = Path()..addRRect(stitch);
    for (final metric in stitchPath.computeMetrics()) {
      double d = 0;
      while (d < metric.length) {
        canvas.drawPath(metric.extractPath(d, d + s * 0.03), dash);
        d += s * 0.05;
      }
    }
    canvas.restore();

    // ── Clasp ────────────────────────────────────────────────────────────
    final clasp = RRect.fromRectAndRadius(
      Rect.fromLTWH(s * 0.58, s * 0.48, s * 0.36, s * 0.24),
      Radius.circular(s * 0.12),
    );
    canvas.drawRRect(
      clasp.shift(Offset(0, s * 0.015)),
      Paint()
        ..color = _deep.withValues(alpha: 0.35)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, s * 0.02),
    );
    canvas.drawRRect(
      clasp,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.white, Color(0xFFE3F6EA)],
        ).createShader(clasp.outerRect),
    );
    final inner = RRect.fromRectAndRadius(
      clasp.outerRect.deflate(s * 0.035),
      Radius.circular(s * 0.085),
    );
    canvas.drawRRect(
      inner,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2CC46F), _deep],
        ).createShader(inner.outerRect),
    );
    canvas.drawCircle(
      Offset(inner.left + inner.height / 2 + s * 0.01, inner.center.dy),
      s * 0.04,
      Paint()..color = Colors.white,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
