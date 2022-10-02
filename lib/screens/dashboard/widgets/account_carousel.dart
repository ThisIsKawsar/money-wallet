import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:animate_do/animate_do.dart';
import 'package:cashpilot/data/models/account_model.dart';

class AccountCarousel extends StatelessWidget {
  final List<AccountModel> accounts;
  final String currencySymbol;

  const AccountCarousel({
    super.key,
    required this.accounts,
    this.currencySymbol = '\$',
  });

  String _formatAmount(double amount) {
    final formatter = NumberFormat('#,##0.00', 'en_US');
    return '$currencySymbol${formatter.format(amount)}';
  }

  IconData _getAccountIcon(String? iconName) {
    switch (iconName) {
      case 'account_balance':
        return Icons.account_balance_rounded;
      case 'credit_card':
        return Icons.credit_card_rounded;
      case 'savings':
        return Icons.savings_rounded;
      case 'wallet':
        return Icons.account_balance_wallet_rounded;
      case 'attach_money':
        return Icons.attach_money_rounded;
      case 'money':
        return Icons.money_rounded;
      default:
        return Icons.account_balance_wallet_rounded;
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

    if (accounts.isEmpty) {
      return FadeInLeft(
        duration: const Duration(milliseconds: 500),
        child: Container(
          height: 130,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: isDark
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.grey.withValues(alpha: 0.08),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.05),
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.account_balance_wallet_outlined,
                  color: Colors.white.withValues(alpha: 0.3),
                  size: 32,
                ),
                const SizedBox(height: 8),
                Text(
                  'No accounts yet',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.4)
                        : Colors.black.withValues(alpha: 0.4),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return SizedBox(
      height: 130,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: accounts.length,
        itemBuilder: (context, index) {
          final account = accounts[index];
          final baseColor = _parseColor(account.color);
          final iconData = _getAccountIcon(account.icon);

          return FadeInLeft(
            duration: const Duration(milliseconds: 500),
            delay: Duration(milliseconds: 80 * index),
            child: Container(
              width: 180,
              margin: EdgeInsets.only(
                right: 14,
                left: index == 0 ? 0 : 0,
              ),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    baseColor.withValues(alpha: isDark ? 0.35 : 0.85),
                    baseColor.withValues(alpha: isDark ? 0.15 : 0.65),
                  ],
                ),
                border: Border.all(
                  color: baseColor.withValues(alpha: 0.2),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: baseColor.withValues(alpha: 0.2),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          iconData,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                      Text(
                        account.type.name.toUpperCase(),
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withValues(alpha: 0.7),
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        account.name,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withValues(alpha: 0.85),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatAmount(account.balance),
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: -0.3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
