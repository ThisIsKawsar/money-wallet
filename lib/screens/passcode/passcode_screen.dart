import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cashpilot/providers/settings_provider.dart';
import 'package:cashpilot/core/theme/app_colors.dart';

enum PasscodeMode { setup, verify, change }

class PasscodeScreen extends StatefulWidget {
  final PasscodeMode mode;
  const PasscodeScreen({super.key, required this.mode});

  @override
  State<PasscodeScreen> createState() => _PasscodeScreenState();
}

class _PasscodeScreenState extends State<PasscodeScreen>
    with SingleTickerProviderStateMixin {
  String _pin = '';
  String _confirmPin = '';
  bool _isConfirming = false;
  bool _hasError = false;
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _shakeAnimation = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -8.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -8.0, end: 8.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 8.0, end: -8.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -8.0, end: 0.0), weight: 1),
    ]).animate(_shakeController);
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  void _onDigit(String digit) {
    if (_pin.length >= 4) return;
    setState(() => _pin += digit);
    if (_pin.length == 4) _onPinComplete();
  }

  void _onDelete() {
    if (_pin.isEmpty) return;
    setState(() => _pin = _pin.substring(0, _pin.length - 1));
  }

  Future<void> _onPinComplete() async {
    final settings = context.read<SettingsProvider>();

    switch (widget.mode) {
      case PasscodeMode.setup:
      case PasscodeMode.change:
        if (!_isConfirming) {
          setState(() {
            _confirmPin = _pin;
            _pin = '';
            _isConfirming = true;
          });
        } else {
          if (_pin == _confirmPin) {
            await settings.setPasscode(_pin);
            if (mounted) context.pop();
          } else {
            _shake();
          }
        }
        break;

      case PasscodeMode.verify:
        if (settings.verifyPasscode(_pin)) {
          if (mounted) context.pop();
        } else {
          _shake();
        }
        break;
    }
  }

  void _shake() {
    setState(() {
      _hasError = true;
      _pin = '';
      _isConfirming = widget.mode == PasscodeMode.verify ? false : _isConfirming;
    });
    _shakeController.forward(from: 0);
    HapticFeedback.heavyImpact();
    Future.delayed(const Duration(seconds: 1),
        () => mounted ? setState(() => _hasError = false) : null);
  }

  String get _title {
    switch (widget.mode) {
      case PasscodeMode.setup:
        return _isConfirming ? 'Confirm PIN' : 'Set PIN';
      case PasscodeMode.change:
        return _isConfirming ? 'Confirm New PIN' : 'New PIN';
      case PasscodeMode.verify:
        return 'Enter PIN';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: widget.mode != PasscodeMode.verify
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => context.pop(),
              )
            : null,
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            _title,
            style: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF1a1a2e),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _hasError
                ? 'Incorrect PIN, try again'
                : widget.mode == PasscodeMode.setup && _isConfirming
                    ? 'Re-enter your PIN'
                    : 'Enter your 4-digit PIN',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: _hasError
                  ? AppColors.expense
                  : isDark
                      ? Colors.white.withValues(alpha: 0.5)
                      : Colors.black.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 48),
          AnimatedBuilder(
            animation: _shakeAnimation,
            builder: (context, child) => Transform.translate(
              offset: Offset(_shakeAnimation.value, 0),
              child: child,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                4,
                (i) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: i < _pin.length
                        ? _hasError
                            ? AppColors.expense
                            : AppColors.primary
                        : Colors.transparent,
                    border: Border.all(
                      color: i < _pin.length
                          ? _hasError
                              ? AppColors.expense
                              : AppColors.primary
                          : isDark
                              ? Colors.white.withValues(alpha: 0.3)
                              : Colors.black.withValues(alpha: 0.3),
                      width: 2,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 48),
          _buildKeypad(isDark),
        ],
      ),
    );
  }

  Widget _buildKeypad(bool isDark) {
    const keys = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['', '0', 'del'],
    ];

    return Column(
      children: keys
          .map((row) => Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: row.map((key) {
                  if (key.isEmpty) return const SizedBox(width: 88, height: 72);
                  if (key == 'del') {
                    return _KeyButton(
                      onTap: _onDelete,
                      isDark: isDark,
                      child: const Icon(Icons.backspace_outlined, size: 22),
                    );
                  }
                  return _KeyButton(
                    onTap: () => _onDigit(key),
                    isDark: isDark,
                    child: Text(
                      key,
                      style: GoogleFonts.inter(
                        fontSize: 24,
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.white : const Color(0xFF1a1a2e),
                      ),
                    ),
                  );
                }).toList(),
              ))
          .toList(),
    );
  }
}

class _KeyButton extends StatelessWidget {
  final VoidCallback onTap;
  final Widget child;
  final bool isDark;

  const _KeyButton(
      {required this.onTap, required this.child, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 88,
        height: 72,
        alignment: Alignment.center,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(44),
            child: Container(
              width: 72,
              height: 72,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : Colors.black.withValues(alpha: 0.05),
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
