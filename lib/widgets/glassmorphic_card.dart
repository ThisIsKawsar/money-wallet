import 'dart:ui';
import 'package:flutter/material.dart';

class GlassmorphicCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;
  final double blur;
  final double opacity;
  final Color? borderColor;
  final Gradient? gradient;
  final List<BoxShadow>? boxShadow;
  final double? width;
  final double? height;

  const GlassmorphicCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.borderRadius = 20,
    this.blur = 10,
    this.opacity = 0.08,
    this.borderColor,
    this.gradient,
    this.boxShadow,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final effectiveBorderColor =
        borderColor ?? Colors.white.withValues(alpha: isDark ? 0.08 : 0.3);

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          width: width,
          height: height,
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(borderRadius),
            gradient: gradient ??
                LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? [
                          Colors.white.withValues(alpha: opacity),
                          Colors.white.withValues(alpha: opacity * 0.5),
                        ]
                      : [
                          Colors.white.withValues(alpha: 0.7),
                          Colors.white.withValues(alpha: 0.4),
                        ],
                ),
            border: Border.all(color: effectiveBorderColor, width: 1),
            boxShadow: boxShadow,
          ),
          child: child,
        ),
      ),
    );
  }
}
