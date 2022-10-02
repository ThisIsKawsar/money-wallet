import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:cashpilot/providers/settings_provider.dart';
import 'package:cashpilot/data/models/reminder_model.dart';
import 'package:cashpilot/core/theme/app_colors.dart';
import 'package:cashpilot/widgets/empty_state.dart';

class RemindersScreen extends StatefulWidget {
  const RemindersScreen({super.key});

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) =>
        context.read<SettingsProvider>().loadSettings());
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final settings = context.watch<SettingsProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text('Bill Reminders',
            style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF1a1a2e))),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: () => _showAddReminder(context, settings),
          ),
        ],
      ),
      body: settings.reminders.isEmpty
          ? EmptyState(
              icon: Icons.alarm_rounded,
              title: 'No reminders set',
              subtitle: 'Add bill reminders so you never miss a payment',
              actionLabel: 'Add Reminder',
              onAction: () => _showAddReminder(context, settings),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: settings.reminders.length,
              itemBuilder: (context, i) {
                final r = settings.reminders[i];
                return _ReminderCard(
                  reminder: r,
                  symbol: settings.currencySymbol,
                  isDark: isDark,
                  onPaid: () => settings.markReminderPaid(r.id),
                  onDelete: () => settings.deleteReminder(r.id),
                );
              },
            ),
    );
  }

  Future<void> _showAddReminder(
      BuildContext context, SettingsProvider settings) async {
    final titleCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    DateTime dueDate = DateTime.now().add(const Duration(days: 30));
    bool isRecurring = false;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: const Text('Add Reminder'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                  controller: titleCtrl,
                  decoration:
                      const InputDecoration(labelText: 'Bill Name')),
              const SizedBox(height: 12),
              TextField(
                controller: amountCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                    labelText: 'Amount',
                    prefixText: settings.currencySymbol),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Text('Monthly Recurring'),
                  const Spacer(),
                  Switch(
                    value: isRecurring,
                    onChanged: (v) => setS(() => isRecurring = v),
                  ),
                ],
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
                    titleCtrl.text.trim().isEmpty) return;
                await settings.addReminder(ReminderModel(
                  id: '',
                  title: titleCtrl.text.trim(),
                  amount: amount,
                  dueDate: dueDate,
                  isRecurring: isRecurring,
                  recurringFrequency:
                      isRecurring ? 'monthly' : null,
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
}

class _ReminderCard extends StatelessWidget {
  final ReminderModel reminder;
  final String symbol;
  final bool isDark;
  final VoidCallback onPaid;
  final VoidCallback onDelete;

  const _ReminderCard(
      {required this.reminder,
      required this.symbol,
      required this.isDark,
      required this.onPaid,
      required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final isOverdue = reminder.isOverdue;
    final color = reminder.isPaid
        ? AppColors.income
        : isOverdue
            ? AppColors.expense
            : AppColors.primary;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.alarm_rounded, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(reminder.title,
                    style: GoogleFonts.inter(
                        fontSize: 14, fontWeight: FontWeight.w600)),
                Text(
                  'Due: ${DateFormat('d MMM yyyy').format(reminder.dueDate)}',
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
                '$symbol${reminder.amount.toStringAsFixed(2)}',
                style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: color),
              ),
              if (!reminder.isPaid)
                GestureDetector(
                  onTap: onPaid,
                  child: Text('Mark Paid',
                      style: GoogleFonts.inter(
                          fontSize: 11,
                          color: AppColors.income,
                          fontWeight: FontWeight.w600)),
                )
              else
                Text('Paid',
                    style: GoogleFonts.inter(
                        fontSize: 11,
                        color: AppColors.income,
                        fontWeight: FontWeight.w600)),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 16),
            onPressed: onDelete,
            padding: const EdgeInsets.only(left: 8),
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}
