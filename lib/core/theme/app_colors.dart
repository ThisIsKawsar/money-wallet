import 'package:flutter/material.dart';

class AppColors {
  // ── Brand (follows the accent chosen in Appearance) ──────────────────
  static const Color defaultBrand = Color(0xFF10A352);
  static Color _brand = defaultBrand;

  /// Called by SettingsProvider whenever the accent changes.
  static void setBrand(Color c) => _brand = c;

  static bool get _isDefault => _brand.toARGB32() == defaultBrand.toARGB32();
  static Color get primary => _brand;
  static Color get primaryLight =>
      _isDefault ? const Color(0xFF28C76F) : Color.lerp(_brand, Colors.white, 0.18)!;
  static Color get primaryDark =>
      _isDefault ? const Color(0xFF0A7E3E) : Color.lerp(_brand, Colors.black, 0.22)!;
  static Color get accent =>
      _isDefault ? const Color(0xFF6FE3A1) : Color.lerp(_brand, Colors.white, 0.45)!;

  /// Very light tints of the brand for backgrounds (t = 0 → white).
  static Color tint(double t) => Color.lerp(Colors.white, _brand, t)!;

  // Soft surfaces
  static Color get mintBg => tint(0.04);
  static Color get mintSoft => tint(0.10);
  static Color get mintWave => tint(0.16);

  // Semantic - Finance colors
  static const Color income = Color(0xFF16A34A);
  static const Color incomeLight = Color(0xFF28C76F);
  static const Color incomeDark = Color(0xFF0A7E3E);
  static const Color expense = Color(0xFFE74C3C);
  static const Color expenseLight = Color(0xFFFDECEC);
  static const Color expenseDark = Color(0xFFC0392B);
  static const Color transfer = Color(0xFF2F80ED);
  static const Color transferLight = Color(0xFFEAF2FD);
  static const Color transferDark = Color(0xFF1D62C2);
  static const Color budgetPurple = Color(0xFF8E44AD);
  static const Color budgetPurpleLight = Color(0xFFF3E8FA);

  // Dark Theme
  static const Color darkBg = Color(0xFF0E1512);
  static const Color darkSurface = Color(0xFF16201B);
  static const Color darkCard = Color(0xFF1E2B24);
  static const Color darkCardAlt = Color(0xFF26362E);
  static const Color darkBorder = Color(0xFF2E4036);
  static const Color darkTextPrimary = Color(0xFFFFFFFF);
  static const Color darkTextSecondary = Color(0xB3FFFFFF);
  static const Color darkTextTertiary = Color(0x80FFFFFF);

  // Light Theme - Clean Mint-White
  static const Color lightBg = Color(0xFFF7FAF8);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightCardAlt = Color(0xFFF2F5F3);
  static const Color lightBorder = Color(0xFFE7EFEA);
  static const Color lightTextPrimary = Color(0xFF1A221E);
  static const Color lightTextSecondary = Color(0xFF6B7871);
  static const Color lightTextTertiary = Color(0xFF9AA7A0);

  // Gradients
  static List<Color> get primaryGradient => [primaryDark, primaryLight];
  static const List<Color> incomeGradient = [Color(0xFF10A352), Color(0xFF28C76F)];
  static const List<Color> expenseGradient = [Color(0xFFE74C3C), Color(0xFFEC7063)];
  static const List<Color> transferGradient = [Color(0xFF2F80ED), Color(0xFF56CCF2)];
  static const List<Color> purpleGradient = [Color(0xFF8E44AD), Color(0xFFBB6BD9)];
  static const List<Color> goldGradient = [Color(0xFFF39C12), Color(0xFFF7DC6F)];
  static const List<Color> darkCardGradient = [Color(0xFF16201B), Color(0xFF1E2B24)];

  // Category Colors
  static const List<Color> categoryColors = [
    Color(0xFF10A352), // Emerald Green
    Color(0xFFE74C3C), // Coral Red
    Color(0xFF2F80ED), // Blue
    Color(0xFF8E44AD), // Purple
    Color(0xFFF39C12), // Amber
    Color(0xFF16A085), // Teal
    Color(0xFFE67E22), // Orange
    Color(0xFF3498DB), // Sky Blue
    Color(0xFF34495E), // Slate
    Color(0xFF95A5A6), // Gray
    Color(0xFF27AE60), // Green
    Color(0xFF9B59B6), // Violet
    Color(0xFFD35400), // Rust
    Color(0xFFC0392B), // Crimson
  ];

  static Color fromHex(String hex) {
    hex = hex.replaceAll('#', '');
    if (hex.length == 6) hex = 'FF$hex';
    return Color(int.parse(hex, radix: 16));
  }
}
