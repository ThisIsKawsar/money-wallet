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

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});
  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  String _chartType = 'expense_overview';
  late DateTime _anchor;

  final _chartTypes = [
    {'key': 'expense_overview', 'label': 'Expense overview'},
    {'key': 'income_overview', 'label': 'Income overview'},
    {'key': 'expense_flow', 'label': 'Expense flow'},
    {'key': 'income_flow', 'label': 'Income flow'},
    {'key': 'monthly_comparison', 'label': 'Monthly comparison'},
    {'key': 'category_trend', 'label': 'Category trend'},
  ];

  @override
  void initState() {
    super.initState();
    _resetAnchor();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TransactionProvider>().loadTransactions();
      context.read<CategoryProvider>().loadCategories();
    });
  }

  void _resetAnchor() {
    final now = DateTime.now();
    final settings = context.read<SettingsProvider>();
    switch (settings.filterPeriod) {
      case 'daily':
        _anchor = DateTime(now.year, now.month, now.day);
      case 'weekly':
        final w = now.subtract(Duration(days: now.weekday - 1));
        _anchor = DateTime(w.year, w.month, w.day);
      case 'yearly':
        _anchor = DateTime(now.year, 1, 1);
      default:
        _anchor = DateTime(now.year, now.month, 1);
    }
  }

  DateTimeRange _range() {
    final settings = context.read<SettingsProvider>();
    switch (settings.filterPeriod) {
      case 'daily':
        return DateTimeRange(
            start: _anchor, end: _anchor.add(const Duration(days: 1)));
      case 'weekly':
        return DateTimeRange(
            start: _anchor, end: _anchor.add(const Duration(days: 7)));
      case 'yearly':
        return DateTimeRange(
            start: _anchor, end: DateTime(_anchor.year + 1, 1, 1));
      default:
        return DateTimeRange(
            start: _anchor,
            end: DateTime(_anchor.year, _anchor.month + 1, 1));
    }
  }

  String _rangeLabel() {
    final settings = context.read<SettingsProvider>();
    switch (settings.filterPeriod) {
      case 'daily':
        return DateFormat('MMM d, EEEE').format(_anchor);
      case 'weekly':
        final end = _anchor.add(const Duration(days: 6));
        return '${DateFormat('MMM d').format(_anchor)} - ${DateFormat('MMM d').format(end)}';
      case 'yearly':
        return _anchor.year.toString();
      default:
        return DateFormat('MMMM, yyyy').format(_anchor);
    }
  }

  void _prev() => setState(() {
        final settings = context.read<SettingsProvider>();
        switch (settings.filterPeriod) {
          case 'daily':
            _anchor = _anchor.subtract(const Duration(days: 1));
          case 'weekly':
            _anchor = _anchor.subtract(const Duration(days: 7));
          case 'yearly':
            _anchor = DateTime(_anchor.year - 1, 1, 1);
          default:
            _anchor = DateTime(_anchor.year, _anchor.month - 1, 1);
        }
      });

  void _next() => setState(() {
        final settings = context.read<SettingsProvider>();
        switch (settings.filterPeriod) {
          case 'daily':
            _anchor = _anchor.add(const Duration(days: 1));
          case 'weekly':
            _anchor = _anchor.add(const Duration(days: 7));
          case 'yearly':
            _anchor = DateTime(_anchor.year + 1, 1, 1);
          default:
            _anchor = DateTime(_anchor.year, _anchor.month + 1, 1);
        }
      });

  List<TransactionModel> _txForRange(List<TransactionModel> all) {
    final r = _range();
    return all
        .where((t) => !t.date.isBefore(r.start) && t.date.isBefore(r.end))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final txProvider = context.watch<TransactionProvider>();
    final catProvider = context.watch<CategoryProvider>();
    final settings = context.watch<SettingsProvider>();

    final periodTxs = _txForRange(txProvider.transactions);
    final income = periodTxs
        .where((t) => t.type == TransactionType.income)
        .fold(0.0, (s, t) => s + t.amount);
    final expense = periodTxs
        .where((t) => t.type == TransactionType.expense)
        .fold(0.0, (s, t) => s + t.amount);
    final net = income - expense;
    final fmt = NumberFormat('#,##0.00');

    return Scaffold(
      body: Column(
        children: [
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                // Period nav
                _PeriodNavBar(
                  label: _rangeLabel(),
                  isDark: isDark,
                  onPrev: _prev,
                  onNext: _next,
                  onFilter: () => _showPeriodPicker(context),
                ),
                // Summary
                Container(
                  color: isDark ? AppColors.darkBg : AppColors.lightBg,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(
                    children: [
                      _sumCol('EXPENSE', '$symbol${fmt.format(expense)}',
                          AppColors.expense, isDark, settings.currencySymbol),
                      _sumCol('INCOME', '$symbol${fmt.format(income)}',
                          AppColors.income, isDark, settings.currencySymbol),
                      _sumCol(
                          'TOTAL',
                          '${net < 0 ? '-' : ''}$symbol${fmt.format(net.abs())}',
                          net >= 0 ? AppColors.income : AppColors.expense,
                          isDark,
                          settings.currencySymbol),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(0, 0, 0, 100),
              children: [
                // Chart type selector
                _ChartTypeSelector(
                  selected: _chartType,
                  types: _chartTypes,
                  isDark: isDark,
                  onSelect: (k) => setState(() => _chartType = k),
                ),
                const SizedBox(height: 4),
                // Chart content
                _buildChartContent(
                    context, periodTxs, catProvider, settings, isDark),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String get symbol => '';

  Widget _sumCol(String label, String value, Color color, bool isDark,
          String sym) =>
      Expanded(
        child: Column(
          children: [
            Text(label,
                style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.5)
                        : Colors.black.withValues(alpha: 0.5))),
            const SizedBox(height: 4),
            Text(value.replaceAll('\$', sym),
                style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: color),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ],
        ),
      );

  Widget _buildChartContent(
      BuildContext context,
      List<TransactionModel> txs,
      dynamic catProvider,
      SettingsProvider settings,
      bool isDark) {
    switch (_chartType) {
      case 'expense_overview':
        return _OverviewSection(
          txs: txs.where((t) => t.type == TransactionType.expense).toList(),
          catProvider: catProvider,
          symbol: settings.currencySymbol,
          isDark: isDark,
          title: 'EXPENSE OVERVIEW',
          color: AppColors.expense,
        );
      case 'income_overview':
        return _OverviewSection(
          txs: txs.where((t) => t.type == TransactionType.income).toList(),
          catProvider: catProvider,
          symbol: settings.currencySymbol,
          isDark: isDark,
          title: 'INCOME OVERVIEW',
          color: AppColors.income,
        );
      case 'expense_flow':
        return _FlowSection(
          allTxs: context.read<TransactionProvider>().transactions,
          type: TransactionType.expense,
          period: settings.filterPeriod,
          anchor: _anchor,
          symbol: settings.currencySymbol,
          isDark: isDark,
          color: AppColors.expense,
          title: 'EXPENSE FLOW',
        );
      case 'income_flow':
        return _FlowSection(
          allTxs: context.read<TransactionProvider>().transactions,
          type: TransactionType.income,
          period: settings.filterPeriod,
          anchor: _anchor,
          symbol: settings.currencySymbol,
          isDark: isDark,
          color: AppColors.income,
          title: 'INCOME FLOW',
        );
      case 'monthly_comparison':
        return _MonthlyComparisonSection(
          allTxs: context.read<TransactionProvider>().transactions,
          symbol: settings.currencySymbol,
          isDark: isDark,
        );
      case 'category_trend':
        return _CategoryTrendSection(
          allTxs: context.read<TransactionProvider>().transactions,
          catProvider: catProvider,
          symbol: settings.currencySymbol,
          isDark: isDark,
        );
      default:
        return const SizedBox.shrink();
    }
  }

  void _showPeriodPicker(BuildContext context) {
    final settings = context.read<SettingsProvider>();
    final opts = [
      {'key': 'daily', 'label': 'DAILY'},
      {'key': 'weekly', 'label': 'WEEKLY'},
      {'key': 'monthly', 'label': 'MONTHLY'},
      {'key': 'yearly', 'label': 'YEARLY'},
    ];
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('View mode',
            style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: opts.map((o) {
            final isSel = settings.filterPeriod == o['key'];
            return ListTile(
              dense: true,
              leading: isSel
                  ? const Icon(Icons.check, color: AppColors.primary)
                  : const SizedBox(width: 24),
              title: Text(o['label']!,
                  style: GoogleFonts.inter(
                      fontWeight:
                          isSel ? FontWeight.w700 : FontWeight.w500,
                      color: isSel ? AppColors.primary : null)),
              onTap: () {
                settings.setFilterPeriod(o['key']!);
                _resetAnchor();
                Navigator.pop(ctx);
              },
            );
          }).toList(),
        ),
      ),
    );
  }
}

// ── Chart type selector ──────────────────────────────────────────────────────

class _ChartTypeSelector extends StatelessWidget {
  final String selected;
  final List<Map<String, String>> types;
  final bool isDark;
  final void Function(String) onSelect;

  const _ChartTypeSelector(
      {required this.selected,
      required this.types,
      required this.isDark,
      required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final current =
        types.firstWhere((t) => t['key'] == selected, orElse: () => types[0]);
    return GestureDetector(
      onTap: () => _showMenu(context),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.keyboard_arrow_down_rounded,
                color: AppColors.primary, size: 20),
            const SizedBox(width: 8),
            Text(
              current['label']!.toUpperCase(),
              style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                  letterSpacing: 0.5),
            ),
          ],
        ),
      ),
    );
  }

  void _showMenu(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: types.map((t) {
            final isSel = selected == t['key'];
            return ListTile(
              title: Text(t['label']!,
                  style: GoogleFonts.inter(
                      fontWeight:
                          isSel ? FontWeight.w700 : FontWeight.w400,
                      color: isSel ? AppColors.primary : null)),
              onTap: () {
                onSelect(t['key']!);
                Navigator.pop(ctx);
              },
            );
          }).toList(),
        ),
      ),
    );
  }
}

// ── Overview (donut + category list) ────────────────────────────────────────

class _OverviewSection extends StatefulWidget {
  final List<TransactionModel> txs;
  final dynamic catProvider;
  final String symbol;
  final bool isDark;
  final String title;
  final Color color;

  const _OverviewSection(
      {required this.txs,
      required this.catProvider,
      required this.symbol,
      required this.isDark,
      required this.title,
      required this.color});

  @override
  State<_OverviewSection> createState() => _OverviewSectionState();
}

class _OverviewSectionState extends State<_OverviewSection> {
  int _touched = -1;

  // Build a stable color list long enough for all categories
  static const _palette = [
    Color(0xFFe74c3c), Color(0xFFf1c40f), Color(0xFF9b59b6),
    Color(0xFF27ae60), Color(0xFFe91e63), Color(0xFF1abc9c),
    Color(0xFF3498db), Color(0xFFff9800), Color(0xFF795548),
    Color(0xFF607d8b), Color(0xFF2ecc71), Color(0xFFe67e22),
    Color(0xFF8e44ad), Color(0xFF16a085), Color(0xFFc0392b),
    Color(0xFF2980b9), Color(0xFFd35400), Color(0xFF27ae60),
  ];

  @override
  Widget build(BuildContext context) {
    if (widget.txs.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(40),
        child: Center(
          child: Text('No data for this period',
              style: GoogleFonts.inter(
                  color: widget.isDark
                      ? Colors.white.withValues(alpha: 0.4)
                      : Colors.black.withValues(alpha: 0.4))),
        ),
      );
    }

    // Aggregate by category
    final Map<String, double> byCategory = {};
    for (final tx in widget.txs) {
      byCategory[tx.categoryId] =
          (byCategory[tx.categoryId] ?? 0) + tx.amount;
    }
    final entries = byCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final total = entries.fold(0.0, (s, e) => s + e.value);
    final fmt = NumberFormat('#,##0.00');

    return Column(
      children: [
        // Donut + legend row
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Donut
              SizedBox(
                width: 180,
                height: 180,
                child: PieChart(
                  PieChartData(
                    pieTouchData: PieTouchData(
                      touchCallback: (event, resp) {
                        setState(() {
                          _touched =
                              (!event.isInterestedForInteractions ||
                                      resp?.touchedSection == null)
                                  ? -1
                                  : resp!.touchedSection!
                                      .touchedSectionIndex;
                        });
                      },
                    ),
                    sections: entries.asMap().entries.map((e) {
                      final isTouched = e.key == _touched;
                      return PieChartSectionData(
                        color: _palette[e.key % _palette.length],
                        value: e.value.value,
                        radius: isTouched ? 36 : 28,
                        title: isTouched
                            ? '${(e.value.value / total * 100).toStringAsFixed(1)}%'
                            : '',
                        titleStyle: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.white),
                      );
                    }).toList(),
                    centerSpaceRadius: 52,
                    sectionsSpace: 2,
                    borderData: FlBorderData(show: false),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Legend
              Expanded(
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: entries.asMap().entries.map((e) {
                    final cat =
                        widget.catProvider.getCategoryById(e.value.key);
                    final color = _palette[e.key % _palette.length];
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                                color: color,
                                borderRadius: BorderRadius.circular(2))),
                        const SizedBox(width: 4),
                        Text(cat?.name ?? 'Unknown',
                            style: GoogleFonts.inter(
                                fontSize: 11,
                                color: widget.isDark
                                    ? Colors.white.withValues(alpha: 0.8)
                                    : Colors.black.withValues(alpha: 0.8))),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Category breakdown list
        ...entries.asMap().entries.map((e) {
          final cat = widget.catProvider.getCategoryById(e.value.key);
          final pct = total > 0 ? e.value.value / total : 0.0;
          final color = _palette[e.key % _palette.length];
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                    color: widget.isDark
                        ? AppColors.darkBorder
                        : AppColors.lightBorder),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      (cat?.name ?? '?').substring(0, 1).toUpperCase(),
                      style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: color),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(cat?.name ?? 'Unknown',
                          style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: widget.isDark
                                  ? Colors.white
                                  : const Color(0xFF1a1a2e))),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: LinearProgressIndicator(
                          value: pct,
                          backgroundColor: color.withValues(alpha: 0.12),
                          valueColor: AlwaysStoppedAnimation(color),
                          minHeight: 5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '-${widget.symbol}${fmt.format(e.value.value)}',
                      style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: widget.color),
                    ),
                    Text(
                      '${(pct * 100).toStringAsFixed(2)}%',
                      style: GoogleFonts.inter(
                          fontSize: 11,
                          color: widget.isDark
                              ? Colors.white.withValues(alpha: 0.5)
                              : Colors.black.withValues(alpha: 0.5)),
                    ),
                  ],
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

// ── Flow chart (bar chart over sub-periods) ──────────────────────────────────

class _FlowSection extends StatelessWidget {
  final List<TransactionModel> allTxs;
  final TransactionType type;
  final String period;
  final DateTime anchor;
  final String symbol;
  final bool isDark;
  final Color color;
  final String title;

  const _FlowSection(
      {required this.allTxs,
      required this.type,
      required this.period,
      required this.anchor,
      required this.symbol,
      required this.isDark,
      required this.color,
      required this.title});

  List<Map<String, dynamic>> _buildBuckets() {
    final buckets = <Map<String, dynamic>>[];
    switch (period) {
      case 'daily':
        // Hourly buckets for the day
        for (int h = 0; h < 24; h += 4) {
          final start =
              DateTime(anchor.year, anchor.month, anchor.day, h);
          final end = start.add(const Duration(hours: 4));
          final sum = allTxs
              .where((t) =>
                  t.type == type &&
                  !t.date.isBefore(start) &&
                  t.date.isBefore(end))
              .fold(0.0, (s, t) => s + t.amount);
          buckets.add({'label': '${h}h', 'value': sum});
        }
      case 'weekly':
        for (int d = 0; d < 7; d++) {
          final start =
              DateTime(anchor.year, anchor.month, anchor.day + d);
          final end = start.add(const Duration(days: 1));
          final sum = allTxs
              .where((t) =>
                  t.type == type &&
                  !t.date.isBefore(start) &&
                  t.date.isBefore(end))
              .fold(0.0, (s, t) => s + t.amount);
          buckets.add(
              {'label': DateFormat('EEE').format(start), 'value': sum});
        }
      case 'yearly':
        for (int m = 1; m <= 12; m++) {
          final start = DateTime(anchor.year, m, 1);
          final end = DateTime(anchor.year, m + 1, 1);
          final sum = allTxs
              .where((t) =>
                  t.type == type &&
                  !t.date.isBefore(start) &&
                  t.date.isBefore(end))
              .fold(0.0, (s, t) => s + t.amount);
          buckets.add(
              {'label': DateFormat('MMM').format(start), 'value': sum});
        }
      default: // monthly — daily buckets
        final daysInMonth =
            DateTime(anchor.year, anchor.month + 1, 0).day;
        for (int d = 1; d <= daysInMonth; d++) {
          final start =
              DateTime(anchor.year, anchor.month, d);
          final end = start.add(const Duration(days: 1));
          final sum = allTxs
              .where((t) =>
                  t.type == type &&
                  !t.date.isBefore(start) &&
                  t.date.isBefore(end))
              .fold(0.0, (s, t) => s + t.amount);
          buckets
              .add({'label': d.toString(), 'value': sum});
        }
    }
    return buckets;
  }

  @override
  Widget build(BuildContext context) {
    final buckets = _buildBuckets();
    final maxY = buckets
        .map((b) => b['value'] as double)
        .fold(0.0, (a, b) => a > b ? a : b);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Container(
        height: 260,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.04)
              : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : Colors.grey.withValues(alpha: 0.1)),
        ),
        child: BarChart(
          BarChartData(
            maxY: maxY > 0 ? maxY * 1.2 : 10,
            barGroups: buckets.asMap().entries.map((e) {
              return BarChartGroupData(
                x: e.key,
                barRods: [
                  BarChartRodData(
                    toY: e.value['value'] as double,
                    color: color,
                    width: period == 'monthly' ? 6 : 14,
                    borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(4)),
                  ),
                ],
              );
            }).toList(),
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              getDrawingHorizontalLine: (v) => FlLine(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.black.withValues(alpha: 0.05),
                  strokeWidth: 1),
            ),
            borderData: FlBorderData(show: false),
            titlesData: FlTitlesData(
              leftTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false)),
              topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false)),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  interval: period == 'monthly' ? 5 : 1,
                  getTitlesWidget: (v, meta) {
                    final idx = v.toInt();
                    if (idx < 0 || idx >= buckets.length) {
                      return const SizedBox.shrink();
                    }
                    return Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(buckets[idx]['label'] as String,
                          style: GoogleFonts.inter(
                              fontSize: 9,
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.5)
                                  : Colors.black.withValues(alpha: 0.5))),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Monthly comparison (income vs expense over months) ───────────────────────

class _MonthlyComparisonSection extends StatelessWidget {
  final List<TransactionModel> allTxs;
  final String symbol;
  final bool isDark;

  const _MonthlyComparisonSection({
    required this.allTxs,
    required this.symbol,
    required this.isDark,
  });

  List<Map<String, dynamic>> _buildMonthlyData() {
    final now = DateTime.now();
    final data = <Map<String, dynamic>>[];
    
    for (int i = 5; i >= 0; i--) {
      final month = DateTime(now.year, now.month - i, 1);
      final nextMonth = DateTime(now.year, now.month - i + 1, 1);
      
      final income = allTxs
          .where((t) => t.type == TransactionType.income &&
              !t.date.isBefore(month) && t.date.isBefore(nextMonth))
          .fold(0.0, (s, t) => s + t.amount);
      
      final expense = allTxs
          .where((t) => t.type == TransactionType.expense &&
              !t.date.isBefore(month) && t.date.isBefore(nextMonth))
          .fold(0.0, (s, t) => s + t.amount);
      
      data.add({
        'label': DateFormat('MMM').format(month),
        'income': income,
        'expense': expense,
      });
    }
    
    return data;
  }

  @override
  Widget build(BuildContext context) {
    final data = _buildMonthlyData();
    final maxY = data.fold<double>(
      0,
      (max, item) => [
        item['income'] as double,
        item['expense'] as double,
        max,
      ].reduce((a, b) => a > b ? a : b),
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Container(
        height: 280,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.04)
              : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : Colors.grey.withValues(alpha: 0.1)),
        ),
        child: BarChart(
          BarChartData(
            maxY: maxY > 0 ? maxY * 1.2 : 10,
            barGroups: data.asMap().entries.map((e) {
              return BarChartGroupData(
                x: e.key,
                barRods: [
                  BarChartRodData(
                    toY: e.value['income'] as double,
                    color: AppColors.income,
                    width: 12,
                    borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(4)),
                  ),
                  BarChartRodData(
                    toY: e.value['expense'] as double,
                    color: AppColors.expense,
                    width: 12,
                    borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(4)),
                  ),
                ],
              );
            }).toList(),
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              getDrawingHorizontalLine: (v) => FlLine(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.black.withValues(alpha: 0.05),
                  strokeWidth: 1),
            ),
            borderData: FlBorderData(show: false),
            titlesData: FlTitlesData(
              leftTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false)),
              topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false)),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (v, meta) {
                    final idx = v.toInt();
                    if (idx < 0 || idx >= data.length) {
                      return const SizedBox.shrink();
                    }
                    return Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(data[idx]['label'] as String,
                          style: GoogleFonts.inter(
                              fontSize: 10,
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.5)
                                  : Colors.black.withValues(alpha: 0.5))),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Category trend (line chart over time) ─────────────────────────────────────

class _CategoryTrendSection extends StatelessWidget {
  final List<TransactionModel> allTxs;
  final dynamic catProvider;
  final String symbol;
  final bool isDark;

  const _CategoryTrendSection({
    required this.allTxs,
    required this.catProvider,
    required this.symbol,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final categoryTotals = <String, double>{};
    for (final tx in allTxs) {
      if (tx.type == TransactionType.expense) {
        categoryTotals[tx.categoryId] =
            (categoryTotals[tx.categoryId] ?? 0) + tx.amount;
      }
    }
    
    final topCategories = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    if (topCategories.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(40),
        child: Center(
          child: Text('No expense data available',
              style: GoogleFonts.inter(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.4)
                      : Colors.black.withValues(alpha: 0.4))),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Top Spending Categories',
              style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF1a1a2e))),
          const SizedBox(height: 12),
          ...topCategories.take(5).map((e) {
            final cat = catProvider.getCategoryById(e.key);
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.expense.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        (cat?.name ?? '?').substring(0, 1).toUpperCase(),
                        style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.expense),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(cat?.name ?? 'Unknown',
                            style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF1a1a2e))),
                        const SizedBox(height: 2),
                        Text('$symbol${e.value.toStringAsFixed(2)}',
                            style: GoogleFonts.inter(
                                fontSize: 12,
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.5)
                                    : Colors.black.withValues(alpha: 0.5))),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ── Shared nav bar ───────────────────────────────────────────────────────────

class _PeriodNavBar extends StatelessWidget {
  final String label;
  final bool isDark;
  final VoidCallback onPrev, onNext, onFilter;

  const _PeriodNavBar(
      {required this.label,
      required this.isDark,
      required this.onPrev,
      required this.onNext,
      required this.onFilter});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
      color: isDark ? AppColors.darkBg : AppColors.lightBg,
      child: Row(
        children: [
          IconButton(
              icon: const Icon(Icons.chevron_left_rounded),
              onPressed: onPrev,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints()),
          Expanded(
            child: Text(label,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color:
                        isDark ? Colors.white : const Color(0xFF1a1a2e))),
          ),
          IconButton(
              icon: const Icon(Icons.chevron_right_rounded),
              onPressed: onNext,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints()),
          IconButton(
              icon: const Icon(Icons.tune_rounded),
              onPressed: onFilter,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              iconSize: 20),
          const SizedBox(width: 8),
        ],
      ),
    );
  }
}
