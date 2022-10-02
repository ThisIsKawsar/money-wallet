import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:animate_do/animate_do.dart';
import 'package:cashpilot/core/theme/app_colors.dart';

class BalanceCard extends StatelessWidget {
  final double totalBalance;
  final double totalIncome;
  final double totalExpense;
  final String currencySymbol;

  const BalanceCard({
    super.key,
    required this.totalBalance,
    required this.totalIncome,
    required this.totalExpense,
    this.currencySymbol = '\$',
  });

  String _formatAmount(double amount) {
    final formatter = NumberFormat('#,##0.00', 'en_US');
    return '$currencySymbol${formatter.format(amount.abs())}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return FadeInUp(
      duration: const Duration(milliseconds: 600),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
                    const Color(0xFF1E1E1E),
                    const Color(0xFF2C2C2C),
                  ]
                : [
                    AppColors.primary,
                    AppColors.primaryLight,
                  ],
          ),
          border: Border.all(
            color: Colors.white.withValues(alpha: isDark ? 0.1 : 0.2),
            width: 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: isDark ? 0.2 : 0.25),
              blurRadius: 20,
              offset: const Offset(0, 8),
              spreadRadius: 0,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total Balance',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withValues(alpha: 0.7),
                        letterSpacing: 0.5,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.trending_up_rounded,
                            color: AppColors.income,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'This Month',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: Colors.white.withValues(alpha: 0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0, end: totalBalance),
                  duration: const Duration(milliseconds: 1200),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, child) {
                    return Text(
                      _formatAmount(value),
                      style: GoogleFonts.inter(
                        fontSize: 36,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: -0.5,
                        height: 1.2,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _IncomeExpenseItem(
                          icon: Icons.arrow_upward_rounded,
                          label: 'Income',
                          amount: totalIncome,
                          color: AppColors.income,
                          currencySymbol: currencySymbol,
                        ),
                      ),
                      Container(
                        height: 40,
                        width: 1,
                        color: Colors.white.withValues(alpha: 0.15),
                      ),
                      Expanded(
                        child: _IncomeExpenseItem(
                          icon: Icons.arrow_downward_rounded,
                          label: 'Expense',
                          amount: totalExpense,
                          color: AppColors.expense,
                          currencySymbol: currencySymbol,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _IncomeExpenseItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final double amount;
  final Color color;
  final String currencySymbol;

  const _IncomeExpenseItem({
    required this.icon,
    required this.label,
    required this.amount,
    required this.color,
    required this.currencySymbol,
  });

  String _formatAmount(double amount) {
    final formatter = NumberFormat('#,##0.00', 'en_US');
    return '$currencySymbol${formatter.format(amount.abs())}';
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: color,
            size: 16,
          ),
        ),
        const SizedBox(width: 10),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 2),
              TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0, end: amount),
                duration: const Duration(milliseconds: 1000),
                curve: Curves.easeOutCubic,
                builder: (context, value, child) {
                  return Text(
                    _formatAmount(value),
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                    overflow: TextOverflow.ellipsis,
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}
