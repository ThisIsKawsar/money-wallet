import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';
import 'package:cashpilot/providers/account_provider.dart';
import 'package:cashpilot/data/models/account_model.dart';
import 'package:cashpilot/core/theme/app_colors.dart';

const _uuid = Uuid();

class AddAccountSheet extends StatefulWidget {
  final AccountModel? account;
  const AddAccountSheet({super.key, this.account});

  static Future<void> show(BuildContext context, {AccountModel? account}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddAccountSheet(account: account),
    );
  }

  @override
  State<AddAccountSheet> createState() => _AddAccountSheetState();
}

class _AddAccountSheetState extends State<AddAccountSheet> {
  final _nameController = TextEditingController();
  final _balanceController = TextEditingController();
  AccountType _type = AccountType.cash;
  String _selectedColor = '#4facfe';
  bool _isEditing = false;

  static const _colors = [
    '#00d4aa',
    '#4facfe',
    '#ff6b6b',
    '#a29bfe',
    '#fd79a8',
    '#ffeaa7',
    '#e17055',
    '#fdcb6e',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.account != null) {
      _isEditing = true;
      _nameController.text = widget.account!.name;
      _type = widget.account!.type;
      _selectedColor = widget.account!.color;
      _balanceController.text = _fmtBalance(widget.account!.balance);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _balanceController.dispose();
    super.dispose();
  }

  static String _fmtBalance(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(2);

  /// Empty means "keep" when editing and 0 when adding.
  double? _parsedBalance() {
    final raw = _balanceController.text.replaceAll(',', '').trim();
    if (raw.isEmpty || raw == '-') return null;
    return double.tryParse(raw);
  }

  Future<void> _save() async {
    if (_nameController.text.trim().isEmpty) return;
    final provider = context.read<AccountProvider>();
    final balance = _parsedBalance();
    if (_isEditing) {
      final updated = widget.account!.copyWith(
        name: _nameController.text.trim(),
        type: _type,
        color: _selectedColor,
        balance: balance ?? widget.account!.balance,
      );
      await provider.updateAccount(updated);
    } else {
      final account = AccountModel(
        id: _uuid.v4(),
        name: _nameController.text.trim(),
        type: _type,
        icon: _iconForType(_type),
        color: _selectedColor,
        balance: balance ?? 0,
        createdAt: DateTime.now(),
      );
      await provider.addAccount(account);
    }
    if (mounted) Navigator.pop(context);
  }

  String _iconForType(AccountType type) {
    switch (type) {
      case AccountType.bank:
        return 'account_balance';
      case AccountType.credit:
        return 'credit_card';
      case AccountType.savings:
        return 'savings';
      case AccountType.mobile:
        return 'phone_android';
      case AccountType.ewallet:
        return 'payments';
      default:
        return 'wallet';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                _isEditing ? 'Edit Account' : 'New Account',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF1a1a2e),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Account Name',
                  hintText: 'e.g. My Bank Account',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _balanceController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                  signed: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[-0-9.,]')),
                ],
                decoration: InputDecoration(
                  labelText: 'Current Balance',
                  hintText: '0',
                  helperText: _isEditing
                      ? 'Set the real amount in this account now. Transactions are not changed.'
                      : 'How much is in this account right now',
                  helperMaxLines: 2,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Type',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.7)
                      : Colors.black.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: AccountType.values.map((t) {
                  final isSelected = _type == t;
                  return ChoiceChip(
                    label: Text(t.name),
                    selected: isSelected,
                    onSelected: (_) => setState(() => _type = t),
                    selectedColor: AppColors.primary,
                    labelStyle: GoogleFonts.inter(
                      color: isSelected ? Colors.white : null,
                      fontWeight: FontWeight.w500,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              Text(
                'Color',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.7)
                      : Colors.black.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 10,
                children: _colors.map((hex) {
                  final color = AppColors.fromHex(hex);
                  final isSelected = _selectedColor == hex;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedColor = hex),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? Colors.white : Colors.transparent,
                          width: 2,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: color.withValues(alpha: 0.5),
                                  blurRadius: 8,
                                ),
                              ]
                            : null,
                      ),
                      child: isSelected
                          ? const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 18,
                            )
                          : null,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    _isEditing ? 'Update Account' : 'Add Account',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
