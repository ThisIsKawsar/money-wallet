import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:intl/intl.dart';
import 'package:cashpilot/providers/goal_provider.dart';
import 'package:cashpilot/providers/settings_provider.dart';
import 'package:cashpilot/core/theme/app_colors.dart';

class SavingsGoals extends StatelessWidget {
  const SavingsGoals({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final goalProvider = context.watch<GoalProvider>();
    final settings = context.watch<SettingsProvider>();
    
    final activeGoals = goalProvider.activeGoals.take(3).toList();

    if (activeGoals.isEmpty) {
      return const SizedBox.shrink();
    }

    return FadeInUp(
      duration: const Duration(milliseconds: 600),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Savings Goals',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF1a1a2e),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${goalProvider.activeGoals.length} Active',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...activeGoals.map((goal) => _GoalCard(
            goal: goal,
            currencySymbol: settings.currencySymbol,
            isDark: isDark,
          )),
        ],
      ),
    );
  }
}

class _GoalCard extends StatelessWidget {
  final dynamic goal;
  final String currencySymbol;
  final bool isDark;

  const _GoalCard({
    required this.goal,
    required this.currencySymbol,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final progress = goal.progress;
    final remaining = goal.targetAmount - goal.currentAmount;
    final isCompleted = goal.isCompleted;
    
    final color = isCompleted 
        ? AppColors.income 
        : progress >= 0.8 
            ? const Color(0xFFfdcb6e) 
            : AppColors.primary;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getIcon(goal.icon),
                  color: color,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      goal.name,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : const Color(0xFF1a1a2e),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$currencySymbol${goal.currentAmount.toStringAsFixed(2)} of $currencySymbol${goal.targetAmount.toStringAsFixed(2)}',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: isDark 
                            ? Colors.white.withValues(alpha: 0.5) 
                            : Colors.black.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${(progress * 100).toStringAsFixed(0)}%',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                  Text(
                    isCompleted ? 'Done!' : '$currencySymbol${remaining.toStringAsFixed(0)} left',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: isCompleted 
                          ? AppColors.income 
                          : isDark 
                              ? Colors.white.withValues(alpha: 0.5) 
                              : Colors.black.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: color.withValues(alpha: 0.12),
              valueColor: AlwaysStoppedAnimation(color),
              minHeight: 8,
            ),
          ),
          if (goal.deadline != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.calendar_today_rounded,
                  size: 12,
                  color: isDark 
                      ? Colors.white.withValues(alpha: 0.4) 
                      : Colors.black.withValues(alpha: 0.4),
                ),
                const SizedBox(width: 4),
                Text(
                  'Target: ${DateFormat('MMM d, yyyy').format(goal.deadline)}',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: isDark 
                        ? Colors.white.withValues(alpha: 0.4) 
                        : Colors.black.withValues(alpha: 0.4),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  IconData _getIcon(String? iconName) {
    switch (iconName) {
      case 'home': return Icons.home_rounded;
      case 'car': return Icons.directions_car_rounded;
      case 'vacation': return Icons.flight_rounded;
      case 'education': return Icons.school_rounded;
      case 'emergency': return Icons.medical_services_rounded;
      case 'gift': return Icons.card_giftcard_rounded;
      case 'shopping': return Icons.shopping_bag_rounded;
      case 'electronics': return Icons.devices_rounded;
      default: return Icons.savings_rounded;
    }
  }
}
