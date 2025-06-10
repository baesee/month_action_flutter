import 'package:hive/hive.dart';
import '../models/category_model.dart' as model;
import 'package:flutter/foundation.dart';

class CategoryRepository {
  static const String boxName = 'categories';

  Future<Box<model.Category>> _openBox() async {
    if (Hive.isBoxOpen(boxName)) {
      return Hive.box<model.Category>(boxName);
    } else {
      return await Hive.openBox<model.Category>(boxName);
    }
  }

  // Create
  Future<void> addCategory(model.Category category) async {
    final box = await _openBox();
    await box.put(category.id, category);
  }

  // Read (단일)
  Future<model.Category?> getCategory(String id) async {
    final box = await _openBox();
    return box.get(id);
  }

  // Read (전체)
  Future<List<model.Category>> getAllCategories() async {
    final box = await _openBox();
    return box.values.toList();
  }

  // Update
  Future<void> updateCategory(model.Category category) async {
    final box = await _openBox();
    await box.put(category.id, category);
  }

  // Delete
  Future<void> deleteCategory(String id) async {
    final box = await _openBox();
    await box.delete(id);
  }

  // 이름으로 검색
  Future<List<model.Category>> getCategoriesByName(String name) async {
    final box = await _openBox();
    return box.values.where((c) => c.name == name).toList();
  }

  // 정렬: 이름순
  Future<List<model.Category>> getCategoriesSortedByName({
    bool descending = false,
  }) async {
    final box = await _openBox();
    final list = box.values.toList();
    list.sort((a, b) => a.name.compareTo(b.name));
    if (descending) {
      return list.reversed.toList();
    }
    return list;
  }

  // 전체 삭제
  Future<void> clearAll() async {
    final box = await _openBox();
    await box.clear();
  }

  // 예외 처리 예시 (공통 try-catch 래퍼)
  Future<T?> safeCall<T>(Future<T> Function() fn) async {
    try {
      return await fn();
    } catch (e, s) {
      debugPrint('CategoryRepository error: $e\n$s');
      return null;
    }
  }
}
