import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AnimatedCounter extends StatelessWidget {
  final double value;
  final String currencySymbol;
  final TextStyle? style;
  final Duration duration;
  final int decimalPlaces;

  const AnimatedCounter({
    super.key,
    required this.value,
    this.currencySymbol = '\$',
    this.style,
    this.duration = const Duration(milliseconds: 1000),
    this.decimalPlaces = 2,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: value),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (context, animatedValue, _) {
        final formatter = NumberFormat(
          '#,##0${decimalPlaces > 0 ? '.${'0' * decimalPlaces}' : ''}',
          'en_US',
        );
        return Text(
          '$currencySymbol${formatter.format(animatedValue.abs())}',
          style: style ?? Theme.of(context).textTheme.headlineMedium,
        );
      },
    );
  }
}
