import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cashpilot/providers/category_provider.dart';
import 'package:cashpilot/data/models/category_model.dart';
import 'package:cashpilot/core/theme/app_colors.dart';
import 'package:cashpilot/core/constants/app_icons.dart';
import 'package:cashpilot/widgets/wavy_background.dart';

class CategoryManagementScreen extends StatefulWidget {
  const CategoryManagementScreen({super.key});

  @override
  State<CategoryManagementScreen> createState() =>
      _CategoryManagementScreenState();
}

class _CategoryManagementScreenState extends State<CategoryManagementScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CategoryProvider>().loadCategories();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final catProvider = context.watch<CategoryProvider>();

    return WavyBackground(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Income categories',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
              TextButton.icon(
                onPressed: () => _showAddCategory(context, catProvider),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Add Category'),
              ),
            ],
          ),
          Divider(
            color: AppColors.primary.withValues(alpha: 0.25),
            height: 10,
          ),
          const SizedBox(height: 6),
          ...catProvider.incomeCategories.map((c) => _CategoryRow(
                category: c,
                isDark: isDark,
                onDelete: () => catProvider.deleteCategory(c.id),
              )),

          const SizedBox(height: 18),
          Text(
            'Expense categories',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
          Divider(
            color: AppColors.primary.withValues(alpha: 0.25),
            height: 16,
          ),
          ...catProvider.expenseCategories.map((c) => _CategoryRow(
                category: c,
                isDark: isDark,
                onDelete: () => catProvider.deleteCategory(c.id),
              )),
        ],
      ),
    );
  }

  Future<void> _showAddCategory(
      BuildContext context, CategoryProvider catProvider) async {
    final nameCtrl = TextEditingController();
    String selectedType = 'expense';
    String selectedIcon = AppIcons.availableIcons.first['name'] as String;
    Color selectedColor = AppColors.categoryColors.first;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: const Text('New Category'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Category Name'),
                ),
                const SizedBox(height: 12),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'expense', label: Text('Expense')),
                    ButtonSegment(value: 'income', label: Text('Income')),
                  ],
                  selected: {selectedType},
                  onSelectionChanged: (s) =>
                      setS(() => selectedType = s.first),
                ),
                const SizedBox(height: 14),
                Text(
                  'Icon',
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 12, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: AppIcons.availableIcons.take(12).map((ic) {
                    final name = ic['name'] as String;
                    final sel = selectedIcon == name;
                    return GestureDetector(
                      onTap: () => setS(() => selectedIcon = name),
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: sel
                              ? AppColors.primary
                              : selectedColor.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          AppIcons.fromName(name),
                          color: sel ? Colors.white : selectedColor,
                          size: 18,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 14),
                Text(
                  'Color',
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 12, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: AppColors.categoryColors.take(8).map((c) {
                    final sel = selectedColor == c;
                    return GestureDetector(
                      onTap: () => setS(() => selectedColor = c),
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: c,
                          shape: BoxShape.circle,
                          border: sel
                              ? Border.all(color: Colors.black, width: 2)
                              : null,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = nameCtrl.text.trim();
                if (name.isEmpty) return;
                final hex =
                    '#${selectedColor.toARGB32().toRadixString(16).substring(2)}';
                await catProvider.addCategory(
                  CategoryModel(
                    id: '',
                    name: name,
                    icon: selectedIcon,
                    color: hex,
                    type: selectedType == 'income'
                        ? CategoryType.income
                        : CategoryType.expense,
                    isCustom: true,
                  ),
                );
                if (ctx.mounted) Navigator.pop(ctx);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  final CategoryModel category;
  final bool isDark;
  final VoidCallback onDelete;

  const _CategoryRow({
    required this.category,
    required this.isDark,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final color = AppColors.fromHex(category.color);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: ListTile(
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        leading: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.16),
            shape: BoxShape.circle,
          ),
          child: Icon(
            AppIcons.fromName(category.icon),
            color: color,
            size: 19,
          ),
        ),
        title: Text(
          category.name,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : AppColors.lightTextPrimary,
          ),
        ),
        trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.more_horiz_rounded, size: 20),
          onSelected: (v) {
            if (v == 'delete') onDelete();
          },
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'delete', child: Text('Delete')),
          ],
        ),
      ),
    );
  }
}
