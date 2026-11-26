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
import 'package:cashpilot/core/constants/app_icons.dart';
import 'package:cashpilot/widgets/empty_state.dart';
import 'package:cashpilot/widgets/wavy_background.dart';

const _uuid = Uuid();

class BudgetsScreen extends StatefulWidget {
  const BudgetsScreen({super.key});

  @override
  State<BudgetsScreen> createState() => _BudgetsScreenState();
}

class _BudgetsScreenState extends State<BudgetsScreen> {
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
      _viewMonth.year,
      _viewMonth.month,
    );

    final totalBudget = monthBudgets.fold(0.0, (s, b) => s + b.amount);
    final totalSpent = monthBudgets.fold(
        0.0, (s, b) => s + (spending[b.categoryId] ?? 0.0));
    final fmt = NumberFormat('#,##0.00', 'en_US');

    return WavyBackground(
      child: Column(
        children: [
          // Month Navigator + Total Budget / Total Spent Bar
          Container(
            margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 12),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : AppColors.lightSurface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () => setState(() => _viewMonth =
                          DateTime(_viewMonth.year, _viewMonth.month - 1, 1)),
                      icon: const Icon(Icons.chevron_left_rounded),
                      visualDensity: VisualDensity.compact,
                    ),
                    Expanded(
                      child: Text(
                        DateFormat('MMMM, yyyy').format(_viewMonth),
                        textAlign: TextAlign.center,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : AppColors.lightTextPrimary,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => setState(() => _viewMonth =
                          DateTime(_viewMonth.year, _viewMonth.month + 1, 1)),
                      icon: const Icon(Icons.chevron_right_rounded),
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Divider(
                  height: 1,
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            'TOTAL BUDGET',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.lightTextSecondary,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${settings.currencySymbol}${fmt.format(totalBudget)}',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            'TOTAL SPENT',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.lightTextSecondary,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${settings.currencySymbol}${fmt.format(totalSpent)}',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: totalSpent > totalBudget
                                  ? AppColors.expense
                                  : AppColors.income,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          Expanded(
            child: monthBudgets.isEmpty
                ? EmptyState(
                    icon: Icons.calculate_outlined,
                    title:
                        'No budgets for ${DateFormat('MMMM yyyy').format(_viewMonth)}',
                    subtitle: 'Set category limits to track your monthly spending',
                    actionLabel: 'Set Budget',
                    onAction: () =>
                        _showAddOrEditBudget(context, catProvider, settings),
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(16, 6, 16, 100),
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Budgeted categories: ${DateFormat('MMM, yyyy').format(_viewMonth)}',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? Colors.white
                                  : AppColors.lightTextPrimary,
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () => _showAddOrEditBudget(
                                context, catProvider, settings),
                            icon: const Icon(Icons.add_rounded, size: 18),
                            label: const Text('Add'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ...monthBudgets.map((b) {
                        final cat =
                            catProvider.getCategoryById(b.categoryId ?? '');
                        final spent = spending[b.categoryId] ?? 0.0;
                        final remaining = (b.amount - spent).clamp(0.0, double.infinity);
                        final exceeded = spent > b.amount;
                        final progress = b.amount > 0
                            ? (spent / b.amount).clamp(0.0, 1.0)
                            : 0.0;
                        final catColor = cat != null
                            ? AppColors.fromHex(cat.color)
                            : AppColors.primary;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.darkCard
                                : AppColors.lightSurface,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: isDark
                                  ? AppColors.darkBorder
                                  : AppColors.lightBorder,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: catColor.withValues(alpha: 0.14),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      cat != null
                                          ? AppIcons.fromName(cat.icon)
                                          : Icons.category_rounded,
                                      color: catColor,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      cat?.name ?? 'Category',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: isDark
                                            ? Colors.white
                                            : AppColors.lightTextPrimary,
                                      ),
                                    ),
                                  ),
                                  PopupMenuButton<String>(
                                    icon: const Icon(Icons.more_horiz_rounded),
                                    onSelected: (v) async {
                                      if (v == 'edit') {
                                        await _showAddOrEditBudget(
                                            context, catProvider, settings,
                                            existing: b);
                                      } else if (v == 'delete') {
                                        await budgets.deleteBudget(b.id);
                                      }
                                    },
                                    itemBuilder: (_) => const [
                                      PopupMenuItem(
                                          value: 'edit', child: Text('Edit')),
                                      PopupMenuItem(
                                          value: 'delete',
                                          child: Text('Delete')),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        _kvRow(
                                          'Limit:',
                                          '${settings.currencySymbol}${fmt.format(b.amount)}',
                                          isDark
                                              ? Colors.white
                                              : AppColors.lightTextPrimary,
                                          isDark,
                                        ),
                                        _kvRow(
                                          'Spent:',
                                          '${settings.currencySymbol}${fmt.format(spent)}',
                                          exceeded
                                              ? AppColors.expense
                                              : AppColors.income,
                                          isDark,
                                        ),
                                        _kvRow(
                                          'Remaining:',
                                          '${settings.currencySymbol}${fmt.format(remaining)}',
                                          exceeded
                                              ? AppColors.expense
                                              : AppColors.income,
                                          isDark,
                                        ),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        '(${DateFormat('MMM, yyyy').format(_viewMonth)})',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 11,
                                          color: isDark
                                              ? AppColors.darkTextSecondary
                                              : AppColors.lightTextSecondary,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: AppColors.primary,
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          '${settings.currencySymbol}${fmt.format(b.amount)}',
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: LinearProgressIndicator(
                                  value: progress,
                                  minHeight: 8,
                                  backgroundColor: isDark
                                      ? AppColors.darkCardAlt
                                      : const Color(0xFFE9EFEA),
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    exceeded
                                        ? AppColors.expense
                                        : AppColors.primary,
                                  ),
                                ),
                              ),
                              if (exceeded) ...[
                                const SizedBox(height: 4),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: Text(
                                    '*Limit exceeded',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.expense,
                                    ),
                                  ),
                                ),
                              ],
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

  Widget _kvRow(String k, String v, Color vColor, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1.5),
      child: Row(
        children: [
          SizedBox(
            width: 78,
            child: Text(
              k,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
              ),
            ),
          ),
          Text(
            v,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: vColor,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddOrEditBudget(
    BuildContext context,
    CategoryProvider catProvider,
    SettingsProvider settings, {
    BudgetModel? existing,
  }) async {
    final amountCtrl = TextEditingController(
      text: existing != null ? existing.amount.toStringAsFixed(2) : '',
    );
    final expenseCats = catProvider.expenseCategories;
    String? selectedCatId = existing?.categoryId ??
        (expenseCats.isNotEmpty ? expenseCats.first.id : null);

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: Text(existing == null ? 'Set Monthly Budget' : 'Edit Budget'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: selectedCatId,
                decoration: const InputDecoration(labelText: 'Category'),
                items: expenseCats
                    .map((c) => DropdownMenuItem(value: c.id, child: Text(c.name)))
                    .toList(),
                onChanged: existing != null
                    ? null
                    : (v) => setS(() => selectedCatId = v),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: amountCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Limit (${settings.currencySymbol})',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final amount = double.tryParse(amountCtrl.text);
                if (amount == null || amount <= 0 || selectedCatId == null) {
                  return;
                }
                if (existing != null) {
                  await context
                      .read<BudgetProvider>()
                      .updateBudget(existing.copyWith(amount: amount));
                } else {
                  final budget = BudgetModel(
                    id: _uuid.v4(),
                    categoryId: selectedCatId!,
                    amount: amount,
                    period: BudgetPeriod.monthly,
                    startDate: _viewMonth,
                  );
                  await context.read<BudgetProvider>().addBudget(budget);
                }
                if (ctx.mounted) Navigator.pop(ctx);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}
