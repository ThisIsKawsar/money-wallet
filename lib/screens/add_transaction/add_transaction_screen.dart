import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:cashpilot/providers/transaction_provider.dart';
import 'package:cashpilot/providers/account_provider.dart';
import 'package:cashpilot/providers/category_provider.dart';
import 'package:cashpilot/providers/settings_provider.dart';
import 'package:cashpilot/data/models/transaction_model.dart';
import 'package:cashpilot/data/models/account_model.dart';
import 'package:cashpilot/data/models/category_model.dart';
import 'package:cashpilot/core/theme/app_colors.dart';
import 'package:cashpilot/core/constants/app_icons.dart';
import 'package:cashpilot/widgets/wavy_background.dart';
import 'package:cashpilot/widgets/ui_kit.dart';
import 'package:cashpilot/widgets/account_picker.dart';

const _uuid = Uuid();

class AddTransactionScreen extends StatefulWidget {
  final String? initialType;
  final TransactionModel? transaction;

  const AddTransactionScreen({super.key, this.initialType, this.transaction});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  static const _types = [TransactionType.income, TransactionType.expense, TransactionType.transfer];

  late int _typeIndex;
  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  DateTime _date = DateTime.now();
  CategoryModel? _category;
  AccountModel? _account;
  AccountModel? _toAccount;
  bool _showAll = false;
  bool _saving = false;

  bool get _isEditing => widget.transaction != null;
  TransactionType get _type => _types[_typeIndex];

  @override
  void initState() {
    super.initState();
    final tx = widget.transaction;
    _typeIndex = switch (widget.initialType) {
      'income' => 0,
      'expense' => 1,
      'transfer' => 2,
      _ => tx != null ? _types.indexOf(tx.type) : 1,
    };
    if (tx != null) {
      _amountCtrl.text = tx.amount.toStringAsFixed(2);
      _noteCtrl.text = tx.note ?? '';
      _date = tx.date;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _init());
  }

  Future<void> _init() async {
    final cats = context.read<CategoryProvider>();
    final accs = context.read<AccountProvider>();
    if (cats.categories.isEmpty) await cats.loadCategories();
    if (accs.accounts.isEmpty) await accs.loadAccounts();
    if (!mounted) return;
    setState(() {
      final tx = widget.transaction;
      if (tx != null) {
        _category = cats.getCategoryById(tx.categoryId);
        _account = accs.getAccountById(tx.accountId);
        if (tx.toAccountId != null) _toAccount = accs.getAccountById(tx.toAccountId!);
      } else {
        if (accs.accounts.isNotEmpty) _account = accs.accounts.first;
        if (accs.accounts.length > 1) _toAccount = accs.accounts[1];
        _autoCategory(cats);
      }
    });
  }

  void _autoCategory(CategoryProvider cats) {
    final list = _type == TransactionType.income ? cats.incomeCategories : cats.expenseCategories;
    _category = list.isNotEmpty ? list.first : null;
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final amount = double.tryParse(_amountCtrl.text.replaceAll(',', ''));
    if (amount == null || amount <= 0) return showToast(context, 'Enter a valid amount', error: true);
    if (_type != TransactionType.transfer && _category == null) {
      return showToast(context, 'Choose a category', error: true);
    }
    if (_account == null) return showToast(context, 'Choose an account', error: true);
    if (_type == TransactionType.transfer &&
        (_toAccount == null || _toAccount!.id == _account!.id)) {
      return showToast(context, 'Choose a different destination account', error: true);
    }

    setState(() => _saving = true);
    HapticFeedback.lightImpact();
    final txp = context.read<TransactionProvider>();
    final accp = context.read<AccountProvider>();
    final note = _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim();

    if (_isEditing) {
      final old = widget.transaction!;
      // Revert the old effect, then apply the new one.
      await accp.applyTransaction(old, revert: true);
      final updated = old.copyWith(
        type: _type,
        amount: amount,
        categoryId: _type == TransactionType.transfer ? 'transfer' : _category!.id,
        accountId: _account!.id,
        toAccountId: _type == TransactionType.transfer ? _toAccount?.id : null,
        date: _date,
        note: note,
      );
      await txp.updateTransaction(updated);
      await accp.applyTransaction(updated);
    } else if (_type == TransactionType.transfer) {
      await accp.transferBetweenAccounts(
          fromId: _account!.id, toId: _toAccount!.id, amount: amount, note: note);
      await txp.loadTransactions();
    } else {
      final tx = TransactionModel(
        id: _uuid.v4(),
        type: _type,
        amount: amount,
        categoryId: _category!.id,
        accountId: _account!.id,
        date: _date,
        note: note,
        createdAt: DateTime.now(),
      );
      await txp.addTransaction(tx);
      await accp.applyTransaction(tx);
    }

    if (!mounted) return;
    showToast(context, _isEditing ? 'Transaction updated' : 'Transaction saved');
    safeBack(context);
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete transaction?'),
        content: const Text('The account balance will be adjusted.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Delete', style: TextStyle(color: AppColors.expense))),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final accp = context.read<AccountProvider>();
    await accp.applyTransaction(widget.transaction!, revert: true);
    if (!mounted) return;
    await context.read<TransactionProvider>().deleteTransaction(widget.transaction!.id);
    if (mounted) safeBack(context);
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _date = DateTime(picked.year, picked.month, picked.day, _date.hour, _date.minute));
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final catp = context.watch<CategoryProvider>();
    final accounts = context.watch<AccountProvider>().accounts;
    final cats = _type == TransactionType.income ? catp.incomeCategories : catp.expenseCategories;
    final visible = _showAll ? cats : cats.take(3).toList();
    final accent = switch (_type) {
      TransactionType.income => AppColors.income,
      TransactionType.expense => AppColors.expense,
      TransactionType.transfer => AppColors.transfer,
    };
    final cta = _isEditing
        ? 'Save Changes'
        : ['Add Income', 'Add Expense', 'Transfer Now'][_typeIndex];

    return Scaffold(
      body: WavyBackground(
        child: SafeArea(
          child: Column(
            children: [
              ScreenHeader(
                title: _isEditing ? 'Edit Transaction' : 'Add Transaction',
                                trailing: _isEditing
                    ? IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, color: AppColors.expense),
                        onPressed: _delete,
                      )
                    : null,
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  children: [
                    PillTabs(
                      labels: const ['Income', 'Expense', 'Transfer'],
                      index: _typeIndex,
                      onChanged: (i) => setState(() {
                        _typeIndex = i;
                        _showAll = false;
                        _autoCategory(catp);
                      }),
                    ),
                    const SizedBox(height: 20),

                    // Amount
                    SoftCard(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Amount', style: jakarta(12, weight: FontWeight.w600, color: context.textTertiary)),
                          Row(
                            children: [
                              Text(settings.currencySymbol,
                                  style: jakarta(32, weight: FontWeight.w800, color: accent)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextField(
                                  controller: _amountCtrl,
                                  autofocus: !_isEditing,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  inputFormatters: [
                                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                                  ],
                                  style: jakarta(34, weight: FontWeight.w800, color: context.textPrimary),
                                  decoration: InputDecoration(
                                    hintText: '0.00',
                                    hintStyle: jakarta(34, weight: FontWeight.w700, color: context.textTertiary),
                                    border: InputBorder.none,
                                    enabledBorder: InputBorder.none,
                                    focusedBorder: InputBorder.none,
                                    filled: false,
                                    isDense: true,
                                    contentPadding: const EdgeInsets.symmetric(vertical: 6),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),

                    if (_type != TransactionType.transfer) ...[
                      const FieldLabel('Category'),
                      AnimatedSize(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOut,
                        alignment: Alignment.topCenter,
                        child: GridView.count(
                          crossAxisCount: 4,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          mainAxisSpacing: 14,
                          crossAxisSpacing: 8,
                          childAspectRatio: 0.82,
                          children: [
                            for (final c in visible)
                              _CategoryChoice(
                                label: c.name,
                                icon: AppIcons.fromName(c.icon),
                                color: AppColors.fromHex(c.color),
                                selected: _category?.id == c.id,
                                onTap: () => setState(() => _category = c),
                              ),
                            if (cats.length > 3)
                              _CategoryChoice(
                                label: _showAll ? 'Less' : 'More',
                                icon: _showAll ? Icons.expand_less_rounded : Icons.more_horiz_rounded,
                                color: AppColors.transfer,
                                selected: false,
                                onTap: () => setState(() => _showAll = !_showAll),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],

                    FieldLabel(_type == TransactionType.transfer ? 'From Account' : 'Account'),
                    AccountPickerField(
                      accounts: accounts,
                      selected: _account,
                      symbol: settings.currencySymbol,
                      onChanged: (a) => setState(() => _account = a),
                    ),
                    if (_type == TransactionType.transfer) ...[
                      const SizedBox(height: 16),
                      const FieldLabel('To Account'),
                      AccountPickerField(
                        accounts: accounts.where((a) => a.id != _account?.id).toList(),
                        selected: _toAccount,
                        symbol: settings.currencySymbol,
                        onChanged: (a) => setState(() => _toAccount = a),
                      ),
                    ],
                    const SizedBox(height: 18),
                    const FieldLabel('Description (Optional)'),
                    AppTextField(
                      controller: _noteCtrl,
                      hint: _type == TransactionType.income
                          ? 'e.g. Monthly Salary'
                          : _type == TransactionType.expense
                              ? 'e.g. Lunch with team'
                              : 'e.g. For savings',
                      icon: Icons.edit_note_rounded,
                    ),
                    const SizedBox(height: 18),
                    const FieldLabel('Date'),
                    FieldBox(
                      onTap: _pickDate,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today_outlined, size: 19, color: context.textSecondary),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(DateFormat('MMM d, yyyy').format(_date),
                                style: jakarta(15, weight: FontWeight.w600, color: context.textPrimary)),
                          ),
                          for (final (label, days) in const [('Today', 0), ('Yesterday', 1)])
                            Padding(
                              padding: const EdgeInsets.only(left: 6),
                              child: GestureDetector(
                                onTap: () => setState(() {
                                  final d = DateTime.now().subtract(Duration(days: days));
                                  _date = DateTime(d.year, d.month, d.day, DateTime.now().hour, DateTime.now().minute);
                                }),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(label,
                                      style: jakarta(11, weight: FontWeight.w700, color: AppColors.primary)),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 6, 20, 14),
                child: GradientButton(label: cta, loading: _saving, onPressed: _save),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryChoice extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _CategoryChoice({
    required this.label,
    required this.icon,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 64,
            height: 64,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: selected ? AppColors.primary : Colors.transparent,
                width: 2.2,
              ),
            ),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withValues(alpha: context.isDark ? 0.18 : 0.12),
              ),
              alignment: Alignment.center,
              child: GlossyIcon(icon: icon, color: color, size: 34, circle: true, iconSize: 19),
            ),
          ),
          const SizedBox(height: 6),
          Text(label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: jakarta(12,
                  weight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected ? AppColors.primary : context.textSecondary)),
        ],
      ),
    );
  }
}
