import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cashpilot/core/theme/app_colors.dart';
import 'package:cashpilot/providers/settings_provider.dart';
import 'package:cashpilot/widgets/wavy_background.dart';

class AppearanceScreen extends StatefulWidget {
  const AppearanceScreen({super.key});

  @override
  State<AppearanceScreen> createState() => _AppearanceScreenState();
}

class _AppearanceScreenState extends State<AppearanceScreen> {
  late ThemeMode _selectedMode;
  late int _selectedAccent;

  @override
  void initState() {
    super.initState();
    final settings = context.read<SettingsProvider>();
    _selectedMode = settings.themeMode;
    _selectedAccent = settings.accentIndex;
  }

  Future<void> _apply() async {
    await context.read<SettingsProvider>().setAppearance(_selectedMode, _selectedAccent);
    if (!mounted) return;
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeColor = SettingsProvider.accentPalette[_selectedAccent];

    return Scaffold(
      body: WavyBackground(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_rounded, size: 24),
                      onPressed: () => context.pop(),
                    ),
                    Expanded(
                      child: Text(
                        'Appearance',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : AppColors.lightTextPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                  children: [
                    _ThemeOptionCard(
                      icon: Icons.wb_sunny_rounded,
                      iconColor: const Color(0xFFF39C12),
                      iconBg: const Color(0xFFFFF4E0),
                      title: 'Light Mode',
                      selected: _selectedMode == ThemeMode.light,
                      activeColor: activeColor,
                      isDark: isDark,
                      onTap: () => setState(() => _selectedMode = ThemeMode.light),
                    ),
                    const SizedBox(height: 12),
                    _ThemeOptionCard(
                      icon: Icons.nightlight_round,
                      iconColor: const Color(0xFF2F80ED),
                      iconBg: const Color(0xFFEAF2FD),
                      title: 'Dark Mode',
                      selected: _selectedMode == ThemeMode.dark,
                      activeColor: activeColor,
                      isDark: isDark,
                      onTap: () => setState(() => _selectedMode = ThemeMode.dark),
                    ),
                    const SizedBox(height: 12),
                    _ThemeOptionCard(
                      icon: Icons.settings_rounded,
                      iconColor: AppColors.primary,
                      iconBg: AppColors.mintSoft,
                      title: 'System Mode',
                      selected: _selectedMode == ThemeMode.system,
                      activeColor: activeColor,
                      isDark: isDark,
                      onTap: () => setState(() => _selectedMode = ThemeMode.system),
                    ),
                    const SizedBox(height: 28),
                    Text(
                      'Color Palette',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : AppColors.lightTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(
                        SettingsProvider.accentPalette.length,
                        (i) {
                          final color = SettingsProvider.accentPalette[i];
                          final isSelected = _selectedAccent == i;
                          return GestureDetector(
                            onTap: () => setState(() => _selectedAccent = i),
                            child: Container(
                              padding: const EdgeInsets.all(3),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                border: isSelected
                                    ? Border.all(color: color, width: 2.2)
                                    : Border.all(
                                        color: Colors.transparent, width: 2.2),
                              ),
                              child: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: color,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 36),
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: _apply,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: activeColor,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                          ),
                        ),
                        child: Text(
                          'Apply Changes',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ThemeOptionCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final bool selected;
  final Color activeColor;
  final bool isDark;
  final VoidCallback onTap;

  const _ThemeOptionCard({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.selected,
    required this.activeColor,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.lightSurface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected
                ? activeColor
                : isDark
                    ? AppColors.darkBorder
                    : AppColors.lightBorder,
            width: selected ? 1.8 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isDark ? iconColor.withValues(alpha: 0.16) : iconBg,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : AppColors.lightTextPrimary,
                ),
              ),
            ),
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? activeColor : Colors.transparent,
                border: Border.all(
                  color: selected
                      ? activeColor
                      : isDark
                          ? AppColors.darkTextTertiary
                          : AppColors.lightTextTertiary,
                  width: 1.6,
                ),
              ),
              child: selected
                  ? const Icon(Icons.check_rounded, size: 15, color: Colors.white)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
