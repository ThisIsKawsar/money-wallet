import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:cashpilot/providers/transaction_provider.dart';
import 'package:cashpilot/providers/account_provider.dart';
import 'package:cashpilot/providers/category_provider.dart';
import 'package:cashpilot/providers/settings_provider.dart';
import 'package:cashpilot/providers/goal_provider.dart';
import 'package:cashpilot/data/models/transaction_model.dart';
import 'package:cashpilot/core/theme/app_colors.dart';
import 'package:cashpilot/widgets/wavy_background.dart';
import 'package:cashpilot/widgets/period_bar.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  Future<void> _loadData() async {
    await Future.wait([
      context.read<TransactionProvider>().loadTransactions(),
      context.read<AccountProvider>().loadAccounts(),
      context.read<CategoryProvider>().loadCategories(),
      context.read<GoalProvider>().loadGoals(),
    ]);
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning!';
    if (h < 17) return 'Good afternoon!';
    return 'Good evening!';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final settings = context.watch<SettingsProvider>();
    final txProvider = context.watch<TransactionProvider>();
    final accProvider = context.watch<AccountProvider>();

    final mode = settings.filterPeriod;
    final anchor = PeriodHelpers.defaultAnchor(mode);
    final range = PeriodHelpers.range(anchor, mode);

    final rangeTxs = txProvider.transactions
        .where((t) => !t.date.isBefore(range.start) && t.date.isBefore(range.end))
        .toList();

    final totalIncome = rangeTxs
        .where((t) => t.type == TransactionType.income)
        .fold(0.0, (s, t) => s + t.amount);
    final totalExpense = rangeTxs
        .where((t) => t.type == TransactionType.expense)
        .fold(0.0, (s, t) => s + t.amount);
    final periodBalance = totalIncome - totalExpense;
    final periodLabel = PeriodHelpers.label(anchor, mode);

    // Same totals for the previous period, for the trend badges.
    final prevRange = PeriodHelpers.range(PeriodHelpers.prev(anchor, mode), mode);
    double prevSum(TransactionType type) => txProvider.transactions
        .where((t) =>
            t.type == type &&
            !t.date.isBefore(prevRange.start) &&
            t.date.isBefore(prevRange.end))
        .fold(0.0, (s, t) => s + t.amount);
    final incomeTrend = _Trend.of(totalIncome, prevSum(TransactionType.income));
    final expenseTrend = _Trend.of(totalExpense, prevSum(TransactionType.expense));

    // Build chart buckets based on View mode from Display options
    final List<String> bucketLabels = [];
    final List<double> bucketIncome = [];
    final List<double> bucketExpense = [];

    if (mode == 'daily') {
      bucketLabels.add(DateFormat('EEE').format(anchor));
      bucketIncome.add(totalIncome);
      bucketExpense.add(totalExpense);
    } else if (mode == 'weekly') {
      for (int i = 0; i < 7; i++) {
        final d = anchor.add(Duration(days: i));
        bucketLabels.add(DateFormat('E').format(d).substring(0, 2));
        final dTxs = rangeTxs.where((t) =>
            t.date.year == d.year && t.date.month == d.month && t.date.day == d.day);
        bucketIncome.add(dTxs
            .where((t) => t.type == TransactionType.income)
            .fold(0.0, (s, t) => s + t.amount));
        bucketExpense.add(dTxs
            .where((t) => t.type == TransactionType.expense)
            .fold(0.0, (s, t) => s + t.amount));
      }
    } else if (mode == '3months') {
      for (int i = 0; i < 3; i++) {
        final m = DateTime(anchor.year, anchor.month + i, 1);
        bucketLabels.add(DateFormat('MMM').format(m));
        final mTxs = rangeTxs.where(
            (t) => t.date.year == m.year && t.date.month == m.month);
        bucketIncome.add(mTxs
            .where((t) => t.type == TransactionType.income)
            .fold(0.0, (s, t) => s + t.amount));
        bucketExpense.add(mTxs
            .where((t) => t.type == TransactionType.expense)
            .fold(0.0, (s, t) => s + t.amount));
      }
    } else if (mode == '6months') {
      for (int i = 0; i < 6; i++) {
        final m = DateTime(anchor.year, anchor.month + i, 1);
        bucketLabels.add(DateFormat('MMM').format(m));
        final mTxs = rangeTxs.where(
            (t) => t.date.year == m.year && t.date.month == m.month);
        bucketIncome.add(mTxs
            .where((t) => t.type == TransactionType.income)
            .fold(0.0, (s, t) => s + t.amount));
        bucketExpense.add(mTxs
            .where((t) => t.type == TransactionType.expense)
            .fold(0.0, (s, t) => s + t.amount));
      }
    } else if (mode == 'yearly') {
      for (int q = 0; q < 4; q++) {
        final qStart = DateTime(anchor.year, 1 + q * 3, 1);
        final qEnd = DateTime(anchor.year, 1 + (q + 1) * 3, 1);
        bucketLabels.add('Q${q + 1}');
        final qTxs = rangeTxs.where(
            (t) => !t.date.isBefore(qStart) && t.date.isBefore(qEnd));
        bucketIncome.add(qTxs
            .where((t) => t.type == TransactionType.income)
            .fold(0.0, (s, t) => s + t.amount));
        bucketExpense.add(qTxs
            .where((t) => t.type == TransactionType.expense)
            .fold(0.0, (s, t) => s + t.amount));
      }
    } else {
      // monthly
      bucketLabels.addAll(['W1', 'W2', 'W3', 'W4']);
      bucketIncome.addAll(List.filled(4, 0.0));
      bucketExpense.addAll(List.filled(4, 0.0));
      for (final t in rangeTxs) {
        final wIdx = ((t.date.day - 1) ~/ 7).clamp(0, 3);
        if (t.type == TransactionType.income) bucketIncome[wIdx] += t.amount;
        if (t.type == TransactionType.expense) bucketExpense[wIdx] += t.amount;
      }
    }

    final displayName =
        settings.userName.trim().isEmpty ? 'User' : settings.userName.trim();
    final fmt = NumberFormat('#,##0', 'en_US');

    return WavyBackground(
      child: RefreshIndicator(
        onRefresh: _loadData,
        color: AppColors.primary,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 110),
          children: [
            // ── Greeting Header ──────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hello, $displayName 👋',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 21,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : AppColors.lightTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _greeting(),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                      ),
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: () => showDisplayOptionsDialog(context),
                  child: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkCard : AppColors.lightSurface,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color:
                            isDark ? AppColors.darkBorder : AppColors.lightBorder,
                      ),
                    ),
                    child: Icon(
                      Icons.filter_list_rounded,
                      size: 22,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // ── Green Total Balance Card ─────────────────────────────────
            _HomeBalanceCard(
              totalBalance: periodBalance,
              accountsBalance: accProvider.totalBalance,
              periodLabel: periodLabel,
              totalIncome: totalIncome,
              totalExpense: totalExpense,
              currencySymbol: settings.currencySymbol,
              isHidden: settings.balanceHidden,
              onToggleHidden: settings.toggleBalanceHidden,
              onTap: () => context.go('/accounts'),
            ),
            const SizedBox(height: 22),

            // ── 4 Quick Actions ──────────────────────────────────────────
            _HomeQuickActions(
              isDark: isDark,
              onAddIncome: () => context.push('/add-transaction',
                  extra: {'type': 'income'}),
              onAddExpense: () => context.push('/add-transaction',
                  extra: {'type': 'expense'}),
              onTransfer: () => context.push('/transfer'),
              onBudget: () => context.go('/budgets'),
            ),
            const SizedBox(height: 22),

            // ── Income & Expense Summary Cards ───────────────────────────
            Row(
              children: [
                Expanded(
                  child: _MiniStatCard(
                    label: 'Income',
                    amount: '${settings.currencySymbol}${fmt.format(totalIncome)}',
                    trend: incomeTrend,
                    isIncome: true,
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _MiniStatCard(
                    label: 'Expense',
                    amount: '${settings.currencySymbol}${fmt.format(totalExpense)}',
                    trend: expenseTrend,
                    isIncome: false,
                    isDark: isDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ── W1-W4 Grouped Income vs Expense Bar Chart ────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : AppColors.lightSurface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _LegendDot(
                          color: AppColors.income,
                          label: 'Income',
                          isDark: isDark),
                      const SizedBox(width: 20),
                      _LegendDot(
                          color: AppColors.expense,
                          label: 'Expense',
                          isDark: isDark),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 160,
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
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 34,
                              getTitlesWidget: (v, _) => Text(
                                v >= 1000
                                    ? '${(v / 1000).toStringAsFixed(0)}k'
                                    : '${v.toInt()}',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10,
                                  color: AppColors.lightTextTertiary,
                                ),
                              ),
                            ),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (v, _) {
                                final idx = v.toInt();
                                final label = (idx >= 0 && idx < bucketLabels.length)
                                    ? bucketLabels[idx]
                                    : '';
                                return Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: Text(
                                    label,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: isDark
                                          ? AppColors.darkTextSecondary
                                          : AppColors.lightTextSecondary,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        barGroups: List.generate(bucketLabels.length, (i) {
                          return BarChartGroupData(
                            x: i,
                            barsSpace: 6,
                            barRods: [
                              BarChartRodData(
                                toY: bucketIncome[i],
                                color: AppColors.income,
                                width: bucketLabels.length > 4 ? 9 : 12,
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(6),
                                ),
                              ),
                              BarChartRodData(
                                toY: bucketExpense[i],
                                color: AppColors.expense,
                                width: bucketLabels.length > 4 ? 9 : 12,
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(6),
                                ),
                              ),
                            ],
                          );
                        }),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeBalanceCard extends StatelessWidget {
  /// Balance of the selected period (income − expense).
  final double totalBalance;

  /// Current sum of all account balances (not period-filtered).
  final double accountsBalance;
  final String periodLabel;
  final double totalIncome;
  final double totalExpense;
  final String currencySymbol;
  final bool isHidden;
  final VoidCallback onToggleHidden;
  final VoidCallback onTap;

  const _HomeBalanceCard({
    required this.totalBalance,
    required this.accountsBalance,
    required this.periodLabel,
    required this.totalIncome,
    required this.totalExpense,
    required this.currencySymbol,
    required this.isHidden,
    required this.onToggleHidden,
    required this.onTap,
  });

  String _formatAmount(double amount) {
    final formatter = NumberFormat('#,##0.00', 'en_US');
    final prefix = amount < 0 ? '-' : '';
    return '$prefix$currencySymbol${formatter.format(amount.abs())}';
  }

  String _trendLabel() {
    if (totalIncome <= 0 && totalExpense <= 0) return '+0.0%';
    if (totalIncome <= 0) return '-100%';
    final netPct = ((totalIncome - totalExpense) / totalIncome) * 100;
    final sign = netPct >= 0 ? '+' : '';
    return '$sign${netPct.toStringAsFixed(1)}%';
  }

  @override
  Widget build(BuildContext context) {
    final isPositiveTrend = totalIncome >= totalExpense;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 148,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: AppColors.primaryGradient,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.28),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Stack(
            children: [
              Positioned(
                right: 0,
                bottom: 0,
                top: 28,
                width: 170,
                child: CustomPaint(painter: _SparklinePainter()),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 20, 22, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total Balance · $periodLabel',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withValues(alpha: 0.88),
                      ),
                    ),
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            isHidden
                                ? '$currencySymbol••••••'
                                : _formatAmount(totalBalance),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 32,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: -0.6,
                              height: 1.15,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 10),
                        GestureDetector(
                          onTap: onToggleHidden,
                          behavior: HitTestBehavior.opaque,
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: Icon(
                              isHidden
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: Colors.white.withValues(alpha: 0.85),
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.22),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isPositiveTrend
                                    ? Icons.arrow_upward_rounded
                                    : Icons.arrow_downward_rounded,
                                color: Colors.white,
                                size: 13,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                _trendLabel(),
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Flexible(
                          child: Text(
                            'Accounts ${isHidden ? '$currencySymbol••••' : _formatAmount(accountsBalance)}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.white.withValues(alpha: 0.85),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final linePath = Path()
      ..moveTo(0, h * 0.72)
      ..cubicTo(w * 0.16, h * 0.56, w * 0.24, h * 0.82, w * 0.42, h * 0.64)
      ..cubicTo(w * 0.58, h * 0.46, w * 0.68, h * 0.72, w * 0.84, h * 0.26)
      ..quadraticBezierTo(w * 0.92, h * 0.14, w, h * 0.28);

    final fillPath = Path.from(linePath)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.white.withValues(alpha: 0.28),
          Colors.white.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h));

    canvas.drawPath(fillPath, fillPaint);

    final strokePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.65)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(linePath, strokePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _HomeQuickActions extends StatelessWidget {
  final bool isDark;
  final VoidCallback onAddIncome;
  final VoidCallback onAddExpense;
  final VoidCallback onTransfer;
  final VoidCallback onBudget;

  const _HomeQuickActions({
    required this.isDark,
    required this.onAddIncome,
    required this.onAddExpense,
    required this.onTransfer,
    required this.onBudget,
  });

  @override
  Widget build(BuildContext context) {
    final items = [
      (
        icon: Icons.arrow_downward_rounded,
        label: 'Income',
        color: AppColors.income,
        bg: AppColors.mintSoft,
        onTap: onAddIncome,
      ),
      (
        icon: Icons.arrow_upward_rounded,
        label: 'Expense',
        color: AppColors.expense,
        bg: AppColors.expenseLight,
        onTap: onAddExpense,
      ),
      (
        icon: Icons.swap_horiz_rounded,
        label: 'Transfer',
        color: AppColors.transfer,
        bg: AppColors.transferLight,
        onTap: onTransfer,
      ),
      (
        icon: Icons.calendar_today_rounded,
        label: 'Budget',
        color: AppColors.budgetPurple,
        bg: AppColors.budgetPurpleLight,
        onTap: onBudget,
      ),
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: items
          .map((item) => Expanded(
                child: GestureDetector(
                  onTap: item.onTap,
                  behavior: HitTestBehavior.opaque,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: isDark
                              ? item.color.withValues(alpha: 0.16)
                              : item.bg,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Center(
                          child: Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              color: item.color,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(item.icon, color: Colors.white, size: 17),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        item.label,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.lightTextPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ))
          .toList(),
    );
  }
}

/// Change of a period total vs the previous period.
class _Trend {
  final String text;
  final bool up;
  const _Trend(this.text, this.up);

  factory _Trend.of(double current, double previous) {
    if (previous <= 0) {
      return current > 0 ? const _Trend('New', true) : const _Trend('0%', true);
    }
    final pct = (current - previous) / previous * 100;
    final up = pct >= 0;
    final abs = pct.abs();
    return _Trend('${abs >= 100 ? abs.toStringAsFixed(0) : abs.toStringAsFixed(1)}%', up);
  }
}

class _MiniStatCard extends StatelessWidget {
  final String label;
  final String amount;
  final _Trend trend;
  final bool isIncome;
  final bool isDark;

  const _MiniStatCard({
    required this.label,
    required this.amount,
    required this.trend,
    required this.isIncome,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final color = isIncome ? AppColors.income : AppColors.expense;
    final softBg = isIncome ? AppColors.mintSoft : AppColors.expenseLight;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: isDark ? color.withValues(alpha: 0.18) : softBg,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isIncome
                      ? Icons.arrow_upward_rounded
                      : Icons.arrow_downward_rounded,
                  color: color,
                  size: 14,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            amount,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : AppColors.lightTextPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${trend.up ? '↑' : '↓'} ${trend.text} vs prev.',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              // More income or less expense is good (green), otherwise red.
              color: trend.up == isIncome ? AppColors.income : AppColors.expense,
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  final bool isDark;

  const _LegendDot({
    required this.color,
    required this.label,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color:
                isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
          ),
        ),
      ],
    );
  }
}
