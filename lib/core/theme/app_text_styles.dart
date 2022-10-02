import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTextStyles {
  static TextStyle heading1(BuildContext context) => GoogleFonts.inter(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        color: Theme.of(context).colorScheme.onSurface,
        height: 1.2,
      );

  static TextStyle heading2(BuildContext context) => GoogleFonts.inter(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: Theme.of(context).colorScheme.onSurface,
        height: 1.3,
      );

  static TextStyle heading3(BuildContext context) => GoogleFonts.inter(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: Theme.of(context).colorScheme.onSurface,
      );

  static TextStyle sectionTitle(BuildContext context) => GoogleFonts.inter(
        fontSize: 17,
        fontWeight: FontWeight.w700,
        color: Theme.of(context).colorScheme.onSurface,
      );

  static TextStyle body(BuildContext context) => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: Theme.of(context).colorScheme.onSurface,
      );

  static TextStyle bodySecondary(BuildContext context) => GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
      );

  static TextStyle caption(BuildContext context) => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
      );

  static TextStyle amountLarge(BuildContext context) => GoogleFonts.inter(
        fontSize: 36,
        fontWeight: FontWeight.w700,
        color: Colors.white,
        letterSpacing: -0.5,
        height: 1.2,
      );

  static TextStyle amountMedium(BuildContext context) => GoogleFonts.inter(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: Theme.of(context).colorScheme.onSurface,
        letterSpacing: -0.3,
      );

  static TextStyle label(BuildContext context) => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
        letterSpacing: 0.3,
      );
}
