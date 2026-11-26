import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:cashpilot/providers/account_provider.dart';
import 'package:cashpilot/providers/transaction_provider.dart';
import 'package:cashpilot/providers/settings_provider.dart';
import 'package:cashpilot/data/models/account_model.dart';
import 'package:cashpilot/core/theme/app_colors.dart';
import 'package:cashpilot/widgets/wavy_background.dart';
import 'package:cashpilot/widgets/ui_kit.dart';
import 'package:cashpilot/widgets/account_picker.dart';

class TransferScreen extends StatefulWidget {
  const TransferScreen({super.key});

  @override
  State<TransferScreen> createState() => _TransferScreenState();
}

class _TransferScreenState extends State<TransferScreen> {
  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  AccountModel? _from;
  AccountModel? _to;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final accp = context.read<AccountProvider>();
      if (accp.accounts.isEmpty) await accp.loadAccounts();
      if (!mounted) return;
      setState(() {
        final list = accp.accounts;
        if (list.isNotEmpty) _from = list.first;
        if (list.length > 1) _to = list[1];
      });
    });
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _transfer() async {
    final amount = double.tryParse(_amountCtrl.text.replaceAll(',', ''));
    if (_from == null || _to == null) return showToast(context, 'Choose both accounts', error: true);
    if (_from!.id == _to!.id) return showToast(context, 'Pick two different accounts', error: true);
    if (amount == null || amount <= 0) return showToast(context, 'Enter a valid amount', error: true);

    setState(() => _saving = true);
    HapticFeedback.mediumImpact();
    final txp = context.read<TransactionProvider>();
    await context.read<AccountProvider>().transferBetweenAccounts(
          fromId: _from!.id,
          toId: _to!.id,
          amount: amount,
          note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
        );
    await txp.loadTransactions();
    if (!mounted) return;
    showToast(context, 'Transfer complete');
    safeBack(context);
  }

  @override
  Widget build(BuildContext context) {
    final accounts = context.watch<AccountProvider>().accounts;
    final symbol = context.watch<SettingsProvider>().currencySymbol;
    // Keep selections fresh after balance changes.
    final from = _from == null ? null : accounts.where((a) => a.id == _from!.id).firstOrNull;
    final to = _to == null ? null : accounts.where((a) => a.id == _to!.id).firstOrNull;

    return Scaffold(
      body: WavyBackground(
        child: SafeArea(
          child: Column(
            children: [
              ScreenHeader(title: 'Transfer Money'),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  children: [
                    const FieldLabel('From Account'),
                    AccountPickerField(
                      accounts: accounts,
                      selected: from,
                      symbol: symbol,
                      onChanged: (a) => setState(() => _from = a),
                    ),
                    // Swap
                    Center(
                      child: GestureDetector(
                        onTap: () => setState(() {
                          final t = _from;
                          _from = _to;
                          _to = t;
                        }),
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 10),
                          child: const GlossyIcon(
                              icon: Icons.swap_vert_rounded,
                              color: AppColors.transfer,
                              size: 40,
                              circle: true),
                        ),
                      ),
                    ),
                    const FieldLabel('To Account'),
                    AccountPickerField(
                      accounts: accounts.where((a) => a.id != from?.id).toList(),
                      selected: to,
                      symbol: symbol,
                      onChanged: (a) => setState(() => _to = a),
                    ),
                    const SizedBox(height: 20),
                    const FieldLabel('Amount'),
                    FieldBox(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                      child: Row(
                        children: [
                          Text(symbol, style: jakarta(24, weight: FontWeight.w800, color: context.textPrimary)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: _amountCtrl,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'))],
                              style: jakarta(24, weight: FontWeight.w800, color: context.textPrimary),
                              decoration: InputDecoration(
                                hintText: '0.00',
                                hintStyle: jakarta(24, weight: FontWeight.w700, color: context.textTertiary),
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                filled: false,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      children: [50, 100, 200, 500].map((v) {
                        return ActionChip(
                          label: Text('$symbol$v', style: jakarta(13, weight: FontWeight.w700, color: AppColors.primary)),
                          backgroundColor: AppColors.primary.withValues(alpha: 0.08),
                          side: BorderSide.none,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          onPressed: () => setState(() => _amountCtrl.text = v.toString()),
                        );
                      }).toList()
                        ..add(ActionChip(
                          label: Text('All', style: jakarta(13, weight: FontWeight.w700, color: AppColors.transfer)),
                          backgroundColor: AppColors.transfer.withValues(alpha: 0.08),
                          side: BorderSide.none,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          onPressed: from == null || from.balance <= 0
                              ? null
                              : () => setState(() => _amountCtrl.text = from.balance.toStringAsFixed(2)),
                        )),
                    ),
                    const SizedBox(height: 16),
                    const FieldLabel('Note (Optional)'),
                    AppTextField(controller: _noteCtrl, hint: 'e.g. For savings', icon: Icons.edit_note_rounded),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 6, 20, 14),
                child: GradientButton(label: 'Transfer Now', loading: _saving, onPressed: _transfer),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
