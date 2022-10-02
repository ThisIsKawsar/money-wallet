import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cashpilot/core/theme/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';

class MainShell extends StatelessWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  int _locationToIndex(String location) {
    if (location.startsWith('/transactions')) return 1;
    if (location.startsWith('/analytics')) return 2;
    if (location.startsWith('/budgets')) return 3;
    if (location.startsWith('/settings')) return 4;
    return 0;
  }

  void _onTap(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/');
      case 1:
        context.go('/transactions');
      case 2:
        context.go('/analytics');
      case 3:
        context.go('/budgets');
      case 4:
        context.go('/settings');
    }
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final currentIndex = _locationToIndex(location);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: child,
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/add-transaction'),
        backgroundColor: AppColors.primary,
        elevation: 6,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: _BottomNav(
        currentIndex: currentIndex,
        isDark: isDark,
        onTap: (i) => _onTap(context, i),
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  final int currentIndex;
  final bool isDark;
  final void Function(int) onTap;

  const _BottomNav({
    required this.currentIndex,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      elevation: 0,
      notchMargin: 8,
      shape: const CircularNotchedRectangle(),
      child: SizedBox(
        height: 60,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _NavItem(icon: Icons.home_rounded, label: 'Home', index: 0, currentIndex: currentIndex, isDark: isDark, onTap: onTap),
            _NavItem(icon: Icons.receipt_long_rounded, label: 'Transactions', index: 1, currentIndex: currentIndex, isDark: isDark, onTap: onTap),
            const SizedBox(width: 56),
            _NavItem(icon: Icons.bar_chart_rounded, label: 'Analytics', index: 2, currentIndex: currentIndex, isDark: isDark, onTap: onTap),
            _NavItem(icon: Icons.pie_chart_rounded, label: 'Budgets', index: 3, currentIndex: currentIndex, isDark: isDark, onTap: onTap),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final int index;
  final int currentIndex;
  final bool isDark;
  final void Function(int) onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.index,
    required this.currentIndex,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = index == currentIndex;
    final color = isSelected
        ? AppColors.primary
        : isDark
            ? AppColors.darkTextTertiary
            : AppColors.lightTextTertiary;

    return InkWell(
      onTap: () => onTap(index),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
