import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:cashpilot/providers/transaction_provider.dart';
import 'package:cashpilot/providers/category_provider.dart';
import 'package:cashpilot/providers/account_provider.dart';
import 'package:cashpilot/providers/settings_provider.dart';
import 'package:cashpilot/data/models/transaction_model.dart';
import 'package:cashpilot/core/theme/app_colors.dart';
import 'package:cashpilot/widgets/wavy_background.dart';
import 'package:cashpilot/widgets/ui_kit.dart';
import 'package:cashpilot/widgets/transaction_tile.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  static const _filters = [null, TransactionType.income, TransactionType.expense, TransactionType.transfer];
  int _filter = 0;
  bool _searching = false;
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TransactionProvider>().loadTransactions();
      context.read<CategoryProvider>().loadCategories();
      context.read<AccountProvider>().loadAccounts();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _delete(TransactionModel tx) async {
    final accp = context.read<AccountProvider>();
    final txp = context.read<TransactionProvider>();
    await accp.applyTransaction(tx, revert: true);
    await txp.deleteTransaction(tx.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Text('Transaction deleted', style: jakarta(14, weight: FontWeight.w600, color: Colors.white)),
        action: SnackBarAction(
          label: 'UNDO',
          textColor: AppColors.accent,
          onPressed: () async {
            await txp.addTransaction(tx);
            await accp.applyTransaction(tx);
          },
        ),
      ));
  }

  @override
  Widget build(BuildContext context) {
    final txp = context.watch<TransactionProvider>();
    final catp = context.watch<CategoryProvider>();
    final symbol = context.watch<SettingsProvider>().currencySymbol;
    final q = _searchCtrl.text.trim().toLowerCase();
    final type = _filters[_filter];

    final list = txp.transactions.where((t) {
      if (type != null && t.type != type) return false;
      if (q.isEmpty) return true;
      final cat = catp.getCategoryById(t.categoryId)?.name.toLowerCase() ?? '';
      return (t.note?.toLowerCase().contains(q) ?? false) ||
          cat.contains(q) ||
          t.amount.toStringAsFixed(2).contains(q);
    }).toList();

    // Group by month
    final groups = <String, List<TransactionModel>>{};
    for (final t in list) {
      groups.putIfAbsent(DateFormat('MMMM yyyy').format(t.date), () => []).add(t);
    }

    return Scaffold(
      body: WavyBackground(
        child: SafeArea(
          child: Column(
            children: [
              ScreenHeader(
                title: 'Transactions',
                                trailing: IconButton(
                  icon: Icon(_searching ? Icons.close_rounded : Icons.search_rounded, color: context.textPrimary),
                  onPressed: () => setState(() {
                    _searching = !_searching;
                    if (!_searching) _searchCtrl.clear();
                  }),
                ),
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 220),
                child: _searching
                    ? Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                        child: AppTextField(
                          controller: _searchCtrl,
                          hint: 'Search notes, categories, amounts',
                          icon: Icons.search_rounded,
                          autofocus: true,
                          onChanged: (_) => setState(() {}),
                        ),
                      )
                    : const SizedBox(width: double.infinity),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: PillTabs(
                  labels: const ['All', 'Income', 'Expense', 'Transfer'],
                  index: _filter,
                  height: 36,
                  onChanged: (i) => setState(() => _filter = i),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: list.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            GlossyIcon(icon: Icons.search_off_rounded, color: AppColors.primary, size: 64),
                            const SizedBox(height: 16),
                            Text(q.isEmpty ? 'No transactions yet' : 'No matches',
                                style: jakarta(16, weight: FontWeight.w700, color: context.textPrimary)),
                            const SizedBox(height: 4),
                            Text(q.isEmpty ? 'Tap + to add one' : 'Try a different search',
                                style: jakarta(13, color: context.textSecondary)),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        color: AppColors.primary,
                        onRefresh: () => context.read<TransactionProvider>().loadTransactions(),
                        child: ListView(
                          padding: const EdgeInsets.fromLTRB(20, 4, 20, 40),
                          children: [
                            for (final entry in groups.entries) ...[
                              Padding(
                                padding: const EdgeInsets.fromLTRB(2, 12, 2, 10),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(entry.key,
                                          style: jakarta(16, weight: FontWeight.w700, color: context.textPrimary)),
                                    ),
                                    _MonthNet(txs: entry.value, symbol: symbol),
                                  ],
                                ),
                              ),
                              for (final tx in entry.value)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: Slidable(
                                    key: ValueKey(tx.id),
                                    endActionPane: ActionPane(
                                      motion: const DrawerMotion(),
                                      extentRatio: 0.26,
                                      children: [
                                        SlidableAction(
                                          onPressed: (_) => _delete(tx),
                                          backgroundColor: AppColors.expense,
                                          foregroundColor: Colors.white,
                                          icon: Icons.delete_outline_rounded,
                                          label: 'Delete',
                                          borderRadius: BorderRadius.circular(18),
                                        ),
                                      ],
                                    ),
                                    child: TransactionTile(
                                      tx: tx,
                                      category: catp.getCategoryById(tx.categoryId),
                                      currencySymbol: symbol,
                                      showTime: true,
                                      onTap: () => context.push('/add-transaction', extra: {'transaction': tx}),
                                    ),
                                  ),
                                ),
                            ],
                          ],
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MonthNet extends StatelessWidget {
  final List<TransactionModel> txs;
  final String symbol;
  const _MonthNet({required this.txs, required this.symbol});

  @override
  Widget build(BuildContext context) {
    double net = 0;
    for (final t in txs) {
      if (t.type == TransactionType.income) net += t.amount;
      if (t.type == TransactionType.expense) net -= t.amount;
    }
    final c = net >= 0 ? AppColors.income : AppColors.expense;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: c.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
      child: Text('${net >= 0 ? '+' : ''}${fmtMoney(net, symbol)}',
          style: jakarta(12, weight: FontWeight.w700, color: c)),
    );
  }
}
