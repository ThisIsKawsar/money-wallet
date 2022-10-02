import 'package:flutter/material.dart';
import 'package:cashpilot/core/constants/app_icons.dart';
import 'package:cashpilot/core/theme/app_colors.dart';

class CategoryIcon extends StatelessWidget {
  final String? iconName;
  final String? colorHex;
  final double size;
  final double iconSize;
  final Color? color;

  const CategoryIcon({
    super.key,
    this.iconName,
    this.colorHex,
    this.size = 44,
    this.iconSize = 20,
    this.color,
  });

  Color _parseColor(String? hex) {
    if (hex == null || hex.isEmpty) return AppColors.primary;
    try {
      final clean = hex.replaceAll('#', '');
      return Color(int.parse('FF$clean', radix: 16));
    } catch (_) {
      return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final baseColor = color ?? _parseColor(colorHex);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: baseColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(size * 0.3),
      ),
      child: Icon(
        AppIcons.fromName(iconName),
        color: baseColor,
        size: iconSize,
      ),
    );
  }
}
