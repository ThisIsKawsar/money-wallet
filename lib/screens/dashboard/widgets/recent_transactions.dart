import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:animate_do/animate_do.dart';
import 'package:cashpilot/data/models/transaction_model.dart';
import 'package:cashpilot/data/models/category_model.dart';

class RecentTransactions extends StatelessWidget {
  final List<TransactionModel> transactions;
  final List<CategoryModel> categories;
  final String currencySymbol;
  final VoidCallback? onSeeAll;

  const RecentTransactions({
    super.key,
    required this.transactions,
    required this.categories,
    this.currencySymbol = '\$',
    this.onSeeAll,
  });

  CategoryModel? _getCategoryById(String? categoryId) {
    if (categoryId == null) return null;
    try {
      return categories.firstWhere((c) => c.id == categoryId);
    } catch (_) {
      return null;
    }
  }

  String _formatAmount(double amount) {
    final formatter = NumberFormat('#,##0.00', 'en_US');
    return '$currencySymbol${formatter.format(amount.abs())}';
  }

  String _getRelativeDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateOnly = DateTime(date.year, date.month, date.day);
    final difference = today.difference(dateOnly).inDays;

    if (difference == 0) return 'Today';
    if (difference == 1) return 'Yesterday';
    if (difference < 7) return '${difference}d ago';
    if (difference < 30) return '${(difference / 7).floor()}w ago';
    return DateFormat('MMM d').format(date);
  }

  IconData _parseIcon(String? iconName) {
    switch (iconName) {
      case 'restaurant':
        return Icons.restaurant_rounded;
      case 'shopping_cart':
        return Icons.shopping_cart_rounded;
      case 'directions_car':
        return Icons.directions_car_rounded;
      case 'home':
        return Icons.home_rounded;
      case 'local_hospital':
        return Icons.local_hospital_rounded;
      case 'school':
        return Icons.school_rounded;
      case 'flight':
        return Icons.flight_rounded;
      case 'movie':
        return Icons.movie_rounded;
      case 'fitness_center':
        return Icons.fitness_center_rounded;
      case 'pets':
        return Icons.pets_rounded;
      case 'work':
        return Icons.work_rounded;
      case 'attach_money':
        return Icons.attach_money_rounded;
      case 'card_giftcard':
        return Icons.card_giftcard_rounded;
      case 'savings':
        return Icons.savings_rounded;
      case 'business':
        return Icons.business_rounded;
      case 'trending_up':
        return Icons.trending_up_rounded;
      default:
        return Icons.receipt_long_rounded;
    }
  }

  Color _parseColor(String? colorStr) {
    if (colorStr == null || colorStr.isEmpty) return const Color(0xFF4facfe);
    try {
      final hex = colorStr.replaceFirst('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      return const Color(0xFF4facfe);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final recentTx = transactions.take(5).toList();

    return FadeInUp(
      duration: const Duration(milliseconds: 600),
      delay: const Duration(milliseconds: 400),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Transactions',
                style: GoogleFonts.inter(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF1a1a2e),
                ),
              ),
              if (transactions.isNotEmpty)
                GestureDetector(
                  onTap: onSeeAll,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4facfe).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'See All',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF4facfe),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (recentTx.isEmpty) _buildEmptyState(isDark) else _buildList(recentTx, isDark),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.04)
            : Colors.grey.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.grey.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 48,
            color: isDark
                ? Colors.white.withValues(alpha: 0.2)
                : Colors.black.withValues(alpha: 0.2),
          ),
          const SizedBox(height: 12),
          Text(
            'No transactions yet',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.4)
                  : Colors.black.withValues(alpha: 0.4),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Start by adding your first transaction',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.25)
                  : Colors.black.withValues(alpha: 0.25),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList(List<TransactionModel> recentTx, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.04)
            : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.grey.withValues(alpha: 0.1),
        ),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: recentTx.length,
        separatorBuilder: (context, index) => Divider(
          height: 1,
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.grey.withValues(alpha: 0.1),
          indent: 68,
        ),
        itemBuilder: (context, index) {
          final tx = recentTx[index];
          return _TransactionItem(
            transaction: tx,
            category: _getCategoryById(tx.categoryId),
            isDark: isDark,
            currencySymbol: currencySymbol,
            formatAmount: _formatAmount,
            getRelativeDate: _getRelativeDate,
            parseIcon: _parseIcon,
            parseColor: _parseColor,
            delay: index * 60,
          );
        },
      ),
    );
  }
}

class _TransactionItem extends StatelessWidget {
  final TransactionModel transaction;
  final CategoryModel? category;
  final bool isDark;
  final String currencySymbol;
  final String Function(double) formatAmount;
  final String Function(DateTime) getRelativeDate;
  final IconData Function(String?) parseIcon;
  final Color Function(String?) parseColor;
  final int delay;

  const _TransactionItem({
    required this.transaction,
    required this.category,
    required this.isDark,
    required this.currencySymbol,
    required this.formatAmount,
    required this.getRelativeDate,
    required this.parseIcon,
    required this.parseColor,
    required this.delay,
  });

  @override
  Widget build(BuildContext context) {
    final isIncome = transaction.type == TransactionType.income;
    final isTransfer = transaction.type == TransactionType.transfer;
    final amountColor = isTransfer
        ? const Color(0xFF6c5ce7)
        : isIncome
            ? const Color(0xFF00d4aa)
            : const Color(0xFFff6b6b);
    final prefix = isIncome ? '+' : '-';
    final categoryColor = category != null
        ? parseColor(category!.color)
        : const Color(0xFF4facfe);
    final categoryIcon = category != null
        ? parseIcon(category!.icon)
        : Icons.receipt_long_rounded;
    final categoryName = category?.name ?? (isTransfer ? 'Transfer' : 'Unknown');

    return FadeInLeft(
      duration: const Duration(milliseconds: 400),
      delay: Duration(milliseconds: delay),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: categoryColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                categoryIcon,
                color: categoryColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    categoryName,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : const Color(0xFF1a1a2e),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    transaction.note?.isNotEmpty == true
                        ? transaction.note!
                        : getRelativeDate(transaction.date),
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.45)
                          : Colors.black.withValues(alpha: 0.45),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$prefix${formatAmount(transaction.amount)}',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: amountColor,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  getRelativeDate(transaction.date),
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.35)
                        : Colors.black.withValues(alpha: 0.35),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
