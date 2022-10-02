import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';

class QuickActions extends StatelessWidget {
  final VoidCallback? onAddIncome;
  final VoidCallback? onAddExpense;
  final VoidCallback? onTransfer;
  final VoidCallback? onBudget;

  const QuickActions({
    super.key,
    this.onAddIncome,
    this.onAddExpense,
    this.onTransfer,
    this.onBudget,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final actions = [
      _QuickActionData(
        icon: Icons.arrow_upward_rounded,
        label: 'Income',
        gradientColors: [const Color(0xFF00d4aa), const Color(0xFF00b894)],
        onTap: onAddIncome,
      ),
      _QuickActionData(
        icon: Icons.arrow_downward_rounded,
        label: 'Expense',
        gradientColors: [const Color(0xFFff6b6b), const Color(0xFFee5a24)],
        onTap: onAddExpense,
      ),
      _QuickActionData(
        icon: Icons.swap_horiz_rounded,
        label: 'Transfer',
        gradientColors: [const Color(0xFF6c5ce7), const Color(0xFFa29bfe)],
        onTap: onTransfer,
      ),
      _QuickActionData(
        icon: Icons.pie_chart_rounded,
        label: 'Budget',
        gradientColors: [const Color(0xFF4facfe), const Color(0xFF00f2fe)],
        onTap: onBudget,
      ),
    ];

    return FadeInUp(
      duration: const Duration(milliseconds: 600),
      delay: const Duration(milliseconds: 200),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.85,
        ),
        itemCount: actions.length,
        itemBuilder: (context, index) {
          final action = actions[index];
          return _QuickActionButton(
            data: action,
            isDark: isDark,
            delay: index * 60,
          );
        },
      ),
    );
  }
}

class _QuickActionData {
  final IconData icon;
  final String label;
  final List<Color> gradientColors;
  final VoidCallback? onTap;

  const _QuickActionData({
    required this.icon,
    required this.label,
    required this.gradientColors,
    this.onTap,
  });
}

class _QuickActionButton extends StatelessWidget {
  final _QuickActionData data;
  final bool isDark;
  final int delay;

  const _QuickActionButton({
    required this.data,
    required this.isDark,
    required this.delay,
  });

  @override
  Widget build(BuildContext context) {
    return FadeInUp(
      duration: const Duration(milliseconds: 400),
      delay: Duration(milliseconds: delay),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: data.onTap,
          borderRadius: BorderRadius.circular(18),
          splashColor: data.gradientColors[0].withValues(alpha: 0.2),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              color: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.grey.withValues(alpha: 0.06),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : Colors.grey.withValues(alpha: 0.1),
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: data.gradientColors,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: data.gradientColors[0].withValues(alpha: 0.35),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    data.icon,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  data.label,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.8)
                        : Colors.black.withValues(alpha: 0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
