import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:cashpilot/core/theme/app_colors.dart';
import 'package:cashpilot/providers/settings_provider.dart';

class PeriodHelpers {
  static DateTime defaultAnchor(String viewMode) {
    final now = DateTime.now();
    switch (viewMode) {
      case 'daily':
        return DateTime(now.year, now.month, now.day);
      case 'weekly':
        final w = now.subtract(Duration(days: now.weekday - 1));
        return DateTime(w.year, w.month, w.day);
      case '3months':
        final qMonth = ((now.month - 1) ~/ 3) * 3 + 1;
        return DateTime(now.year, qMonth, 1);
      case '6months':
        final hMonth = now.month <= 6 ? 1 : 7;
        return DateTime(now.year, hMonth, 1);
      case 'yearly':
        return DateTime(now.year, 1, 1);
      default:
        return DateTime(now.year, now.month, 1);
    }
  }

  static DateTimeRange range(DateTime anchor, String viewMode) {
    switch (viewMode) {
      case 'daily':
        return DateTimeRange(
          start: anchor,
          end: anchor.add(const Duration(days: 1)),
        );
      case 'weekly':
        return DateTimeRange(
          start: anchor,
          end: anchor.add(const Duration(days: 7)),
        );
      case '3months':
        return DateTimeRange(
          start: anchor,
          end: DateTime(anchor.year, anchor.month + 3, 1),
        );
      case '6months':
        return DateTimeRange(
          start: anchor,
          end: DateTime(anchor.year, anchor.month + 6, 1),
        );
      case 'yearly':
        return DateTimeRange(
          start: anchor,
          end: DateTime(anchor.year + 1, 1, 1),
        );
      default:
        return DateTimeRange(
          start: anchor,
          end: DateTime(anchor.year, anchor.month + 1, 1),
        );
    }
  }

  static DateTime prev(DateTime anchor, String viewMode) {
    switch (viewMode) {
      case 'daily':
        return anchor.subtract(const Duration(days: 1));
      case 'weekly':
        return anchor.subtract(const Duration(days: 7));
      case '3months':
        return DateTime(anchor.year, anchor.month - 3, 1);
      case '6months':
        return DateTime(anchor.year, anchor.month - 6, 1);
      case 'yearly':
        return DateTime(anchor.year - 1, 1, 1);
      default:
        return DateTime(anchor.year, anchor.month - 1, 1);
    }
  }

  static DateTime next(DateTime anchor, String viewMode) {
    switch (viewMode) {
      case 'daily':
        return anchor.add(const Duration(days: 1));
      case 'weekly':
        return anchor.add(const Duration(days: 7));
      case '3months':
        return DateTime(anchor.year, anchor.month + 3, 1);
      case '6months':
        return DateTime(anchor.year, anchor.month + 6, 1);
      case 'yearly':
        return DateTime(anchor.year + 1, 1, 1);
      default:
        return DateTime(anchor.year, anchor.month + 1, 1);
    }
  }

  static String label(DateTime anchor, String viewMode) {
    switch (viewMode) {
      case 'daily':
        return DateFormat('MMM d, EEEE').format(anchor);
      case 'weekly':
        final end = anchor.add(const Duration(days: 6));
        return '${DateFormat('MMM d').format(anchor)} - ${DateFormat('MMM d, yyyy').format(end)}';
      case '3months':
        final end = DateTime(anchor.year, anchor.month + 2, 1);
        return '${DateFormat('MMM').format(anchor)} - ${DateFormat('MMM yyyy').format(end)}';
      case '6months':
        final end = DateTime(anchor.year, anchor.month + 5, 1);
        return '${DateFormat('MMM').format(anchor)} - ${DateFormat('MMM yyyy').format(end)}';
      case 'yearly':
        return '${anchor.year}';
      default:
        return DateFormat('MMMM, yyyy').format(anchor);
    }
  }
}

class PeriodSummaryBar extends StatelessWidget {
  final DateTime anchor;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final double expense;
  final double income;
  final double total;
  final String currencySymbol;
  final bool showFilterButton;
  final VoidCallback? onPeriodModeChanged;

  const PeriodSummaryBar({
    super.key,
    required this.anchor,
    required this.onPrev,
    required this.onNext,
    required this.expense,
    required this.income,
    required this.total,
    required this.currencySymbol,
    this.showFilterButton = true,
    this.onPeriodModeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final fmt = NumberFormat('#,##0.00', 'en_US');

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 10),
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: AppColors.primaryGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.25),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: onPrev,
                icon: const Icon(Icons.chevron_left_rounded, color: Colors.white),
                visualDensity: VisualDensity.compact,
              ),
              Expanded(
                child: Text(
                  PeriodHelpers.label(anchor, settings.filterPeriod),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
              IconButton(
                onPressed: onNext,
                icon: const Icon(Icons.chevron_right_rounded, color: Colors.white),
                visualDensity: VisualDensity.compact,
              ),
              if (showFilterButton)
                IconButton(
                  onPressed: () async {
                    await showDisplayOptionsDialog(context);
                    onPeriodModeChanged?.call();
                  },
                  icon: const Icon(
                    Icons.filter_list_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                  visualDensity: VisualDensity.compact,
                  tooltip: 'Display options',
                ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _StatCol(
                    label: 'EXPENSE',
                    value: '-$currencySymbol${fmt.format(expense)}',
                  ),
                ),
                Container(
                  width: 1,
                  height: 28,
                  color: Colors.white.withValues(alpha: 0.24),
                ),
                Expanded(
                  child: _StatCol(
                    label: 'INCOME',
                    value: '$currencySymbol${fmt.format(income)}',
                  ),
                ),
                Container(
                  width: 1,
                  height: 28,
                  color: Colors.white.withValues(alpha: 0.24),
                ),
                Expanded(
                  child: _StatCol(
                    label: 'TOTAL',
                    value:
                        '${total < 0 ? '-' : ''}$currencySymbol${fmt.format(total.abs())}',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCol extends StatelessWidget {
  final String label;
  final String value;

  const _StatCol({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
            color: Colors.white.withValues(alpha: 0.8),
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

Future<void> showDisplayOptionsDialog(BuildContext context) async {
  final settings = context.read<SettingsProvider>();
  String viewMode = settings.filterPeriod;

  const modes = [
    ('daily', 'DAILY'),
    ('weekly', 'WEEKLY'),
    ('monthly', 'MONTHLY'),
    ('3months', '3 MONTHS'),
    ('6months', '6 MONTHS'),
    ('yearly', 'YEARLY'),
  ];

  await showDialog(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setS) => AlertDialog(
        title: Center(
          child: Text(
            'Display options',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        content: SingleChildScrollView(
          child: _OptionRow(
            label: 'View mode:',
            children: modes.map((m) {
              final selected = viewMode == m.$1;
              return _CheckChoice(
                text: m.$2,
                selected: selected,
                onTap: () => setS(() => viewMode = m.$1),
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await settings.setDisplayOptions(viewMode: viewMode);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Apply'),
          ),
        ],
      ),
    ),
  );
}

class _OptionRow extends StatelessWidget {
  final String label;
  final List<Widget> children;

  const _OptionRow({required this.label, required this.children});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 94,
          child: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children,
          ),
        ),
      ],
    );
  }
}

class _CheckChoice extends StatelessWidget {
  final String text;
  final bool selected;
  final VoidCallback onTap;

  const _CheckChoice({
    required this.text,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 4),
        child: Row(
          children: [
            SizedBox(
              width: 22,
              child: selected
                  ? Icon(Icons.check_rounded,
                      size: 18, color: AppColors.primary)
                  : null,
            ),
            const SizedBox(width: 6),
            Text(
              text,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected
                    ? AppColors.primary
                    : Theme.of(context).textTheme.bodyMedium?.color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
