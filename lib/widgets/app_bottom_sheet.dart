import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cashpilot/core/theme/app_colors.dart';

class AppBottomSheet extends StatelessWidget {
  final String? title;
  final Widget child;
  final double? initialChildSize;
  final double minChildSize;
  final double maxChildSize;
  final bool expand;

  const AppBottomSheet({
    super.key,
    this.title,
    required this.child,
    this.initialChildSize = 0.6,
    this.minChildSize = 0.3,
    this.maxChildSize = 0.95,
    this.expand = false,
  });

  static Future<T?> show<T>(
    BuildContext context, {
    String? title,
    required Widget child,
    double initialChildSize = 0.6,
    double minChildSize = 0.3,
    double maxChildSize = 0.95,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AppBottomSheet(
        title: title,
        child: child,
        initialChildSize: initialChildSize,
        minChildSize: minChildSize,
        maxChildSize: maxChildSize,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DraggableScrollableSheet(
      initialChildSize: initialChildSize ?? 0.6,
      minChildSize: minChildSize,
      maxChildSize: maxChildSize,
      expand: expand,
      builder: (context, controller) => Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.2)
                    : Colors.black.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            if (title != null) ...[
              const SizedBox(height: 16),
              Text(
                title!,
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF1a1a2e),
                ),
              ),
            ],
            const SizedBox(height: 8),
            Expanded(
              child: SingleChildScrollView(
                controller: controller,
                child: child,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
