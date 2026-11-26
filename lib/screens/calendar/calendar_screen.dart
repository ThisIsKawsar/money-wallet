import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:cashpilot/providers/budget_provider.dart';
import 'package:cashpilot/providers/transaction_provider.dart';
import 'package:cashpilot/providers/category_provider.dart';
import 'package:cashpilot/providers/settings_provider.dart';
import 'package:cashpilot/data/models/transaction_model.dart';
import 'package:cashpilot/core/theme/app_colors.dart';
import 'package:cashpilot/widgets/wavy_background.dart';
import 'package:cashpilot/widgets/ui_kit.dart';
import 'package:cashpilot/widgets/transaction_tile.dart';

enum _DayState { done, missed, pending, today }

/// Spending calendar: each past day is "Done" when spending stayed within the
/// daily allowance, "Missed" when it went over; future days are "Pending".
class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late DateTime _month;
  late DateTime _selected;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = DateTime(now.year, now.month, 1);
    _selected = DateTime(now.year, now.month, now.day);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BudgetProvider>().loadBudgets();
    });
  }

  @override
  Widget build(BuildContext context) {
    final txp = context.watch<TransactionProvider>();
    final catp = context.watch<CategoryProvider>();
    final budgetp = context.watch<BudgetProvider>();
    final symbol = context.watch<SettingsProvider>().currencySymbol;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final daysInMonth = DateTime(_month.year, _month.month + 1, 0).day;
    final monthEnd = DateTime(_month.year, _month.month + 1, 1);
    final monthTxs = txp.transactions
        .where((t) => !t.date.isBefore(_month) && t.date.isBefore(monthEnd))
        .toList();

    // Daily allowance
    final budgetTotal = budgetp.budgets
        .where((b) => b.startDate.year == _month.year && b.startDate.month == _month.month)
        .fold(0.0, (s, b) => s + b.amount);
    final monthIncome = monthTxs
        .where((t) => t.type == TransactionType.income)
        .fold(0.0, (s, t) => s + t.amount);
    final limit = budgetTotal > 0
        ? budgetTotal / daysInMonth
        : monthIncome > 0
            ? monthIncome / daysInMonth
            : double.infinity;
    final limitSource = budgetTotal > 0 ? 'budget' : monthIncome > 0 ? 'income' : null;

    final dailySpend = List<double>.filled(daysInMonth + 1, 0);
    for (final t in monthTxs.where((t) => t.type == TransactionType.expense)) {
      dailySpend[t.date.day] += t.amount;
    }

    _DayState stateOf(int day) {
      final d = DateTime(_month.year, _month.month, day);
      if (d.isAfter(today)) return _DayState.pending;
      if (d == today) return _DayState.today;
      return dailySpend[day] <= limit ? _DayState.done : _DayState.missed;
    }

    var done = 0, elapsed = 0;
    for (var d = 1; d <= daysInMonth; d++) {
      final s = stateOf(d);
      if (s == _DayState.pending) continue;
      elapsed++;
      if (s == _DayState.done || (s == _DayState.today && dailySpend[d] <= limit)) done++;
    }
    final pct = elapsed > 0 ? done / elapsed : 0.0;

    final leading = DateTime(_month.year, _month.month, 1).weekday % 7; // Sunday first
    final cells = <DateTime>[];
    for (var i = 0; i < 42; i++) {
      cells.add(DateTime(_month.year, _month.month, 1 - leading + i));
    }
    final rows = (leading + daysInMonth) > 35 ? 6 : 5;

    final selectedTxs = txp.transactions
        .where((t) =>
            t.date.year == _selected.year && t.date.month == _selected.month && t.date.day == _selected.day)
        .toList();

    return Scaffold(
      body: WavyBackground(
        child: SafeArea(
          child: Column(
            children: [
              ScreenHeader(
                title: 'Calendar',
                                trailing: IconButton(
                  icon: Icon(Icons.today_rounded, color: context.textPrimary),
                  onPressed: () => setState(() {
                    _month = DateTime(now.year, now.month, 1);
                    _selected = today;
                  }),
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 6, 20, 40),
                  children: [
                    SoftCard(
                      radius: 18,
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.chevron_left_rounded),
                            onPressed: () => setState(() => _month = DateTime(_month.year, _month.month - 1, 1)),
                          ),
                          Expanded(
                            child: Text(DateFormat('MMMM yyyy').format(_month),
                                textAlign: TextAlign.center,
                                style: jakarta(16, weight: FontWeight.w700, color: context.textPrimary)),
                          ),
                          IconButton(
                            icon: const Icon(Icons.chevron_right_rounded),
                            onPressed: () => setState(() => _month = DateTime(_month.year, _month.month + 1, 1)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']
                          .map((d) => Expanded(
                                child: Text(d,
                                    textAlign: TextAlign.center,
                                    style: jakarta(12, weight: FontWeight.w600, color: context.textSecondary)),
                              ))
                          .toList(),
                    ),
                    const SizedBox(height: 10),
                    for (var r = 0; r < rows; r++)
                      Row(
                        children: [
                          for (var c = 0; c < 7; c++)
                            Expanded(
                              child: Builder(builder: (context) {
                                final d = cells[r * 7 + c];
                                final inMonth = d.month == _month.month;
                                return _DayCell(
                                  day: d.day,
                                  inMonth: inMonth,
                                  state: inMonth ? stateOf(d.day) : _DayState.pending,
                                  selected: d == _selected,
                                  onTap: inMonth ? () => setState(() => _selected = d) : null,
                                );
                              }),
                            ),
                        ],
                      ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        LegendDot(color: AppColors.primary, label: 'Done'),
                        SizedBox(width: 18),
                        LegendDot(color: AppColors.expense, label: 'Missed'),
                        SizedBox(width: 18),
                        LegendDot(color: Color(0xFF9AA7A0), label: 'Pending', hollow: true),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // Trophy summary
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(22),
                        gradient: LinearGradient(colors: [
                          AppColors.primary.withValues(alpha: context.isDark ? 0.18 : 0.07),
                          AppColors.primary.withValues(alpha: context.isDark ? 0.10 : 0.15),
                        ]),
                        border: Border.all(color: AppColors.primary.withValues(alpha: 0.12)),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              GlossyIcon(icon: Icons.emoji_events_rounded, color: AppColors.primary, size: 52),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('This Month', style: jakarta(13, color: context.textSecondary)),
                                    Text('$done / $elapsed',
                                        style: jakarta(24, weight: FontWeight.w800, color: context.textPrimary)),
                                  ],
                                ),
                              ),
                              Text('${(pct * 100).round()}%',
                                  style: jakarta(24, weight: FontWeight.w800, color: context.textPrimary)),
                            ],
                          ),
                          const SizedBox(height: 12),
                          SoftProgressBar(value: pct),
                          const SizedBox(height: 10),
                          Text(
                            limitSource == null
                                ? 'Add a budget or income to set your daily allowance.'
                                : 'Days within your ${fmtMoney(limit, symbol)} daily allowance (from $limitSource).',
                            textAlign: TextAlign.center,
                            style: jakarta(12, color: context.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),
                    SectionHeader(title: DateFormat('EEEE, MMM d').format(_selected)),
                    const SizedBox(height: 10),
                    if (selectedTxs.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Text('No transactions on this day',
                            textAlign: TextAlign.center, style: jakarta(13, color: context.textSecondary)),
                      )
                    else
                      for (final tx in selectedTxs)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: TransactionTile(
                            tx: tx,
                            category: catp.getCategoryById(tx.categoryId),
                            currencySymbol: symbol,
                            showTime: true,
                            onTap: () => context.push('/add-transaction', extra: {'transaction': tx}),
                          ),
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

class _DayCell extends StatelessWidget {
  final int day;
  final bool inMonth;
  final _DayState state;
  final bool selected;
  final VoidCallback? onTap;

  const _DayCell({
    required this.day,
    required this.inMonth,
    required this.state,
    required this.selected,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color? bg;
    Color fg = context.textPrimary;
    Gradient? gradient;
    if (!inMonth) {
      fg = context.textTertiary.withValues(alpha: 0.6);
    } else {
      switch (state) {
        case _DayState.done:
          bg = AppColors.primary.withValues(alpha: context.isDark ? 0.2 : 0.12);
        case _DayState.missed:
          bg = AppColors.expense.withValues(alpha: context.isDark ? 0.22 : 0.12);
          fg = context.isDark ? const Color(0xFFFF9A9A) : AppColors.expenseDark;
        case _DayState.today:
          gradient = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.primaryLight, AppColors.primary],
          );
          fg = Colors.white;
        case _DayState.pending:
          bg = null;
          fg = context.textTertiary;
      }
    }

    return GestureDetector(
      onTap: onTap,
      child: AspectRatio(
        aspectRatio: 1,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          margin: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: gradient == null ? bg : null,
            gradient: gradient,
            borderRadius: BorderRadius.circular(12),
            border: selected && state != _DayState.today
                ? Border.all(color: AppColors.primary, width: 2)
                : null,
            boxShadow: state == _DayState.today && inMonth
                ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.35), blurRadius: 10, offset: const Offset(0, 4))]
                : null,
          ),
          alignment: Alignment.center,
          child: Text('$day',
              style: jakarta(14,
                  weight: inMonth && state != _DayState.pending ? FontWeight.w700 : FontWeight.w500, color: fg)),
        ),
      ),
    );
  }
}
