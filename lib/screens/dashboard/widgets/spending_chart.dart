import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:animate_do/animate_do.dart';

class SpendingChartData {
  final String categoryName;
  final double amount;
  final Color color;
  final String? iconName;

  const SpendingChartData({
    required this.categoryName,
    required this.amount,
    required this.color,
    this.iconName,
  });
}

class SpendingChart extends StatefulWidget {
  final List<SpendingChartData> spendingData;
  final double totalSpending;
  final String currencySymbol;

  const SpendingChart({
    super.key,
    required this.spendingData,
    required this.totalSpending,
    this.currencySymbol = '\$',
  });

  @override
  State<SpendingChart> createState() => _SpendingChartState();
}

class _SpendingChartState extends State<SpendingChart> {
  int touchedIndex = -1;

  String _formatCompact(double amount) {
    if (amount >= 1000000) {
      return '${widget.currencySymbol}${(amount / 1000000).toStringAsFixed(1)}M';
    }
    if (amount >= 1000) {
      return '${widget.currencySymbol}${(amount / 1000).toStringAsFixed(1)}K';
    }
    final formatter = NumberFormat('#,##0', 'en_US');
    return '${widget.currencySymbol}${formatter.format(amount)}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return FadeInUp(
      duration: const Duration(milliseconds: 600),
      delay: const Duration(milliseconds: 500),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Spending by Category',
            style: GoogleFonts.inter(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF1a1a2e),
            ),
          ),
          const SizedBox(height: 20),
          if (widget.spendingData.isEmpty)
            _buildEmptyState(isDark)
          else
            _buildChart(isDark),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.04)
            : Colors.grey.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.grey.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.pie_chart_outline_rounded,
            size: 48,
            color: isDark
                ? Colors.white.withValues(alpha: 0.2)
                : Colors.black.withValues(alpha: 0.2),
          ),
          const SizedBox(height: 12),
          Text(
            'No spending data',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.4)
                  : Colors.black.withValues(alpha: 0.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChart(bool isDark) {
    final topData = widget.spendingData.take(5).toList();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.04)
            : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.grey.withValues(alpha: 0.1),
        ),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Column(
        children: [
          SizedBox(
            height: 200,
            child: Stack(
              alignment: Alignment.center,
              children: [
                PieChart(
                  PieChartData(
                    pieTouchData: PieTouchData(
                      touchCallback: (FlTouchEvent event, pieTouchResponse) {
                        setState(() {
                          if (!event.isInterestedForInteractions ||
                              pieTouchResponse == null ||
                              pieTouchResponse.touchedSection == null) {
                            touchedIndex = -1;
                            return;
                          }
                          touchedIndex = pieTouchResponse
                              .touchedSection!.touchedSectionIndex;
                        });
                      },
                    ),
                    borderData: FlBorderData(show: false),
                    sectionsSpace: 3,
                    centerSpaceRadius: 55,
                    sections: _buildSections(topData),
                    startDegreeOffset: -90,
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Total',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.5)
                            : Colors.black.withValues(alpha: 0.5),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatCompact(widget.totalSpending),
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : const Color(0xFF1a1a2e),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          ...topData.asMap().entries.map((entry) {
            final index = entry.key;
            final data = entry.value;
            final percentage = widget.totalSpending > 0
                ? (data.amount / widget.totalSpending * 100)
                : 0.0;

            return FadeInLeft(
              duration: const Duration(milliseconds: 400),
              delay: Duration(milliseconds: 80 * index),
              child: Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: data.color,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        data.categoryName,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.75)
                              : Colors.black.withValues(alpha: 0.7),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      _formatCompact(data.amount),
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.85)
                            : Colors.black.withValues(alpha: 0.8),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: data.color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${percentage.toStringAsFixed(1)}%',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: data.color,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  List<PieChartSectionData> _buildSections(List<SpendingChartData> topData) {
    return topData.asMap().entries.map((entry) {
      final index = entry.key;
      final data = entry.value;
      final isTouched = index == touchedIndex;
      final fontSize = isTouched ? 14.0 : 0.0;
      final radius = isTouched ? 35.0 : 28.0;

      return PieChartSectionData(
        color: data.color,
        value: data.amount,
        title: isTouched
            ? '${(data.amount / widget.totalSpending * 100).toStringAsFixed(0)}%'
            : '',
        radius: radius,
        titleStyle: GoogleFonts.inter(
          fontSize: fontSize,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
        titlePositionPercentageOffset: 0.55,
        badgePositionPercentageOffset: 0.98,
      );
    }).toList();
  }
}
