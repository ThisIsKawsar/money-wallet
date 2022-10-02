import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cashpilot/providers/category_provider.dart';
import 'package:cashpilot/data/models/category_model.dart';
import 'package:cashpilot/core/theme/app_colors.dart';
import 'package:cashpilot/core/constants/app_icons.dart';
import 'package:cashpilot/widgets/category_icon.dart';

class CategoryManagementScreen extends StatefulWidget {
  const CategoryManagementScreen({super.key});

  @override
  State<CategoryManagementScreen> createState() =>
      _CategoryManagementScreenState();
}

class _CategoryManagementScreenState
    extends State<CategoryManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CategoryProvider>().loadCategories();
    });
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final catProvider = context.watch<CategoryProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text('Categories',
            style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF1a1a2e))),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: () => _showAddCategory(context, catProvider),
          ),
        ],
        bottom: TabBar(
          controller: _tab,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          tabs: const [Tab(text: 'Expense'), Tab(text: 'Income')],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: [
          _CatList(
              categories: catProvider.expenseCategories,
              isDark: isDark,
              onDelete: (c) =>
                  context.read<CategoryProvider>().deleteCategory(c.id)),
          _CatList(
              categories: catProvider.incomeCategories,
              isDark: isDark,
              onDelete: (c) =>
                  context.read<CategoryProvider>().deleteCategory(c.id)),
        ],
      ),
    );
  }

  Future<void> _showAddCategory(
      BuildContext context, CategoryProvider provider) async {
    final nameCtrl = TextEditingController();
    CategoryType type = CategoryType.expense;
    String selectedColor = '#ff6b6b';
    String selectedIcon = 'remove_circle';

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: const Text('New Category'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: 'Name')),
                const SizedBox(height: 12),
                DropdownButtonFormField<CategoryType>(
                  value: type,
                  items: CategoryType.values
                      .map((t) => DropdownMenuItem(
                          value: t, child: Text(t.name)))
                      .toList(),
                  onChanged: (v) => setS(() => type = v ?? type),
                  decoration:
                      const InputDecoration(labelText: 'Type'),
                ),
                const SizedBox(height: 12),
                const Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Icon')),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: AppIcons.availableIcons.map((ico) {
                    final isSelected = selectedIcon == ico['name'];
                    return GestureDetector(
                      onTap: () =>
                          setS(() => selectedIcon = ico['name']!),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary.withValues(alpha: 0.15)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primary
                                : Colors.transparent,
                          ),
                        ),
                        child: Icon(AppIcons.fromName(ico['name']),
                            size: 22),
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
                child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (nameCtrl.text.trim().isEmpty) return;
                await provider.addCategory(CategoryModel(
                  id: '',
                  name: nameCtrl.text.trim(),
                  icon: selectedIcon,
                  color: selectedColor,
                  type: type,
                  isCustom: true,
                ));
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }
}

class _CatList extends StatelessWidget {
  final List<CategoryModel> categories;
  final bool isDark;
  final void Function(CategoryModel) onDelete;

  const _CatList(
      {required this.categories,
      required this.isDark,
      required this.onDelete});

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) {
      return const Center(child: Text('No categories'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: categories.length,
      itemBuilder: (context, i) {
        final cat = categories[i];
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
          ),
          child: ListTile(
            leading: CategoryIcon(iconName: cat.icon, colorHex: cat.color),
            title: Text(cat.name,
                style: GoogleFonts.inter(
                    fontSize: 14, fontWeight: FontWeight.w500)),
            subtitle: Text(cat.isCustom ? 'Custom' : 'Default',
                style: GoogleFonts.inter(fontSize: 12)),
            trailing: cat.isCustom
                ? IconButton(
                    icon: const Icon(Icons.delete_outline_rounded,
                        color: AppColors.expense),
                    onPressed: () => onDelete(cat),
                  )
                : null,
          ),
        );
      },
    );
  }
}
