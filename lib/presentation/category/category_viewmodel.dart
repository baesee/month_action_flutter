import 'package:flutter/material.dart';
import '../../data/models/category_model.dart';
import '../../data/repositories/category_repository.dart';

class CategoryViewModel extends ChangeNotifier {
  final CategoryRepository _repository;
  List<Category> _categories = [];
  bool _isLoading = false;
  String? _error;

  List<Category> get categories => _categories;
  bool get isLoading => _isLoading;
  String? get error => _error;

  CategoryViewModel({CategoryRepository? repository})
    : _repository = repository ?? CategoryRepository();

  Future<void> loadCategories() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _categories = await _repository.getCategoriesSortedByName();
    } catch (e) {
      _error = '카테고리 불러오기 실패: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addCategory(Category category) async {
    try {
      await _repository.addCategory(category);
      await loadCategories();
    } catch (e) {
      _error = '카테고리 추가 실패: $e';
      notifyListeners();
    }
  }

  Future<void> updateCategory(Category category) async {
    try {
      await _repository.updateCategory(category);
      await loadCategories();
    } catch (e) {
      _error = '카테고리 수정 실패: $e';
      notifyListeners();
    }
  }

  Future<void> deleteCategory(String id) async {
    try {
      await _repository.deleteCategory(id);
      await loadCategories();
    } catch (e) {
      _error = '카테고리 삭제 실패: $e';
      notifyListeners();
    }
  }
}
