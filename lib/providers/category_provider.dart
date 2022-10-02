import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:cashpilot/data/models/category_model.dart';
import 'package:cashpilot/data/database/database_helper.dart';

class CategoryProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper.instance;
  static const _uuid = Uuid();

  List<CategoryModel> _categories = [];
  bool _isLoading = false;
  String? _error;

  List<CategoryModel> get categories => List.unmodifiable(_categories);
  bool get isLoading => _isLoading;
  String? get error => _error;

  List<CategoryModel> get incomeCategories =>
      _categories.where((c) => c.type == CategoryType.income).toList();

  List<CategoryModel> get expenseCategories =>
      _categories.where((c) => c.type == CategoryType.expense).toList();

  Future<void> loadCategories() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _categories = await _db.getCategories();
    } catch (e) {
      _error = 'Failed to load categories: $e';
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> addCategory(CategoryModel category) async {
    try {
      final withId = category.copyWith(id: _uuid.v4());
      await _db.insertCategory(withId);
      _categories.add(withId);
      notifyListeners();
    } catch (e) {
      _error = 'Failed to add category: $e';
      notifyListeners();
    }
  }

  Future<void> updateCategory(CategoryModel category) async {
    try {
      await _db.updateCategory(category);
      final idx = _categories.indexWhere((c) => c.id == category.id);
      if (idx != -1) {
        _categories[idx] = category;
        notifyListeners();
      }
    } catch (e) {
      _error = 'Failed to update category: $e';
      notifyListeners();
    }
  }

  Future<void> deleteCategory(String id) async {
    try {
      await _db.deleteCategory(id);
      _categories.removeWhere((c) => c.id == id);
      notifyListeners();
    } catch (e) {
      _error = 'Failed to delete category: $e';
      notifyListeners();
    }
  }

  CategoryModel? getCategoryById(String id) {
    try {
      return _categories.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
