// Renders the launcher icon PNGs from CashPilotLogoPainter.
//
//   flutter test tool/generate_icons_test.dart
//   dart run flutter_launcher_icons
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cashpilot/widgets/cashpilot_logo.dart';

Future<void> _render(String path, {required bool background, required double logoScale}) async {
  const size = 1024.0;
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  const rect = Rect.fromLTWH(0, 0, size, size);

  if (background) {
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFF5FCF8), Color(0xFFD5F2E1)],
        ).createShader(rect),
    );
    canvas.drawCircle(
      const Offset(size * 0.5, size * 0.52),
      size * 0.42,
      Paint()
        ..shader = RadialGradient(colors: [
          Colors.white.withValues(alpha: 0.9),
          Colors.white.withValues(alpha: 0.0),
        ]).createShader(
            Rect.fromCircle(center: const Offset(size * 0.5, size * 0.52), radius: size * 0.42)),
    );
  }

  final logo = size * logoScale;
  canvas.save();
  canvas.translate((size - logo) / 2, (size - logo) / 2 + size * 0.01);
  const CashPilotLogoPainter().paint(canvas, Size.square(logo));
  canvas.restore();

  final image = await recorder.endRecording().toImage(size.toInt(), size.toInt());
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  File(path).writeAsBytesSync(bytes!.buffer.asUint8List());
}

void main() {
  testWidgets('generate launcher icons', (tester) async {
    await tester.runAsync(() async {
      await _render('assets/icon/icon.png', background: true, logoScale: 0.70);
      // Adaptive foreground must sit inside the 66% safe zone.
      await _render('assets/icon/icon_foreground.png', background: false, logoScale: 0.54);
    });
  });
}
