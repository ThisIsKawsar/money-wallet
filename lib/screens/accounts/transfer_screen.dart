import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cashpilot/providers/account_provider.dart';
import 'package:cashpilot/providers/settings_provider.dart';
import 'package:cashpilot/data/models/account_model.dart';
import 'package:cashpilot/core/theme/app_colors.dart';
import 'package:cashpilot/core/constants/app_icons.dart';

class TransferScreen extends StatefulWidget {
  const TransferScreen({super.key});

  @override
  State<TransferScreen> createState() => _TransferScreenState();
}

class _TransferScreenState extends State<TransferScreen> {
  AccountModel? _from;
  AccountModel? _to;
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AccountProvider>().loadAccounts();
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _transfer() async {
    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0 || _from == null || _to == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please fill all fields correctly'),
            backgroundColor: AppColors.expense),
      );
      return;
    }
    await context.read<AccountProvider>().transferBetweenAccounts(
          fromId: _from!.id,
          toId: _to!.id,
          amount: amount,
          note: _noteController.text.trim().isEmpty
              ? null
              : _noteController.text.trim(),
        );
    if (!context.mounted) return;
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accounts = context.watch<AccountProvider>().accounts;
    final settings = context.watch<SettingsProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text('Transfer',
            style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF1a1a2e))),
        leading: IconButton(
            icon: const Icon(Icons.close), onPressed: () => context.pop()),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _label('From Account', isDark),
            const SizedBox(height: 8),
            _AccountPicker(
              accounts: accounts,
              selected: _from,
              exclude: _to?.id,
              onSelect: (a) => setState(() => _from = a),
              isDark: isDark,
            ),
            const SizedBox(height: 16),
            Center(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.swap_vert_rounded,
                    color: AppColors.primary, size: 24),
              ),
            ),
            const SizedBox(height: 16),
            _label('To Account', isDark),
            const SizedBox(height: 8),
            _AccountPicker(
              accounts: accounts,
              selected: _to,
              exclude: _from?.id,
              onSelect: (a) => setState(() => _to = a),
              isDark: isDark,
            ),
            const SizedBox(height: 24),
            _label('Amount', isDark),
            const SizedBox(height: 8),
            TextField(
              controller: _amountController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                hintText: '0.00',
                prefixText: settings.currencySymbol,
              ),
            ),
            const SizedBox(height: 16),
            _label('Note (optional)', isDark),
            const SizedBox(height: 8),
            TextField(
              controller: _noteController,
              decoration: const InputDecoration(hintText: 'Add a note...'),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _transfer,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.transfer,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: Text('Transfer',
                    style: GoogleFonts.inter(
                        fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text, bool isDark) => Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: isDark
              ? Colors.white.withValues(alpha: 0.7)
              : Colors.black.withValues(alpha: 0.6),
        ),
      );
}

class _AccountPicker extends StatelessWidget {
  final List<AccountModel> accounts;
  final AccountModel? selected;
  final String? exclude;
  final void Function(AccountModel) onSelect;
  final bool isDark;

  const _AccountPicker({
    required this.accounts,
    required this.selected,
    required this.exclude,
    required this.onSelect,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final filtered = accounts.where((a) => a.id != exclude).toList();
    return DropdownButtonFormField<AccountModel>(
      value: selected,
      hint: const Text('Select account'),
      decoration: InputDecoration(
        filled: true,
        fillColor: isDark ? AppColors.darkCardAlt : AppColors.lightCardAlt,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
                BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
                BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      items: filtered
          .map((a) => DropdownMenuItem(
                value: a,
                child: Row(
                  children: [
                    Icon(AppIcons.fromName(a.icon),
                        size: 18, color: AppColors.fromHex(a.color)),
                    const SizedBox(width: 12),
                    Text(a.name),
                  ],
                ),
              ))
          .toList(),
      onChanged: (a) {
        if (a != null) onSelect(a);
      },
    );
  }
}
