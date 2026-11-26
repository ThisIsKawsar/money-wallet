import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:cashpilot/providers/transaction_provider.dart';
import 'package:cashpilot/providers/category_provider.dart';
import 'package:cashpilot/providers/settings_provider.dart';
import 'package:cashpilot/data/models/transaction_model.dart';
import 'package:cashpilot/core/theme/app_colors.dart';
import 'package:cashpilot/core/constants/app_icons.dart';
import 'package:cashpilot/widgets/wavy_background.dart';
import 'package:cashpilot/widgets/period_bar.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  late DateTime _anchor;
  String? _lastMode;
  String _chartMode = 'EXPENSE OVERVIEW';

  static const _modes = [
    'EXPENSE OVERVIEW',
    'INCOME OVERVIEW',
    'EXPENSE FLOW',
    'INCOME FLOW',
  ];

  @override
  void initState() {
    super.initState();
    final mode = context.read<SettingsProvider>().filterPeriod;
    _lastMode = mode;
    _anchor = PeriodHelpers.defaultAnchor(mode);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TransactionProvider>().loadTransactions();
      context.read<CategoryProvider>().loadCategories();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final txProvider = context.watch<TransactionProvider>();
    final catProvider = context.watch<CategoryProvider>();
    final settings = context.watch<SettingsProvider>();

    if (_lastMode != settings.filterPeriod) {
      _lastMode = settings.filterPeriod;
      _anchor = PeriodHelpers.defaultAnchor(settings.filterPeriod);
    }

    final range = PeriodHelpers.range(_anchor, settings.filterPeriod);
    final txs = txProvider.transactions
        .where((t) => !t.date.isBefore(range.start) && t.date.isBefore(range.end))
        .toList();

    final totalIncome = txs
        .where((t) => t.type == TransactionType.income)
        .fold(0.0, (s, t) => s + t.amount);
    final totalExpense = txs
        .where((t) => t.type == TransactionType.expense)
        .fold(0.0, (s, t) => s + t.amount);

    final isIncomeMode = _chartMode.startsWith('INCOME');
    final isFlowMode = _chartMode.endsWith('FLOW');
    final targetType =
        isIncomeMode ? TransactionType.income : TransactionType.expense;
    final modeTotal = isIncomeMode ? totalIncome : totalExpense;

    final Map<String, double> catMap = {};
    for (final t in txs.where((t) => t.type == targetType)) {
      catMap[t.categoryId] = (catMap[t.categoryId] ?? 0) + t.amount;
    }
    final catEntries = catMap.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final weekTotals = List<double>.filled(4, 0);
    for (final t in txs.where((t) => t.type == targetType)) {
      final w = ((t.date.day - 1) ~/ 7).clamp(0, 3);
      weekTotals[w] += t.amount;
    }

    final fmt = NumberFormat('#,##0.00', 'en_US');

    return WavyBackground(
      child: Column(
        children: [
          PeriodSummaryBar(
            anchor: _anchor,
            onPrev: () => setState(
                () => _anchor = PeriodHelpers.prev(_anchor, settings.filterPeriod)),
            onNext: () => setState(
                () => _anchor = PeriodHelpers.next(_anchor, settings.filterPeriod)),
            expense: totalExpense,
            income: totalIncome,
            total: totalIncome - totalExpense,
            currencySymbol: settings.currencySymbol,
            onPeriodModeChanged: () => setState(() {
              _anchor = PeriodHelpers.defaultAnchor(settings.filterPeriod);
            }),
          ),
          Expanded(
            child: ListView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 100),
              children: [
                // Chart Type Dropdown Pill
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkCard : AppColors.mintSoft,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.25),
                      ),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _chartMode,
                        icon: Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: AppColors.primary,
                        ),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                          letterSpacing: 0.4,
                        ),
                        items: _modes
                            .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                            .toList(),
                        onChanged: (v) {
                          if (v != null) setState(() => _chartMode = v);
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Chart Card
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkCard : AppColors.lightSurface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    ),
                  ),
                  child: isFlowMode
                      ? SizedBox(
                          height: 190,
                          child: BarChart(
                            BarChartData(
                              gridData: FlGridData(
                                show: true,
                                drawVerticalLine: false,
                                getDrawingHorizontalLine: (_) => FlLine(
                                  color: isDark
                                      ? AppColors.darkBorder
                                      : AppColors.lightBorder,
                                  strokeWidth: 1,
                                ),
                              ),
                              borderData: FlBorderData(show: false),
                              titlesData: FlTitlesData(
                                topTitles: const AxisTitles(
                                    sideTitles: SideTitles(showTitles: false)),
                                rightTitles: const AxisTitles(
                                    sideTitles: SideTitles(showTitles: false)),
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    getTitlesWidget: (v, _) => Padding(
                                      padding: const EdgeInsets.only(top: 6),
                                      child: Text(
                                        'W${v.toInt() + 1}',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              barGroups: List.generate(4, (i) {
                                return BarChartGroupData(
                                  x: i,
                                  barRods: [
                                    BarChartRodData(
                                      toY: weekTotals[i],
                                      color: isIncomeMode
                                          ? AppColors.income
                                          : AppColors.expense,
                                      width: 22,
                                      borderRadius: const BorderRadius.vertical(
                                        top: Radius.circular(8),
                                      ),
                                    ),
                                  ],
                                );
                              }),
                            ),
                          ),
                        )
                      : catEntries.isEmpty
                          ? Padding(
                              padding: const EdgeInsets.symmetric(vertical: 36),
                              child: Center(
                                child: Text(
                                  'No ${isIncomeMode ? 'income' : 'expense'} data in this period',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13,
                                    color: AppColors.lightTextSecondary,
                                  ),
                                ),
                              ),
                            )
                          : Row(
                              children: [
                                SizedBox(
                                  width: 145,
                                  height: 145,
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      PieChart(
                                        PieChartData(
                                          centerSpaceRadius: 42,
                                          sectionsSpace: 2,
                                          sections: catEntries.map((e) {
                                            final cat = catProvider
                                                .getCategoryById(e.key);
                                            final color = cat != null
                                                ? AppColors.fromHex(cat.color)
                                                : AppColors.primary;
                                            return PieChartSectionData(
                                              value: e.value,
                                              color: color,
                                              radius: 26,
                                              showTitle: false,
                                            );
                                          }).toList(),
                                        ),
                                      ),
                                      Text(
                                        isIncomeMode ? 'Income' : 'Expenses',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: isDark
                                              ? Colors.white
                                              : AppColors.lightTextPrimary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: catEntries.take(8).map((e) {
                                      final cat =
                                          catProvider.getCategoryById(e.key);
                                      final color = cat != null
                                          ? AppColors.fromHex(cat.color)
                                          : AppColors.primary;
                                      return Padding(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 3),
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 9,
                                              height: 9,
                                              decoration: BoxDecoration(
                                                color: color,
                                                borderRadius:
                                                    BorderRadius.circular(2),
                                              ),
                                            ),
                                            const SizedBox(width: 7),
                                            Expanded(
                                              child: Text(
                                                cat?.name ?? 'Others',
                                                style:
                                                    GoogleFonts.plusJakartaSans(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w500,
                                                  color: isDark
                                                      ? Colors.white
                                                      : AppColors.lightTextPrimary,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ],
                            ),
                ),
                const SizedBox(height: 16),

                // Category Breakdown Rows with Progress Bars & Percentages
                ...catEntries.map((e) {
                  final cat = catProvider.getCategoryById(e.key);
                  final color = cat != null
                      ? AppColors.fromHex(cat.color)
                      : AppColors.primary;
                  final ratio = modeTotal > 0 ? (e.value / modeTotal) : 0.0;
                  final pct = (ratio * 100).toStringAsFixed(2);

                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkCard : AppColors.lightSurface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color:
                            isDark ? AppColors.darkBorder : AppColors.lightBorder,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.14),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            cat != null
                                ? AppIcons.fromName(cat.icon)
                                : Icons.category_rounded,
                            color: color,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    cat?.name ?? 'Others',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: isDark
                                          ? Colors.white
                                          : AppColors.lightTextPrimary,
                                    ),
                                  ),
                                  Text(
                                    '${isIncomeMode ? '+' : '-'}${settings.currencySymbol}${fmt.format(e.value)}',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: isIncomeMode
                                          ? AppColors.income
                                          : AppColors.expense,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: LinearProgressIndicator(
                                  value: ratio.clamp(0.0, 1.0),
                                  minHeight: 7,
                                  backgroundColor: isDark
                                      ? AppColors.darkCardAlt
                                      : const Color(0xFFE9EFEA),
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    isIncomeMode
                                        ? AppColors.income
                                        : AppColors.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '$pct%',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? Colors.white
                                : AppColors.lightTextPrimary,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
