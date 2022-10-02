import 'package:flutter/material.dart';

class AppColors {
  // Primary - MyMoney Pro inspired blue-green gradient
  static const Color primary = Color(0xFF00B4D8);
  static const Color primaryLight = Color(0xFF48CAE4);
  static const Color primaryDark = Color(0xFF0077B6);
  static const Color accent = Color(0xFF90E0EF);

  // Semantic - Professional finance colors
  static const Color income = Color(0xFF2ECC71);
  static const Color incomeLight = Color(0xFF58D68D);
  static const Color incomeDark = Color(0xFF27AE60);
  static const Color expense = Color(0xFFE74C3C);
  static const Color expenseLight = Color(0xFFEC7063);
  static const Color expenseDark = Color(0xFFCB4335);
  static const Color transfer = Color(0xFF9B59B6);
  static const Color transferLight = Color(0xFFAF7AC5);
  static const Color transferDark = Color(0xFF884EA0);

  // Dark Theme - Deep professional dark mode
  static const Color darkBg = Color(0xFF121212);
  static const Color darkSurface = Color(0xFF1E1E1E);
  static const Color darkCard = Color(0xFF2C2C2C);
  static const Color darkCardAlt = Color(0xFF3A3A3A);
  static const Color darkBorder = Color(0xFF404040);
  static const Color darkTextPrimary = Color(0xFFFFFFFF);
  static const Color darkTextSecondary = Color(0xB3FFFFFF);
  static const Color darkTextTertiary = Color(0x80FFFFFF);

  // Light Theme - Clean professional light mode
  static const Color lightBg = Color(0xFFF8F9FA);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightCardAlt = Color(0xFFF0F1F3);
  static const Color lightBorder = Color(0xFFE9ECEF);
  static const Color lightTextPrimary = Color(0xFF212529);
  static const Color lightTextSecondary = Color(0xFF6C757D);
  static const Color lightTextTertiary = Color(0xFFADB5BD);

  // Gradients - Modern gradient styles
  static const List<Color> primaryGradient = [Color(0xFF00B4D8), Color(0xFF48CAE4)];
  static const List<Color> incomeGradient = [Color(0xFF2ECC71), Color(0xFF58D68D)];
  static const List<Color> expenseGradient = [Color(0xFFE74C3C), Color(0xFFEC7063)];
  static const List<Color> transferGradient = [Color(0xFF9B59B6), Color(0xFFAF7AC5)];
  static const List<Color> purpleGradient = [Color(0xFF6C5CE7), Color(0xFFA29BFE)];
  static const List<Color> goldGradient = [Color(0xFFF1C40F), Color(0xFFF4D03F)];
  static const List<Color> darkCardGradient = [Color(0xFF1E1E1E), Color(0xFF2C2C2C)];

  // Category Colors - Distinguishable professional palette
  static const List<Color> categoryColors = [
    Color(0xFF2ECC71),  // Green
    Color(0xFF00B4D8),  // Blue
    Color(0xFF9B59B6),  // Purple
    Color(0xFFE74C3C),  // Red
    Color(0xFFF1C40F),  // Yellow
    Color(0xFFE67E22),  // Orange
    Color(0xFF1ABC9C),  // Teal
    Color(0xFF3498DB),  // Light Blue
    Color(0xFF34495E),  // Dark Blue
    Color(0xFF95A5A6),  // Gray
    Color(0xFF16A085),  // Dark Teal
    Color(0xFF8E44AD),  // Dark Purple
    Color(0xFFD35400),  // Dark Orange
    Color(0xFFC0392B),  // Dark Red
  ];

  static Color fromHex(String hex) {
    hex = hex.replaceAll('#', '');
    if (hex.length == 6) hex = 'FF$hex';
    return Color(int.parse(hex, radix: 16));
  }
}
