import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
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
import 'package:cashpilot/widgets/category_icon.dart';

const _uuid = Uuid();

class AddTransactionScreen extends StatefulWidget {
  final String? initialType;
  final TransactionModel? transaction;

  const AddTransactionScreen({
    super.key,
    this.initialType,
    this.transaction,
  });

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  CategoryModel? _selectedCategory;
  AccountModel? _selectedAccount;
  AccountModel? _selectedToAccount;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    final initialIndex = widget.initialType == 'income'
        ? 0
        : widget.initialType == 'expense'
            ? 1
            : widget.transaction != null
                ? _typeToIndex(widget.transaction!.type)
                : 1;
    _tabController = TabController(length: 3, vsync: this, initialIndex: initialIndex);

    if (widget.transaction != null) {
      _isEditing = true;
      final tx = widget.transaction!;
      _amountController.text = tx.amount.toStringAsFixed(2);
      _noteController.text = tx.note ?? '';
      _selectedDate = tx.date;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) => _initProviders());
  }

  int _typeToIndex(TransactionType type) {
    switch (type) {
      case TransactionType.income:
        return 0;
      case TransactionType.expense:
        return 1;
      case TransactionType.transfer:
        return 2;
    }
  }

  TransactionType _indexToType(int index) {
    switch (index) {
      case 0:
        return TransactionType.income;
      case 2:
        return TransactionType.transfer;
      default:
        return TransactionType.expense;
    }
  }

  Future<void> _initProviders() async {
    final cats = context.read<CategoryProvider>();
    final accs = context.read<AccountProvider>();
    if (cats.categories.isEmpty) await cats.loadCategories();
    if (accs.accounts.isEmpty) await accs.loadAccounts();

    if (widget.transaction != null && mounted) {
      final tx = widget.transaction!;
      setState(() {
        _selectedCategory = cats.getCategoryById(tx.categoryId);
        _selectedAccount = accs.getAccountById(tx.accountId);
        if (tx.toAccountId != null) {
          _selectedToAccount = accs.getAccountById(tx.toAccountId!);
        }
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final amount = double.tryParse(_amountController.text.replaceAll(',', ''));
    if (amount == null || amount <= 0) {
      _showError('Please enter a valid amount');
      return;
    }

    final type = _indexToType(_tabController.index);
    if (type != TransactionType.transfer && _selectedCategory == null) {
      _showError('Please select a category');
      return;
    }
    if (_selectedAccount == null) {
      _showError('Please select an account');
      return;
    }
    if (type == TransactionType.transfer && _selectedToAccount == null) {
      _showError('Please select destination account');
      return;
    }

    final txProvider = context.read<TransactionProvider>();
    final accProvider = context.read<AccountProvider>();

    if (_isEditing && widget.transaction != null) {
      final updated = widget.transaction!.copyWith(
        type: type,
        amount: amount,
        categoryId: _selectedCategory?.id ?? '0',
        accountId: _selectedAccount!.id,
        toAccountId: _selectedToAccount?.id,
        date: _selectedDate,
        note: _noteController.text.trim().isEmpty
            ? null
            : _noteController.text.trim(),
      );
      await txProvider.updateTransaction(updated);
    } else {
      if (type == TransactionType.transfer) {
        await accProvider.transferBetweenAccounts(
          fromId: _selectedAccount!.id,
          toId: _selectedToAccount!.id,
          amount: amount,
          note: _noteController.text.trim().isEmpty
              ? null
              : _noteController.text.trim(),
        );
      } else {
        final tx = TransactionModel(
          id: _uuid.v4(),
          type: type,
          amount: amount,
          categoryId: _selectedCategory!.id,
          accountId: _selectedAccount!.id,
          date: _selectedDate,
          note: _noteController.text.trim().isEmpty
              ? null
              : _noteController.text.trim(),
          createdAt: DateTime.now(),
        );
        await txProvider.addTransaction(tx);

        // Update account balance
        final acc = _selectedAccount!;
        final delta = type == TransactionType.income ? amount : -amount;
        final updated = acc.copyWith(balance: acc.balance + delta);
        await accProvider.updateAccount(updated);
      }
    }

    if (context.mounted) context.pop();
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppColors.expense),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final settings = context.watch<SettingsProvider>();
    final catProvider = context.watch<CategoryProvider>();
    final accProvider = context.watch<AccountProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEditing ? 'Edit Transaction' : 'Add Transaction',
          style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF1a1a2e)),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: isDark
              ? Colors.white.withValues(alpha: 0.5)
              : Colors.black.withValues(alpha: 0.5),
          labelStyle:
              GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
          tabs: const [
            Tab(text: 'Income'),
            Tab(text: 'Expense'),
            Tab(text: 'Transfer'),
          ],
          onTap: (_) => setState(() => _selectedCategory = null),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Amount input
            _AmountField(
              controller: _amountController,
              symbol: settings.currencySymbol,
              isDark: isDark,
              onChanged: () => setState(() {}),
            ),
            const SizedBox(height: 24),

            // Category (not for transfer)
            AnimatedBuilder(
              animation: _tabController,
              builder: (context, _) {
                if (_tabController.index == 2) return const SizedBox.shrink();
                final isIncome = _tabController.index == 0;
                final categories = isIncome
                    ? catProvider.incomeCategories
                    : catProvider.expenseCategories;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionLabel('Category', isDark),
                    const SizedBox(height: 12),
                    _CategoryGrid(
                      categories: categories,
                      selected: _selectedCategory,
                      onSelect: (c) =>
                          setState(() => _selectedCategory = c),
                    ),
                    const SizedBox(height: 24),
                  ],
                );
              },
            ),

            _sectionLabel('Account', isDark),
            const SizedBox(height: 12),
            _AccountSelector(
              accounts: accProvider.accounts,
              selected: _selectedAccount,
              onSelect: (a) => setState(() => _selectedAccount = a),
              isDark: isDark,
            ),
            const SizedBox(height: 24),

            // To account (transfer only)
            AnimatedBuilder(
              animation: _tabController,
              builder: (context, _) {
                if (_tabController.index != 2) {
                  return const SizedBox.shrink();
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionLabel('To Account', isDark),
                    const SizedBox(height: 12),
                    _AccountSelector(
                      accounts: accProvider.accounts
                          .where((a) => a.id != _selectedAccount?.id)
                          .toList(),
                      selected: _selectedToAccount,
                      onSelect: (a) =>
                          setState(() => _selectedToAccount = a),
                      isDark: isDark,
                    ),
                    const SizedBox(height: 24),
                  ],
                );
              },
            ),

            _sectionLabel('Date', isDark),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: _pickDate,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkCardAlt
                      : AppColors.lightCardAlt,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark
                        ? AppColors.darkBorder
                        : AppColors.lightBorder,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_rounded,
                        size: 18, color: AppColors.primary),
                    const SizedBox(width: 12),
                    Text(
                      '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: isDark
                            ? Colors.white
                            : const Color(0xFF1a1a2e),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            _sectionLabel('Note (optional)', isDark),
            const SizedBox(height: 12),
            TextField(
              controller: _noteController,
              maxLines: 2,
              style: GoogleFonts.inter(fontSize: 14),
              decoration: const InputDecoration(
                hintText: 'Add a note...',
              ),
            ),
            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: Text(
                  _isEditing ? 'Update' : 'Save Transaction',
                  style: GoogleFonts.inter(
                      fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String text, bool isDark) => Text(
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

class _AmountField extends StatelessWidget {
  final TextEditingController controller;
  final String symbol;
  final bool isDark;
  final VoidCallback onChanged;

  const _AmountField({
    required this.controller,
    required this.symbol,
    required this.isDark,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.15),
            AppColors.primaryLight.withValues(alpha: 0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        children: [
          Text(
            symbol,
            style: GoogleFonts.inter(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              style: GoogleFonts.inter(
                fontSize: 36,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF1a1a2e),
              ),
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: '0.00',
                hintStyle: GoogleFonts.inter(
                  fontSize: 36,
                  fontWeight: FontWeight.w700,
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.3)
                      : Colors.black.withValues(alpha: 0.2),
                ),
                fillColor: Colors.transparent,
                filled: true,
              ),
              onChanged: (_) => onChanged(),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryGrid extends StatelessWidget {
  final List<CategoryModel> categories;
  final CategoryModel? selected;
  final void Function(CategoryModel) onSelect;

  const _CategoryGrid({
    required this.categories,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.85,
      ),
      itemCount: categories.length,
      itemBuilder: (context, i) {
        final cat = categories[i];
        final isSelected = selected?.id == cat.id;
        final color = AppColors.fromHex(cat.color);
        return GestureDetector(
          onTap: () => onSelect(cat),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: isSelected
                  ? color.withValues(alpha: 0.2)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isSelected ? color : Colors.transparent,
                width: 1.5,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CategoryIcon(
                  iconName: cat.icon,
                  colorHex: cat.color,
                  size: 40,
                  iconSize: 18,
                ),
                const SizedBox(height: 6),
                Text(
                  cat.name,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: isSelected
                        ? color
                        : Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.7),
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _AccountSelector extends StatelessWidget {
  final List<AccountModel> accounts;
  final AccountModel? selected;
  final void Function(AccountModel) onSelect;
  final bool isDark;

  const _AccountSelector({
    required this.accounts,
    required this.selected,
    required this.onSelect,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: accounts.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final acc = accounts[i];
          final isSelected = selected?.id == acc.id;
          final color = AppColors.fromHex(acc.color);
          return GestureDetector(
            onTap: () => onSelect(acc),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? color.withValues(alpha: 0.15)
                    : isDark
                        ? AppColors.darkCardAlt
                        : AppColors.lightCardAlt,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? color : Colors.transparent,
                  width: 1.5,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(AppIcons.fromName(acc.icon),
                      size: 18, color: color),
                  const SizedBox(width: 8),
                  Text(
                    acc.name,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: isSelected
                          ? color
                          : isDark
                              ? Colors.white
                              : const Color(0xFF1a1a2e),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
