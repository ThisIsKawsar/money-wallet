import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import 'package:cashpilot/providers/budget_provider.dart';
import 'package:cashpilot/providers/transaction_provider.dart';
import 'package:cashpilot/providers/category_provider.dart';
import 'package:cashpilot/providers/settings_provider.dart';
import 'package:cashpilot/data/models/budget_model.dart';
import 'package:cashpilot/core/theme/app_colors.dart';
import 'package:cashpilot/widgets/empty_state.dart';
import 'package:cashpilot/widgets/category_icon.dart';

const _uuid = Uuid();

class BudgetsScreen extends StatefulWidget {
  const BudgetsScreen({super.key});

  @override
  State<BudgetsScreen> createState() => _BudgetsScreenState();
}

class _BudgetsScreenState extends State<BudgetsScreen> {
  // Selected month/year for viewing budgets
  late DateTime _viewMonth;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _viewMonth = DateTime(now.year, now.month, 1);
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    await Future.wait([
      context.read<BudgetProvider>().loadBudgets(),
      context.read<TransactionProvider>().loadTransactions(),
      context.read<CategoryProvider>().loadCategories(),
    ]);
  }

  List<BudgetModel> _budgetsForMonth(List<BudgetModel> all) {
    return all.where((b) {
      final d = b.startDate;
      return d.year == _viewMonth.year && d.month == _viewMonth.month;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final budgets = context.watch<BudgetProvider>();
    final txProvider = context.watch<TransactionProvider>();
    final catProvider = context.watch<CategoryProvider>();
    final settings = context.watch<SettingsProvider>();

    final monthBudgets = _budgetsForMonth(budgets.budgets);
    final spending = txProvider.getCategorySpendingForMonth(
        _viewMonth.year, _viewMonth.month);

    final totalBudget = monthBudgets.fold(0.0, (s, b) => s + b.amount);
    final totalSpent = spending.values.fold(0.0, (s, v) => s + v);
    final overallProgress =
        totalBudget > 0 ? (totalSpent / totalBudget).clamp(0.0, 1.0) : 0.0;

    return Scaffold(
      appBar: AppBar(
        title: Text('Budgets',
            style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF1a1a2e))),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: () =>
                _showAddBudget(context, catProvider, settings),
          ),
        ],
      ),
      body: Column(
        children: [
          // Month navigator
          _MonthNavigator(
            month: _viewMonth,
            isDark: isDark,
            onPrev: () =>
                setState(() => _viewMonth = DateTime(_viewMonth.year, _viewMonth.month - 1, 1)),
            onNext: () =>
                setState(() => _viewMonth = DateTime(_viewMonth.year, _viewMonth.month + 1, 1)),
          ),
          Expanded(
            child: monthBudgets.isEmpty
                ? EmptyState(
                    icon: Icons.pie_chart_outline_rounded,
                    title: 'No budgets for ${DateFormat('MMMM yyyy').format(_viewMonth)}',
                    subtitle: 'Tap + to set a category budget',
                    actionLabel: 'Add Budget',
                    onAction: () =>
                        _showAddBudget(context, catProvider, settings),
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                    children: [
                      // Overall summary ring
                      _OverallSummary(
                        totalBudget: totalBudget,
                        totalSpent: totalSpent,
                        progress: overallProgress,
                        symbol: settings.currencySymbol,
                        isDark: isDark,
                      ),
                      const SizedBox(height: 20),
                      Text('Category Budgets',
                          style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF1a1a2e))),
                      const SizedBox(height: 12),
                      ...monthBudgets.map((b) {
                        final cat = catProvider.getCategoryById(b.categoryId ?? '');
                        final spent = spending[b.categoryId] ?? 0.0;
                        final progress = b.amount > 0
                            ? (spent / b.amount).clamp(0.0, 1.0)
                            : 0.0;
                        final color = progress >= 1.0
                            ? AppColors.expense
                            : progress >= 0.8
                                ? const Color(0xFFfdcb6e)
                                : AppColors.income;
                        return _BudgetCard(
                          category: cat,
                          budget: b,
                          spent: spent,
                          progress: progress,
                          color: color,
                          symbol: settings.currencySymbol,
                          isDark: isDark,
                          onEdit: () => _showEditBudget(
                              context, b, settings),
                          onDelete: () =>
                              context.read<BudgetProvider>().deleteBudget(b.id),
                        );
                      }),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddBudget(BuildContext context,
      CategoryProvider catProvider, SettingsProvider settings) async {
    final cats = catProvider.expenseCategories;
    if (cats.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No expense categories found')));
      return;
    }

    String? selectedCatId = cats.first.id;
    final amountCtrl = TextEditingController();
    int selMonth = _viewMonth.month;
    int selYear = _viewMonth.year;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: const Text('Add Budget'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DropdownButtonFormField<String>(
                  value: selectedCatId,
                  items: cats
                      .map((c) => DropdownMenuItem(
                          value: c.id, child: Text(c.name)))
                      .toList(),
                  onChanged: (v) => setS(() => selectedCatId = v),
                  decoration: const InputDecoration(labelText: 'Category'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: amountCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                      labelText: 'Budget Amount',
                      prefixText: settings.currencySymbol),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        value: selMonth,
                        items: List.generate(12, (i) => i + 1)
                            .map((m) => DropdownMenuItem(
                                value: m,
                                child: Text(DateFormat('MMM')
                                    .format(DateTime(2000, m)))))
                            .toList(),
                        onChanged: (v) => setS(() => selMonth = v ?? selMonth),
                        decoration: const InputDecoration(labelText: 'Month'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        value: selYear,
                        items: List.generate(5, (i) => DateTime.now().year - 2 + i)
                            .map((y) => DropdownMenuItem(
                                value: y, child: Text(y.toString())))
                            .toList(),
                        onChanged: (v) => setS(() => selYear = v ?? selYear),
                        decoration: const InputDecoration(labelText: 'Year'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                final amount = double.tryParse(amountCtrl.text);
                if (amount == null || selectedCatId == null) return;
                await ctx.read<BudgetProvider>().addBudget(BudgetModel(
                      id: _uuid.v4(),
                      categoryId: selectedCatId,
                      amount: amount,
                      period: BudgetPeriod.monthly,
                      startDate: DateTime(selYear, selMonth, 1),
                    ));
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showEditBudget(BuildContext context, BudgetModel budget,
      SettingsProvider settings) async {
    final amountCtrl =
        TextEditingController(text: budget.amount.toStringAsFixed(2));
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Budget'),
        content: TextField(
          controller: amountCtrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
              labelText: 'Budget Amount',
              prefixText: settings.currencySymbol),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final amount = double.tryParse(amountCtrl.text);
              if (amount == null) return;
              await ctx
                  .read<BudgetProvider>()
                  .updateBudget(budget.copyWith(amount: amount));
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }
}

class _MonthNavigator extends StatelessWidget {
  final DateTime month;
  final bool isDark;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  const _MonthNavigator(
      {required this.month,
      required this.isDark,
      required this.onPrev,
      required this.onNext});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        border: Border(
            bottom: BorderSide(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
              icon: const Icon(Icons.chevron_left_rounded),
              onPressed: onPrev,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints()),
          Text(
            DateFormat('MMMM yyyy').format(month),
            style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF1a1a2e)),
          ),
          IconButton(
              icon: const Icon(Icons.chevron_right_rounded),
              onPressed: onNext,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints()),
        ],
      ),
    );
  }
}

class _OverallSummary extends StatelessWidget {
  final double totalBudget, totalSpent, progress;
  final String symbol;
  final bool isDark;

  const _OverallSummary(
      {required this.totalBudget,
      required this.totalSpent,
      required this.progress,
      required this.symbol,
      required this.isDark});

  @override
  Widget build(BuildContext context) {
    final remaining = totalBudget - totalSpent;
    final color = progress >= 1.0
        ? AppColors.expense
        : progress >= 0.8
            ? const Color(0xFFfdcb6e)
            : AppColors.income;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.15),
            color.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _amountLabel('Spent', '$symbol${totalSpent.toStringAsFixed(2)}',
                  color, isDark),
              _amountLabel('Budget',
                  '$symbol${totalBudget.toStringAsFixed(2)}', color, isDark),
              _amountLabel(
                  'Left',
                  '$symbol${remaining.abs().toStringAsFixed(2)}',
                  remaining >= 0 ? AppColors.income : AppColors.expense,
                  isDark),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: color.withValues(alpha: 0.15),
              valueColor: AlwaysStoppedAnimation(color),
              minHeight: 10,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${(progress * 100).toStringAsFixed(1)}% of total budget used',
            style: GoogleFonts.inter(
                fontSize: 12,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.5)
                    : Colors.black.withValues(alpha: 0.5)),
          ),
        ],
      ),
    );
  }

  Widget _amountLabel(String label, String value, Color color, bool isDark) =>
      Column(
        children: [
          Text(label,
              style: GoogleFonts.inter(fontSize: 11, color: color)),
          const SizedBox(height: 4),
          Text(value,
              style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF1a1a2e))),
        ],
      );
}

class _BudgetCard extends StatelessWidget {
  final dynamic category;
  final BudgetModel budget;
  final double spent, progress;
  final Color color;
  final String symbol;
  final bool isDark;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _BudgetCard({
    required this.category,
    required this.budget,
    required this.spent,
    required this.progress,
    required this.color,
    required this.symbol,
    required this.isDark,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final remaining = budget.amount - spent;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CategoryIcon(
                  iconName: category?.icon, colorHex: category?.color),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(category?.name ?? 'Unknown',
                        style: GoogleFonts.inter(
                            fontSize: 15, fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : const Color(0xFF1a1a2e))),
                    Text(
                      '$symbol${spent.toStringAsFixed(2)} of $symbol${budget.amount.toStringAsFixed(2)}',
                      style: GoogleFonts.inter(
                          fontSize: 12,
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.5)
                              : Colors.black.withValues(alpha: 0.5)),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    remaining >= 0 ? '$symbol${remaining.toStringAsFixed(2)} left' : 'Over by $symbol${remaining.abs().toStringAsFixed(2)}',
                    style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: remaining >= 0 ? AppColors.income : AppColors.expense),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: color.withValues(alpha: 0.12),
              valueColor: AlwaysStoppedAnimation(color),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined, size: 14),
                label: const Text('Edit'),
                style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 8)),
              ),
              TextButton.icon(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline, size: 14),
                label: const Text('Delete'),
                style: TextButton.styleFrom(
                    foregroundColor: AppColors.expense,
                    padding: const EdgeInsets.symmetric(horizontal: 8)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
