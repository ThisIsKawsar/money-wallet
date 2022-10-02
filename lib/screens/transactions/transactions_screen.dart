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
import 'package:cashpilot/data/models/transaction_model.dart';
import 'package:cashpilot/core/theme/app_colors.dart';
import 'package:cashpilot/widgets/empty_state.dart';
import 'package:cashpilot/widgets/category_icon.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});
  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  String _typeFilter = 'all';
  late DateTime _anchor; // start of the current period window

  @override
  void initState() {
    super.initState();
    _resetAnchor();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TransactionProvider>().loadTransactions();
      context.read<CategoryProvider>().loadCategories();
      context.read<AccountProvider>().loadAccounts();
    });
  }

  void _resetAnchor() {
    final now = DateTime.now();
    final settings = context.read<SettingsProvider>();
    switch (settings.filterPeriod) {
      case 'daily':
        _anchor = DateTime(now.year, now.month, now.day);
      case 'weekly':
        _anchor = now.subtract(Duration(days: now.weekday - 1));
        _anchor = DateTime(_anchor.year, _anchor.month, _anchor.day);
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
            start: _anchor,
            end: _anchor.add(const Duration(days: 1)));
      case 'weekly':
        return DateTimeRange(
            start: _anchor,
            end: _anchor.add(const Duration(days: 7)));
      case 'yearly':
        return DateTimeRange(
            start: _anchor,
            end: DateTime(_anchor.year + 1, 1, 1));
      default: // monthly
        return DateTimeRange(
            start: _anchor,
            end: DateTime(_anchor.year, _anchor.month + 1, 1));
    }
  }

  String _rangeLabel() {
    final r = _range();
    final settings = context.read<SettingsProvider>();
    switch (settings.filterPeriod) {
      case 'daily':
        return DateFormat('MMM d, EEEE').format(r.start);
      case 'weekly':
        return '${DateFormat('MMM d').format(r.start)} - ${DateFormat('MMM d').format(r.end.subtract(const Duration(days: 1)))}';
      case 'yearly':
        return _anchor.year.toString();
      default:
        return DateFormat('MMMM, yyyy').format(_anchor);
    }
  }

  void _prev() {
    setState(() {
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
  }

  void _next() {
    setState(() {
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
  }

  List<TransactionModel> _filtered(List<TransactionModel> all) {
    final r = _range();
    var list = all
        .where((t) => !t.date.isBefore(r.start) && t.date.isBefore(r.end))
        .toList();
    if (_typeFilter != 'all') {
      final type = TransactionType.values.firstWhere(
          (t) => t.name == _typeFilter,
          orElse: () => TransactionType.expense);
      list = list.where((t) => t.type == type).toList();
    }
    return list;
  }

  Map<String, List<TransactionModel>> _groupByDate(
      List<TransactionModel> txs) {
    final Map<String, List<TransactionModel>> grouped = {};
    for (final tx in txs) {
      final key = DateFormat('yyyy-MM-dd').format(tx.date);
      grouped.putIfAbsent(key, () => []).add(tx);
    }
    return Map.fromEntries(
        grouped.entries.toList()..sort((a, b) => b.key.compareTo(a.key)));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final txProvider = context.watch<TransactionProvider>();
    final catProvider = context.watch<CategoryProvider>();
    final accProvider = context.watch<AccountProvider>();
    final settings = context.watch<SettingsProvider>();

    final filtered = _filtered(txProvider.transactions);
    final grouped = _groupByDate(filtered);

    final income = filtered
        .where((t) => t.type == TransactionType.income)
        .fold(0.0, (s, t) => s + t.amount);
    final expense = filtered
        .where((t) => t.type == TransactionType.expense)
        .fold(0.0, (s, t) => s + t.amount);
    final net = income - expense;

    return Scaffold(
      body: Column(
        children: [
          // ── Header ──────────────────────────────────────────────────────
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                // Period nav bar
                _PeriodNavBar(
                  label: _rangeLabel(),
                  isDark: isDark,
                  onPrev: _prev,
                  onNext: _next,
                  onFilter: () => _showPeriodPicker(context),
                ),
                // Summary
                _SummaryHeader(
                  income: income,
                  expense: expense,
                  net: net,
                  symbol: settings.currencySymbol,
                  isDark: isDark,
                ),
                // Type filter chips
                _TypeChips(
                  selected: _typeFilter,
                  isDark: isDark,
                  onSelect: (t) => setState(() => _typeFilter = t),
                ),
              ],
            ),
          ),
          // ── List ─────────────────────────────────────────────────────────
          Expanded(
            child: grouped.isEmpty
                ? EmptyState(
                    icon: Icons.receipt_long_rounded,
                    title: 'No transactions',
                    subtitle: 'Tap + to record a transaction',
                    actionLabel: 'Add Transaction',
                    onAction: () => context.push('/add-transaction'),
                  )
                : RefreshIndicator(
                    onRefresh: () async {
                      await txProvider.loadTransactions();
                      await accProvider.loadAccounts();
                    },
                    color: AppColors.primary,
                    child: ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.only(bottom: 100),
                      itemCount: grouped.length,
                      itemBuilder: (context, i) {
                        final dateKey = grouped.keys.elementAt(i);
                        final dayTxs = grouped[dateKey]!;
                        return _DateGroup(
                          dateKey: dateKey,
                          transactions: dayTxs,
                          catProvider: catProvider,
                          accProvider: accProvider,
                          symbol: settings.currencySymbol,
                          isDark: isDark,
                          onEdit: (tx) => context.push('/add-transaction',
                              extra: {'transaction': tx}),
                          onDelete: (tx) => _confirmDelete(context, tx),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, TransactionModel tx) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Transaction'),
        content: const Text('Are you sure?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Delete',
                  style: TextStyle(color: AppColors.expense))),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      await context.read<TransactionProvider>().deleteTransaction(tx.id);
    }
  }

  void _showPeriodPicker(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final settings = context.read<SettingsProvider>();
    final options = [
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
          children: options.map((o) {
            final isSelected = settings.filterPeriod == o['key'];
            return ListTile(
              dense: true,
              leading: isSelected
                  ? const Icon(Icons.check, color: AppColors.primary)
                  : const SizedBox(width: 24),
              title: Text(o['label']!,
                  style: GoogleFonts.inter(
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: isSelected ? AppColors.primary : null)),
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

// ── Widgets ──────────────────────────────────────────────────────────────────

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
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF1a1a2e)),
            ),
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

class _SummaryHeader extends StatelessWidget {
  final double income, expense, net;
  final String symbol;
  final bool isDark;

  const _SummaryHeader(
      {required this.income,
      required this.expense,
      required this.net,
      required this.symbol,
      required this.isDark});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##0.00');
    return Container(
      color: isDark ? AppColors.darkBg : AppColors.lightBg,
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          _col('EXPENSE', '$symbol${fmt.format(expense)}',
              AppColors.expense, isDark),
          _col('INCOME', '$symbol${fmt.format(income)}',
              AppColors.income, isDark),
          _col(
              'TOTAL',
              '${net < 0 ? '-' : ''}$symbol${fmt.format(net.abs())}',
              net >= 0 ? AppColors.income : AppColors.expense,
              isDark),
        ],
      ),
    );
  }

  Widget _col(String label, String value, Color color, bool isDark) =>
      Expanded(
        child: Column(
          children: [
            Text(label,
                style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.5)
                        : Colors.black.withValues(alpha: 0.5),
                    letterSpacing: 0.5)),
            const SizedBox(height: 4),
            Text(value,
                style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: color),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ],
        ),
      );
}

class _TypeChips extends StatelessWidget {
  final String selected;
  final bool isDark;
  final void Function(String) onSelect;

  const _TypeChips(
      {required this.selected, required this.isDark, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final filters = [
      {'key': 'all', 'label': 'All'},
      {'key': 'income', 'label': 'Income'},
      {'key': 'expense', 'label': 'Expense'},
      {'key': 'transfer', 'label': 'Transfer'},
    ];
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: filters.map((f) {
          final isSelected = selected == f['key'];
          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: ChoiceChip(
              label: Text(f['label']!),
              selected: isSelected,
              onSelected: (_) => onSelect(f['key']!),
              selectedColor: AppColors.primary,
              backgroundColor:
                  isDark ? AppColors.darkCardAlt : AppColors.lightCardAlt,
              labelStyle: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isSelected
                      ? Colors.white
                      : isDark
                          ? Colors.white.withValues(alpha: 0.7)
                          : Colors.black.withValues(alpha: 0.7)),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(
                      color: isSelected
                          ? AppColors.primary
                          : isDark
                              ? AppColors.darkBorder
                              : AppColors.lightBorder)),
              padding: const EdgeInsets.symmetric(horizontal: 4),
              visualDensity: VisualDensity.compact,
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _DateGroup extends StatelessWidget {
  final String dateKey;
  final List<TransactionModel> transactions;
  final dynamic catProvider;
  final dynamic accProvider;
  final String symbol;
  final bool isDark;
  final void Function(TransactionModel) onEdit;
  final void Function(TransactionModel) onDelete;

  const _DateGroup(
      {required this.dateKey,
      required this.transactions,
      required this.catProvider,
      required this.accProvider,
      required this.symbol,
      required this.isDark,
      required this.onEdit,
      required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final date = DateTime.parse(dateKey);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final d = DateTime(date.year, date.month, date.day);

    String label;
    if (d == today) {
      label = 'Today, ${DateFormat('MMMM d').format(date)}';
    } else if (d == yesterday) {
      label = 'Yesterday, ${DateFormat('MMMM d').format(date)}';
    } else {
      label = DateFormat('MMM d, EEEE').format(date);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
          child: Text(label,
              style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.6)
                      : Colors.black.withValues(alpha: 0.6))),
        ),
        Divider(
            height: 1,
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            indent: 16,
            endIndent: 16),
        ...transactions.map((tx) => _TxRow(
              transaction: tx,
              catProvider: catProvider,
              accProvider: accProvider,
              symbol: symbol,
              isDark: isDark,
              onEdit: () => onEdit(tx),
              onDelete: () => onDelete(tx),
            )),
      ],
    );
  }
}

class _TxRow extends StatelessWidget {
  final TransactionModel transaction;
  final dynamic catProvider;
  final dynamic accProvider;
  final String symbol;
  final bool isDark;
  final VoidCallback onEdit, onDelete;

  const _TxRow(
      {required this.transaction,
      required this.catProvider,
      required this.accProvider,
      required this.symbol,
      required this.isDark,
      required this.onEdit,
      required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final cat = catProvider.getCategoryById(transaction.categoryId);
    final acc = accProvider.getAccountById(transaction.accountId);
    final toAcc = transaction.toAccountId != null
        ? accProvider.getAccountById(transaction.toAccountId)
        : null;

    final isIncome = transaction.type == TransactionType.income;
    final isTransfer = transaction.type == TransactionType.transfer;
    final amountColor = isIncome
        ? AppColors.income
        : isTransfer
            ? AppColors.transfer
            : AppColors.expense;
    final prefix = isIncome ? '+' : isTransfer ? '' : '-';
    final fmt = NumberFormat('#,##0.00');

    return Slidable(
      endActionPane: ActionPane(
        motion: const DrawerMotion(),
        extentRatio: 0.38,
        children: [
          SlidableAction(
            onPressed: (_) => onEdit(),
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            icon: Icons.edit_rounded,
            label: 'Edit',
          ),
          SlidableAction(
            onPressed: (_) => onDelete(),
            backgroundColor: AppColors.expense,
            foregroundColor: Colors.white,
            icon: Icons.delete_rounded,
            label: 'Delete',
          ),
        ],
      ),
      child: InkWell(
        onTap: onEdit,
        child: Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              // Category icon
              CategoryIcon(
                iconName: isTransfer ? 'swap_horiz' : cat?.icon,
                colorHex: isTransfer ? '#6c5ce7' : cat?.color,
                size: 44,
                iconSize: 22,
              ),
              const SizedBox(width: 12),
              // Title + account
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isTransfer ? 'Transfer' : (cat?.name ?? 'Unknown'),
                      style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF1a1a2e)),
                    ),
                    const SizedBox(height: 2),
                    // Account row
                    Row(
                      children: [
                        const Icon(Icons.account_balance_wallet_rounded,
                            size: 12, color: Colors.grey),
                        const SizedBox(width: 3),
                        if (isTransfer && toAcc != null)
                          Text(
                            '${acc?.name ?? ''} → ${toAcc.name}',
                            style: GoogleFonts.inter(
                                fontSize: 11,
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.45)
                                    : Colors.black.withValues(alpha: 0.45)),
                          )
                        else
                          Text(
                            acc?.name ?? '',
                            style: GoogleFonts.inter(
                                fontSize: 11,
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.45)
                                    : Colors.black.withValues(alpha: 0.45)),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              // Amount
              Text(
                '$prefix$symbol${fmt.format(transaction.amount)}',
                style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: amountColor),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
