import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:cashpilot/core/theme/app_colors.dart';

// ═══════════════════════════════════════════════════════════════════════════
// Design tokens
// ═══════════════════════════════════════════════════════════════════════════

extension ThemeX on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
  Color get textPrimary =>
      isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
  Color get textSecondary =>
      isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
  Color get textTertiary =>
      isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary;
  Color get cardColor => isDark ? AppColors.darkCard : Colors.white;
  Color get borderColor =>
      isDark ? AppColors.darkBorder : const Color(0xFFE6F0EA);
  Color get fieldColor =>
      isDark ? AppColors.darkCardAlt : const Color(0xFFF3F7F4);
  Color get trackColor =>
      isDark ? AppColors.darkCardAlt : const Color(0xFFE8EFEA);
}

TextStyle jakarta(
  double size, {
  FontWeight weight = FontWeight.w500,
  Color? color,
  double? height,
  double? spacing,
}) =>
    GoogleFonts.plusJakartaSans(
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: height,
      letterSpacing: spacing,
    );

String fmtMoney(double amount, String symbol, {int decimals = 2}) {
  final f = NumberFormat(decimals == 0 ? '#,##0' : '#,##0.00', 'en_US');
  final sign = amount < 0 ? '-' : '';
  return '$sign$symbol${f.format(amount.abs())}';
}

/// Compact money: $1.2k, $3.4M.
String fmtCompact(double amount, String symbol) {
  final a = amount.abs();
  final sign = amount < 0 ? '-' : '';
  if (a >= 1e6) return '$sign$symbol${(a / 1e6).toStringAsFixed(1)}M';
  if (a >= 1e3) return '$sign$symbol${(a / 1e3).toStringAsFixed(a >= 1e4 ? 0 : 1)}k';
  return '$sign$symbol${a.toStringAsFixed(0)}';
}

Color lighten(Color c, double t) => Color.lerp(c, Colors.white, t)!;
Color darken(Color c, double t) => Color.lerp(c, Colors.black, t)!;

List<BoxShadow> softShadow(BuildContext context, {double strength = 1}) =>
    context.isDark
        ? [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25 * strength),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ]
        : [
            BoxShadow(
              color: AppColors.primaryDark.withValues(alpha: 0.07 * strength),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02 * strength),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ];

// ═══════════════════════════════════════════════════════════════════════════
// Surfaces
// ═══════════════════════════════════════════════════════════════════════════

class SoftCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final VoidCallback? onTap;
  final Color? color;
  final Gradient? gradient;
  final EdgeInsetsGeometry? margin;
  final bool shadow;

  const SoftCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.radius = 20,
    this.onTap,
    this.color,
    this.gradient,
    this.margin,
    this.shadow = true,
  });

  @override
  Widget build(BuildContext context) {
    final br = BorderRadius.circular(radius);
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: gradient == null ? (color ?? context.cardColor) : null,
        gradient: gradient,
        borderRadius: br,
        border: gradient == null
            ? Border.all(color: context.borderColor, width: 1)
            : null,
        boxShadow: shadow ? softShadow(context) : null,
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          borderRadius: br,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

/// Glossy, slightly 3D icon badge: gradient fill, top sheen, coloured glow.
class GlossyIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;
  final double? iconSize;
  final bool circle;

  const GlossyIcon({
    super.key,
    required this.icon,
    required this.color,
    this.size = 44,
    this.iconSize,
    this.circle = false,
  });

  @override
  Widget build(BuildContext context) {
    final radius = circle ? size / 2 : size * 0.32;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [lighten(color, 0.32), color, darken(color, 0.12)],
          stops: const [0, 0.55, 1],
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: context.isDark ? 0.25 : 0.38),
            blurRadius: size * 0.32,
            offset: Offset(0, size * 0.14),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Stack(
          children: [
            Positioned(
              top: size * 0.06,
              left: size * 0.14,
              right: size * 0.14,
              height: size * 0.38,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(size),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white.withValues(alpha: 0.45),
                      Colors.white.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),
            Center(
              child: Icon(
                icon,
                color: Colors.white,
                size: iconSize ?? size * 0.5,
                shadows: [
                  Shadow(
                    color: darken(color, 0.35).withValues(alpha: 0.45),
                    blurRadius: 4,
                    offset: const Offset(0, 1.5),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Pale tinted tile with a gradient-coloured glyph (used in list rows).
class TintIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;
  final bool circle;

  const TintIcon({
    super.key,
    required this.icon,
    required this.color,
    this.size = 46,
    this.circle = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: circle ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: circle ? null : BorderRadius.circular(size * 0.32),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: context.isDark ? 0.22 : 0.10),
            color.withValues(alpha: context.isDark ? 0.14 : 0.18),
          ],
        ),
      ),
      child: Center(
        child: ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (r) => LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [lighten(color, 0.2), darken(color, 0.12)],
          ).createShader(r),
          child: Icon(icon, size: size * 0.5, color: Colors.white),
        ),
      ),
    );
  }
}

/// Pops if possible, otherwise returns to Home (e.g. after a deep `go`).
void safeBack(BuildContext context) {
  if (context.canPop()) {
    context.pop();
  } else {
    context.go('/');
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Layout pieces
// ═══════════════════════════════════════════════════════════════════════════

class ScreenHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onBack;
  final Widget? trailing;
  final bool showBack;

  const ScreenHeader({
    super.key,
    required this.title,
    this.onBack,
    this.trailing,
    this.showBack = true,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
      child: SizedBox(
        height: 48,
        child: Row(
          children: [
            SizedBox(
              width: 48,
              child: showBack
                  ? IconButton(
                      icon: Icon(Icons.arrow_back_ios_new_rounded,
                          size: 20, color: context.textPrimary),
                      onPressed: onBack ?? () => safeBack(context),
                    )
                  : null,
            ),
            Expanded(
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: jakarta(18,
                    weight: FontWeight.w700, color: context.textPrimary),
              ),
            ),
            SizedBox(width: 48, child: trailing),
          ],
        ),
      ),
    );
  }
}

class HeaderIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool badge;

  const HeaderIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.badge = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: context.cardColor,
          shape: BoxShape.circle,
          border: Border.all(color: context.borderColor),
          boxShadow: softShadow(context, strength: 0.6),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(icon, size: 22, color: context.textPrimary),
            if (badge)
              Positioned(
                top: 9,
                right: 10,
                child: Container(
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(
                    color: AppColors.expense,
                    shape: BoxShape.circle,
                    border: Border.all(color: context.cardColor, width: 1.5),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  final String title;
  final String? action;
  final VoidCallback? onAction;

  const SectionHeader({super.key, required this.title, this.action, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(title,
              style: jakarta(17,
                  weight: FontWeight.w700, color: context.textPrimary)),
        ),
        if (action != null)
          GestureDetector(
            onTap: onAction,
            behavior: HitTestBehavior.opaque,
            child: Row(
              children: [
                Text(action!,
                    style: jakarta(13,
                        weight: FontWeight.w700, color: AppColors.primary)),
                const SizedBox(width: 3),
                Icon(Icons.arrow_forward_rounded,
                    size: 15, color: AppColors.primary),
              ],
            ),
          ),
      ],
    );
  }
}

class FieldLabel extends StatelessWidget {
  final String text;
  const FieldLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8, left: 2),
        child: Text(text,
            style: jakarta(14,
                weight: FontWeight.w600, color: context.textPrimary)),
      );
}

/// Rounded field container used for inputs and pickers.
class FieldBox extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;

  const FieldBox({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.isDark ? AppColors.darkCard : Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: context.borderColor),
          ),
          child: child,
        ),
      ),
    );
  }
}

class AppTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData? icon;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;
  final bool autofocus;

  const AppTextField({
    super.key,
    required this.controller,
    required this.hint,
    this.icon,
    this.keyboardType,
    this.onChanged,
    this.autofocus = false,
  });

  @override
  Widget build(BuildContext context) {
    return FieldBox(
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 20, color: context.textTertiary),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: keyboardType,
              onChanged: onChanged,
              autofocus: autofocus,
              style: jakarta(15, color: context.textPrimary),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: jakarta(14, color: context.textTertiary),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Buttons & selectors
// ═══════════════════════════════════════════════════════════════════════════

class GradientButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? trailingIcon;
  final bool loading;
  final List<Color>? colors;
  final double height;

  const GradientButton({
    super.key,
    required this.label,
    this.onPressed,
    this.trailingIcon,
    this.loading = false,
    this.colors,
    this.height = 56,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !loading;
    final colors = this.colors ?? AppColors.primaryGradient;
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: enabled ? 1 : 0.6,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(height / 2),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [lighten(colors.last, 0.05), colors.first],
          ),
          boxShadow: [
            BoxShadow(
              color: colors.first.withValues(alpha: 0.35),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: BorderRadius.circular(height / 2),
            onTap: enabled ? onPressed : null,
            child: Center(
              child: loading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.4, color: Colors.white),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(label,
                            style: jakarta(16,
                                weight: FontWeight.w700, color: Colors.white)),
                        if (trailingIcon != null) ...[
                          const SizedBox(width: 8),
                          Icon(trailingIcon, color: Colors.white, size: 20),
                        ],
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Row of separate pill tabs (selected one is a green gradient pill).
class PillTabs extends StatelessWidget {
  final List<String> labels;
  final int index;
  final ValueChanged<int> onChanged;
  final bool expand;
  final double height;

  const PillTabs({
    super.key,
    required this.labels,
    required this.index,
    required this.onChanged,
    this.expand = true,
    this.height = 44,
  });

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];
    for (var i = 0; i < labels.length; i++) {
      final selected = i == index;
      final pill = GestureDetector(
        onTap: () => onChanged(i),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          height: height,
          padding: EdgeInsets.symmetric(horizontal: expand ? 8 : 18),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(height / 2),
            gradient: selected
                ? LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [AppColors.primaryLight, AppColors.primary],
                  )
                : null,
            color: selected ? null : context.cardColor,
            border: selected ? null : Border.all(color: context.borderColor),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 5),
                    ),
                  ]
                : null,
          ),
          child: Text(
            labels[i],
            style: jakarta(height < 40 ? 13 : 14,
                weight: selected ? FontWeight.w700 : FontWeight.w600,
                color: selected ? Colors.white : context.textSecondary),
          ),
        ),
      );
      children.add(expand ? Expanded(child: pill) : pill);
      if (i != labels.length - 1) children.add(const SizedBox(width: 8));
    }
    return Row(children: children);
  }
}

class LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  final bool hollow;

  const LegendDot({super.key, required this.color, required this.label, this.hollow = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: hollow ? null : color,
            shape: BoxShape.circle,
            border: hollow ? Border.all(color: color, width: 1.5) : null,
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: jakarta(12, color: context.textSecondary)),
      ],
    );
  }
}

/// Rounded progress bar with gradient fill.
class SoftProgressBar extends StatelessWidget {
  final double value;
  final Color? color;
  final double height;

  const SoftProgressBar({
    super.key,
    required this.value,
    this.color,
    this.height = 8,
  });

  @override
  Widget build(BuildContext context) {
    final v = value.clamp(0.0, 1.0);
    final color = this.color ?? AppColors.primary;
    return LayoutBuilder(
      builder: (context, c) => Container(
        height: height,
        decoration: BoxDecoration(
          color: context.trackColor,
          borderRadius: BorderRadius.circular(height),
        ),
        alignment: Alignment.centerLeft,
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: v),
          duration: const Duration(milliseconds: 700),
          curve: Curves.easeOutCubic,
          builder: (context, t, _) => Container(
            width: c.maxWidth * t,
            height: height,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(height),
              gradient: LinearGradient(colors: [lighten(color, 0.25), color]),
            ),
          ),
        ),
      ),
    );
  }
}

Future<T?> showAppSheet<T>(BuildContext context, {required WidgetBuilder builder}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: ctx.isDark ? AppColors.darkSurface : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: ctx.textTertiary.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              builder(ctx),
            ],
          ),
        ),
      ),
    ),
  );
}

void showToast(BuildContext context, String msg, {bool error = false, IconData? icon}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: error ? AppColors.expense : const Color(0xFF15281E),
      duration: const Duration(milliseconds: 1800),
      content: Row(
        children: [
          Icon(icon ?? (error ? Icons.error_outline_rounded : Icons.check_circle_rounded),
              color: error ? Colors.white : AppColors.accent, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(msg,
                style: jakarta(14, weight: FontWeight.w600, color: Colors.white)),
          ),
        ],
      ),
    ));
}

/// Pale tinted tile with a glossy icon, big value and caption.
class TintStatTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String value;
  final String label;
  final String? badge;
  final bool badgeUp;
  final VoidCallback? onTap;

  const TintStatTile({
    super.key,
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
    this.badge,
    this.badgeUp = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: context.isDark ? 0.16 : 0.07),
            color.withValues(alpha: context.isDark ? 0.10 : 0.14),
          ],
        ),
        border: Border.all(color: color.withValues(alpha: context.isDark ? 0.22 : 0.14)),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    GlossyIcon(icon: icon, color: color, size: 30, circle: true, iconSize: 17),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: jakarta(13, weight: FontWeight.w600, color: context.textSecondary)),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(value,
                      style: jakarta(22, weight: FontWeight.w800, color: context.textPrimary, spacing: -0.4)),
                ),
                if (badge != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(badgeUp ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                          size: 13, color: color),
                      const SizedBox(width: 2),
                      Flexible(
                        child: Text(badge!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: jakarta(12, weight: FontWeight.w700, color: color)),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Animated circular gauge with gradient sweep and rounded cap.
class RingGauge extends StatelessWidget {
  final double value;
  final double size;
  final double stroke;
  final Color? color;
  final Widget center;

  const RingGauge({
    super.key,
    required this.value,
    required this.center,
    this.size = 170,
    this.stroke = 16,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value.clamp(0.0, 1.0)),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutCubic,
      builder: (context, v, _) => SizedBox(
        width: size,
        height: size,
        child: CustomPaint(
          painter: _RingPainter(v, stroke, color ?? AppColors.primary, context.trackColor),
          child: Center(child: center),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double v;
  final double stroke;
  final Color color;
  final Color track;
  _RingPainter(this.v, this.stroke, this.color, this.track);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final r = rect.deflate(stroke / 2);
    canvas.drawArc(r, 0, 6.2832, false,
        Paint()
          ..color = track
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke);
    if (v <= 0) return;
    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);
    canvas.rotate(-1.5708);
    canvas.translate(-size.width / 2, -size.height / 2);
    final paint = Paint()
      ..shader = SweepGradient(
        colors: [lighten(color, 0.35), color, darken(color, 0.1)],
        stops: const [0, 0.6, 1],
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(r, 0.0001, 6.2832 * v, false,
        Paint()
          ..color = color.withValues(alpha: 0.25)
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke
          ..strokeCap = StrokeCap.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6));
    canvas.drawArc(r, 0.0001, 6.2832 * v, false, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) => old.v != v || old.color != color || old.track != track;
}
