import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:cashpilot/providers/transaction_provider.dart';
import 'package:cashpilot/providers/account_provider.dart';
import 'package:cashpilot/providers/category_provider.dart';
import 'package:cashpilot/providers/settings_provider.dart';
import 'package:cashpilot/providers/goal_provider.dart';
import 'package:cashpilot/data/models/transaction_model.dart';
import 'package:cashpilot/core/theme/app_colors.dart';
import 'package:cashpilot/core/constants/app_icons.dart';
import 'package:cashpilot/widgets/wavy_background.dart';
import 'package:cashpilot/widgets/period_bar.dart';
import 'package:cashpilot/widgets/empty_state.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late DateTime _anchor;
  String? _lastMode;

  @override
  void initState() {
    super.initState();
    final mode = context.read<SettingsProvider>().filterPeriod;
    _lastMode = mode;
    _anchor = PeriodHelpers.defaultAnchor(mode);
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final settings = context.watch<SettingsProvider>();
    final txProvider = context.watch<TransactionProvider>();
    final accProvider = context.watch<AccountProvider>();
    final catProvider = context.watch<CategoryProvider>();

    if (_lastMode != settings.filterPeriod) {
      _lastMode = settings.filterPeriod;
      _anchor = PeriodHelpers.defaultAnchor(settings.filterPeriod);
    }

    final range = PeriodHelpers.range(_anchor, settings.filterPeriod);
    final periodTxs = txProvider.transactions
        .where((t) => !t.date.isBefore(range.start) && t.date.isBefore(range.end))
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    final income = periodTxs
        .where((t) => t.type == TransactionType.income)
        .fold(0.0, (s, t) => s + t.amount);
    final expense = periodTxs
        .where((t) => t.type == TransactionType.expense)
        .fold(0.0, (s, t) => s + t.amount);

    final total = income - expense;

    // Group by Day: "Nov 25, Wednesday"
    final Map<String, List<TransactionModel>> dayGroups = {};
    for (final tx in periodTxs) {
      final key = DateFormat('MMM d, EEEE').format(tx.date);
      dayGroups.putIfAbsent(key, () => []).add(tx);
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
            expense: expense,
            income: income,
            total: total,
            currencySymbol: settings.currencySymbol,
            onPeriodModeChanged: () => setState(() {
              _anchor = PeriodHelpers.defaultAnchor(settings.filterPeriod);
            }),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadData,
              color: AppColors.primary,
              child: periodTxs.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        const SizedBox(height: 60),
                        EmptyState(
                          icon: Icons.receipt_long_outlined,
                          title: 'No records in this period',
                          subtitle: 'Tap + to add your first transaction',
                          actionLabel: 'Add Record',
                          onAction: () => context.push('/add-transaction'),
                        ),
                      ],
                    )
                  : ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics(),
                      ),
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
                      itemCount: dayGroups.length,
                      itemBuilder: (context, idx) {
                        final dayLabel = dayGroups.keys.elementAt(idx);
                        final items = dayGroups[dayLabel]!;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(top: 12, bottom: 8),
                              child: Text(
                                dayLabel,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: isDark
                                      ? AppColors.darkTextSecondary
                                      : AppColors.lightTextSecondary,
                                ),
                              ),
                            ),
                            ...items.map((tx) {
                              final cat = catProvider.getCategoryById(tx.categoryId);
                              final acc = accProvider.getAccountById(tx.accountId);
                              final isIncome = tx.type == TransactionType.income;
                              final isTransfer = tx.type == TransactionType.transfer;
                              final catColor = isTransfer
                                  ? AppColors.transfer
                                  : cat != null
                                      ? AppColors.fromHex(cat.color)
                                      : AppColors.primary;
                              final catIcon = isTransfer
                                  ? Icons.swap_horiz_rounded
                                  : cat != null
                                      ? AppIcons.fromName(cat.icon)
                                      : Icons.receipt_long_rounded;
                              final title = (tx.note != null && tx.note!.trim().isNotEmpty)
                                  ? tx.note!
                                  : (cat?.name ?? (isTransfer ? 'Transfer' : 'Record'));

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Slidable(
                                  endActionPane: ActionPane(
                                    motion: const ScrollMotion(),
                                    children: [
                                      SlidableAction(
                                        onPressed: (_) async {
                                          await txProvider.deleteTransaction(tx.id);
                                        },
                                        backgroundColor: AppColors.expense,
                                        foregroundColor: Colors.white,
                                        icon: Icons.delete_outline_rounded,
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                    ],
                                  ),
                                  child: InkWell(
                                    onTap: () => context.push(
                                      '/add-transaction',
                                      extra: {'transaction': tx},
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 12,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isDark
                                            ? AppColors.darkCard
                                            : AppColors.lightSurface,
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: isDark
                                              ? AppColors.darkBorder
                                              : AppColors.lightBorder,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 42,
                                            height: 42,
                                            decoration: BoxDecoration(
                                              color: catColor.withValues(alpha: 0.14),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Icon(
                                              catIcon,
                                              color: catColor,
                                              size: 20,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  title,
                                                  style: GoogleFonts.plusJakartaSans(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w600,
                                                    color: isDark
                                                        ? Colors.white
                                                        : AppColors.lightTextPrimary,
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                                const SizedBox(height: 2),
                                                Row(
                                                  children: [
                                                    Icon(
                                                      Icons.account_balance_wallet_outlined,
                                                      size: 12,
                                                      color: isDark
                                                          ? AppColors.darkTextTertiary
                                                          : AppColors.lightTextTertiary,
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      acc?.name ?? 'Account',
                                                      style: GoogleFonts.plusJakartaSans(
                                                        fontSize: 12,
                                                        color: isDark
                                                            ? AppColors.darkTextSecondary
                                                            : AppColors.lightTextSecondary,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                          Text(
                                            '${isIncome ? '+' : '-'}${settings.currencySymbol}${fmt.format(tx.amount)}',
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w700,
                                              color: isIncome
                                                  ? AppColors.income
                                                  : isTransfer
                                                      ? AppColors.transfer
                                                      : AppColors.expense,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ],
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
