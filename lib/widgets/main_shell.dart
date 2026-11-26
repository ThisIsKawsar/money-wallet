import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cashpilot/core/theme/app_colors.dart';
import 'package:cashpilot/core/constants/app_constants.dart';
import 'package:cashpilot/widgets/app_drawer.dart';
import 'package:cashpilot/widgets/cashpilot_logo.dart';

class MainShell extends StatelessWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  int _locationToIndex(String location) {
    if (location.startsWith('/records')) return 0;
    if (location.startsWith('/analytics')) return 1;
    if (location.startsWith('/budgets')) return 3;
    if (location.startsWith('/accounts')) return 4;
    return 2; // Home ('/') is center tab
  }

  void _onTap(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/records');
      case 1:
        context.go('/analytics');
      case 2:
        context.go('/');
      case 3:
        context.go('/budgets');
      case 4:
        context.go('/accounts');
    }
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final currentIndex = _locationToIndex(location);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: const Icon(Icons.menu_rounded, size: 24),
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
        centerTitle: false,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CashPilotLogo(size: 24),
            const SizedBox(width: 8),
            Text(
              AppConstants.appName,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : AppColors.lightTextPrimary,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded, size: 24),
            onPressed: () => context.push('/transactions'),
            tooltip: 'Search records',
          ),
        ],
      ),
      body: child,
      floatingActionButton: Container(
        width: 54,
        height: 54,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: AppColors.primaryGradient,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.35),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: () => context.push('/add-transaction'),
          backgroundColor: Colors.transparent,
          elevation: 0,
          highlightElevation: 0,
          shape: const CircleBorder(),
          child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
        ),
      ),
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
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            width: 0.8,
          ),
        ),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 14,
                  offset: const Offset(0, -3),
                ),
              ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 62,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                icon: Icons.receipt_long_outlined,
                activeIcon: Icons.receipt_long_rounded,
                label: 'Records',
                index: 0,
                currentIndex: currentIndex,
                isDark: isDark,
                onTap: onTap,
              ),
              _NavItem(
                icon: Icons.pie_chart_outline_rounded,
                activeIcon: Icons.pie_chart_rounded,
                label: 'Analysis',
                index: 1,
                currentIndex: currentIndex,
                isDark: isDark,
                onTap: onTap,
              ),
              _NavItem(
                icon: Icons.home_outlined,
                activeIcon: Icons.home_rounded,
                label: 'Home',
                index: 2,
                currentIndex: currentIndex,
                isDark: isDark,
                onTap: onTap,
              ),
              _NavItem(
                icon: Icons.calculate_outlined,
                activeIcon: Icons.calculate_rounded,
                label: 'Budgets',
                index: 3,
                currentIndex: currentIndex,
                isDark: isDark,
                onTap: onTap,
              ),
              _NavItem(
                icon: Icons.account_balance_wallet_outlined,
                activeIcon: Icons.account_balance_wallet_rounded,
                label: 'Accounts',
                index: 4,
                currentIndex: currentIndex,
                isDark: isDark,
                onTap: onTap,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final int index;
  final int currentIndex;
  final bool isDark;
  final void Function(int) onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
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
            : AppColors.lightTextSecondary;

    return InkWell(
      onTap: () => onTap(index),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(isSelected ? activeIcon : icon, color: color, size: 22),
            const SizedBox(height: 3),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10.5,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
