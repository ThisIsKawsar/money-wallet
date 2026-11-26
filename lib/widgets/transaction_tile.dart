import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cashpilot/core/constants/app_icons.dart';
import 'package:cashpilot/core/theme/app_colors.dart';
import 'package:cashpilot/data/models/category_model.dart';
import 'package:cashpilot/data/models/transaction_model.dart';
import 'package:cashpilot/widgets/ui_kit.dart';

class TransactionTile extends StatelessWidget {
  final TransactionModel tx;
  final CategoryModel? category;
  final String currencySymbol;
  final bool showTime;
  final VoidCallback? onTap;

  const TransactionTile({
    super.key,
    required this.tx,
    required this.category,
    required this.currencySymbol,
    this.showTime = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isIncome = tx.type == TransactionType.income;
    final isTransfer = tx.type == TransactionType.transfer;
    final color = isTransfer
        ? AppColors.transfer
        : category != null
            ? AppColors.fromHex(category!.color)
            : AppColors.primary;
    final icon = isTransfer
        ? Icons.swap_horiz_rounded
        : category != null
            ? AppIcons.fromName(category!.icon)
            : Icons.receipt_long_rounded;
    final title = (tx.note?.trim().isNotEmpty ?? false)
        ? tx.note!.trim()
        : category?.name ?? (isTransfer ? 'Transfer' : 'Transaction');
    final date = showTime
        ? DateFormat('MMM d, hh:mm a').format(tx.date)
        : DateFormat('MMM d, yyyy').format(tx.date);

    return SoftCard(
      onTap: onTap,
      radius: 18,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      child: Row(
        children: [
          TintIcon(icon: icon, color: color, size: 46),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: jakarta(15,
                        weight: FontWeight.w600, color: context.textPrimary)),
                const SizedBox(height: 3),
                Text(date, style: jakarta(12, color: context.textTertiary)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${isIncome ? '+ ' : '- '}${fmtMoney(tx.amount, currencySymbol)}',
            style: jakarta(15,
                weight: FontWeight.w700,
                color: isIncome ? AppColors.income : AppColors.expense),
          ),
        ],
      ),
    );
  }
}
