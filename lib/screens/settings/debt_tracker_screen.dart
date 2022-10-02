import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cashpilot/providers/debt_provider.dart';
import 'package:cashpilot/providers/settings_provider.dart';
import 'package:cashpilot/data/models/debt_model.dart';
import 'package:cashpilot/core/theme/app_colors.dart';
import 'package:cashpilot/widgets/empty_state.dart';

class DebtTrackerScreen extends StatefulWidget {
  const DebtTrackerScreen({super.key});

  @override
  State<DebtTrackerScreen> createState() => _DebtTrackerScreenState();
}

class _DebtTrackerScreenState extends State<DebtTrackerScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) =>
        context.read<DebtProvider>().loadDebts());
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final debtProvider = context.watch<DebtProvider>();
    final settings = context.watch<SettingsProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text('Debts & Loans',
            style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF1a1a2e))),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: () => _showAddDebt(context, debtProvider, settings),
          ),
        ],
      ),
      body: debtProvider.debts.isEmpty
          ? EmptyState(
              icon: Icons.credit_score_rounded,
              title: 'No debts tracked',
              subtitle: 'Track money you owe or are owed',
              actionLabel: 'Add Debt',
              onAction: () =>
                  _showAddDebt(context, debtProvider, settings),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _SummaryRow(
                  iOwe: debtProvider.totalOwed,
                  owedToMe: debtProvider.totalOwedToMe,
                  symbol: settings.currencySymbol,
                  isDark: isDark,
                ),
                const SizedBox(height: 16),
                ...debtProvider.debts.map((d) => _DebtCard(
                      debt: d,
                      symbol: settings.currencySymbol,
                      isDark: isDark,
                      onPay: () => _showPayment(context, d, debtProvider),
                      onDelete: () =>
                          debtProvider.deleteDebt(d.id),
                    )),
              ],
            ),
    );
  }

  Future<void> _showAddDebt(BuildContext context, DebtProvider provider,
      SettingsProvider settings) async {
    final nameCtrl = TextEditingController();
    final personCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    DebtType type = DebtType.owe;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: const Text('Add Debt'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Description')),
              const SizedBox(height: 12),
              TextField(
                  controller: personCtrl,
                  decoration: const InputDecoration(labelText: 'Person')),
              const SizedBox(height: 12),
              TextField(
                controller: amountCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                    labelText: 'Amount', prefixText: settings.currencySymbol),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<DebtType>(
                value: type,
                items: const [
                  DropdownMenuItem(value: DebtType.owe, child: Text('I Owe')),
                  DropdownMenuItem(value: DebtType.owed, child: Text('Owed to Me')),
                ],
                onChanged: (v) => setS(() => type = v ?? type),
                decoration: const InputDecoration(labelText: 'Type'),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                final amount = double.tryParse(amountCtrl.text);
                if (amount == null ||
                    nameCtrl.text.trim().isEmpty ||
                    personCtrl.text.trim().isEmpty) return;
                await provider.addDebt(DebtModel(
                  id: '',
                  name: nameCtrl.text.trim(),
                  type: type,
                  amount: amount,
                  person: personCtrl.text.trim(),
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

  Future<void> _showPayment(BuildContext context, DebtModel debt,
      DebtProvider provider) async {
    final amountCtrl = TextEditingController();
    final settings = context.read<SettingsProvider>();
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Record Payment'),
        content: TextField(
          controller: amountCtrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
              labelText: 'Amount Paid', prefixText: settings.currencySymbol),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final amount = double.tryParse(amountCtrl.text);
              if (amount == null) return;
              await provider.recordPayment(debt.id, amount);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Record'),
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final double iOwe;
  final double owedToMe;
  final String symbol;
  final bool isDark;

  const _SummaryRow(
      {required this.iOwe,
      required this.owedToMe,
      required this.symbol,
      required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _card('I Owe', '$symbol${iOwe.toStringAsFixed(2)}',
              AppColors.expense, isDark),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _card('Owed to Me',
              '$symbol${owedToMe.toStringAsFixed(2)}', AppColors.income, isDark),
        ),
      ],
    );
  }

  Widget _card(String label, String value, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(label,
              style: GoogleFonts.inter(
                  fontSize: 12, color: color, fontWeight: FontWeight.w500)),
          const SizedBox(height: 6),
          Text(value,
              style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF1a1a2e))),
        ],
      ),
    );
  }
}

class _DebtCard extends StatelessWidget {
  final DebtModel debt;
  final String symbol;
  final bool isDark;
  final VoidCallback onPay;
  final VoidCallback onDelete;

  const _DebtCard(
      {required this.debt,
      required this.symbol,
      required this.isDark,
      required this.onPay,
      required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final color =
        debt.type == DebtType.owe ? AppColors.expense : AppColors.income;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(debt.name,
                        style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w600)),
                    Text(debt.person,
                        style: GoogleFonts.inter(
                            fontSize: 12,
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.5)
                                : Colors.black.withValues(alpha: 0.5))),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$symbol${debt.remaining.toStringAsFixed(2)}',
                    style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: color),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      debt.type == DebtType.owe ? 'I Owe' : 'Owed',
                      style:
                          GoogleFonts.inter(fontSize: 10, color: color),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: debt.progress,
              backgroundColor: color.withValues(alpha: 0.1),
              valueColor: AlwaysStoppedAnimation(color),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              if (!debt.isSettled)
                TextButton.icon(
                  onPressed: onPay,
                  icon: const Icon(Icons.payment_rounded, size: 16),
                  label: const Text('Record Payment'),
                  style: TextButton.styleFrom(
                      foregroundColor: AppColors.income),
                ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded,
                    size: 18, color: AppColors.expense),
                onPressed: onDelete,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
