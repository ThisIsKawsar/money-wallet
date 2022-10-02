import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cashpilot/providers/transaction_provider.dart';
import 'package:cashpilot/providers/account_provider.dart';
import 'package:cashpilot/providers/category_provider.dart';
import 'package:cashpilot/providers/settings_provider.dart';
import 'package:cashpilot/providers/goal_provider.dart';
import 'package:cashpilot/data/models/transaction_model.dart';
import 'package:cashpilot/core/theme/app_colors.dart';
import 'package:cashpilot/screens/dashboard/widgets/balance_card.dart';
import 'package:cashpilot/screens/dashboard/widgets/account_carousel.dart';
import 'package:cashpilot/screens/dashboard/widgets/quick_actions.dart';
import 'package:cashpilot/screens/dashboard/widgets/recent_transactions.dart';
import 'package:cashpilot/screens/dashboard/widgets/spending_chart.dart';
import 'package:cashpilot/screens/dashboard/widgets/savings_goals.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late DateTime _anchor;

  @override
  void initState() {
    super.initState();
    _resetAnchor();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  void _resetAnchor() {
    final now = DateTime.now();
    _anchor = DateTime(now.year, now.month, 1);
  }

  DateTimeRange _range() {
    return DateTimeRange(
        start: _anchor,
        end: DateTime(_anchor.year, _anchor.month + 1, 1));
  }

  String _rangeLabel() {
    return DateFormat('MMMM, yyyy').format(_anchor);
  }

  void _prev() => setState(() {
    _anchor = DateTime(_anchor.year, _anchor.month - 1, 1);
  });

  void _next() => setState(() {
    _anchor = DateTime(_anchor.year, _anchor.month + 1, 1);
  });

  Future<void> _loadData() async {
    await Future.wait([
      context.read<TransactionProvider>().loadTransactions(),
      context.read<AccountProvider>().loadAccounts(),
      context.read<CategoryProvider>().loadCategories(),
      context.read<GoalProvider>().loadGoals(),
    ]);
  }

  List<TransactionModel> _periodTxs(List<TransactionModel> all) {
    final r = _range();
    return all
        .where((t) => !t.date.isBefore(r.start) && t.date.isBefore(r.end))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final settings = context.watch<SettingsProvider>();
    final txProvider = context.watch<TransactionProvider>();
    final accProvider = context.watch<AccountProvider>();
    final catProvider = context.watch<CategoryProvider>();

    final periodTxs = _periodTxs(txProvider.transactions);

    final income = periodTxs
        .where((t) => t.type == TransactionType.income)
        .fold(0.0, (s, t) => s + t.amount);
    final expense = periodTxs
        .where((t) => t.type == TransactionType.expense)
        .fold(0.0, (s, t) => s + t.amount);

    // Category spending for period
    final Map<String, double> catSpending = {};
    for (final t in periodTxs.where((t) => t.type == TransactionType.expense)) {
      catSpending[t.categoryId] = (catSpending[t.categoryId] ?? 0) + t.amount;
    }
    final spendingData = catSpending.entries.map((e) {
      final cat = catProvider.getCategoryById(e.key);
      return SpendingChartData(
        categoryName: cat?.name ?? 'Unknown',
        amount: e.value,
        color: cat != null ? AppColors.fromHex(cat.color) : AppColors.primary,
        iconName: cat?.icon,
      );
    }).toList()
      ..sort((a, b) => b.amount.compareTo(a.amount));

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadData,
        color: AppColors.primary,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // ── App bar ──────────────────────────────────────────────────
            SliverAppBar(
              floating: true,
              snap: true,
              backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
              elevation: 0,
              titleSpacing: 0,
              toolbarHeight: 52,
              title: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _greeting(),
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.55)
                                : Colors.black.withValues(alpha: 0.45),
                          ),
                        ),
                        Text(
                          DateFormat('EEE, d MMM').format(DateTime.now()),
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF1a1a2e),
                          ),
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: () => context.go('/settings'),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.07)
                              : Colors.black.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.settings_outlined,
                            size: 20,
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF1a1a2e)),
                      ),
                    ),
                  ],
                ),
              ),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(44),
                child: _PeriodNavBar(
                  label: _rangeLabel(),
                  isDark: isDark,
                  onPrev: _prev,
                  onNext: _next,
                ),
              ),
            ),

            // ── Content ──────────────────────────────────────────────────
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Balance + income/expense card (period-aware)
                  BalanceCard(
                    totalBalance: accProvider.totalBalance,
                    totalIncome: income,
                    totalExpense: expense,
                    currencySymbol: settings.currencySymbol,
                  ),
                  const SizedBox(height: 20),

                  // Accounts carousel
                  _sectionTitle('My Accounts', isDark),
                  const SizedBox(height: 12),
                  AccountCarousel(
                    accounts: accProvider.accounts,
                    currencySymbol: settings.currencySymbol,
                  ),
                  const SizedBox(height: 20),

                  // Quick actions
                  _sectionTitle('Quick Actions', isDark),
                  const SizedBox(height: 12),
                  QuickActions(
                    onAddIncome: () => context.push('/add-transaction',
                        extra: {'type': 'income'}),
                    onAddExpense: () => context.push('/add-transaction',
                        extra: {'type': 'expense'}),
                    onTransfer: () => context.push('/transfer'),
                    onBudget: () => context.go('/budgets'),
                  ),
                  const SizedBox(height: 20),

                  // Recent transactions for the selected period
                  RecentTransactions(
                    transactions: periodTxs,
                    categories: catProvider.categories,
                    currencySymbol: settings.currencySymbol,
                    onSeeAll: () => context.go('/transactions'),
                  ),
                  const SizedBox(height: 20),

                  // Spending chart for the selected period
                  SpendingChart(
                    spendingData: spendingData,
                    totalSpending: expense,
                    currencySymbol: settings.currencySymbol,
                  ),
                  const SizedBox(height: 20),

                  // Savings goals
                  const SavingsGoals(),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String text, bool isDark) => Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: isDark ? Colors.white : const Color(0xFF1a1a2e),
        ),
      );

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }
}

// ── Period nav bar ────────────────────────────────────────────────────────────

class _PeriodNavBar extends StatelessWidget {
  final String label;
  final bool isDark;
  final VoidCallback onPrev, onNext;

  const _PeriodNavBar({
    required this.label,
    required this.isDark,
    required this.onPrev,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBg : AppColors.lightBg,
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left_rounded),
            onPressed: onPrev,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          Expanded(
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF1a1a2e),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right_rounded),
            onPressed: onNext,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}
