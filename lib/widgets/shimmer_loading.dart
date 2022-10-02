import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:cashpilot/core/theme/app_colors.dart';

class ShimmerBox extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const ShimmerBox({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 8,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Shimmer.fromColors(
      baseColor: isDark ? AppColors.darkCard : AppColors.lightCardAlt,
      highlightColor: isDark ? AppColors.darkCardAlt : AppColors.lightBorder,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.lightCardAlt,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}

class ShimmerTransactionList extends StatelessWidget {
  final int itemCount;
  const ShimmerTransactionList({super.key, this.itemCount = 5});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: itemCount,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, _) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: [
            ShimmerBox(width: 44, height: 44, borderRadius: 14),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ShimmerBox(
                      width: double.infinity, height: 14, borderRadius: 4),
                  const SizedBox(height: 6),
                  ShimmerBox(width: 100, height: 12, borderRadius: 4),
                ],
              ),
            ),
            const SizedBox(width: 14),
            ShimmerBox(width: 60, height: 14, borderRadius: 4),
          ],
        ),
      ),
    );
  }
}
