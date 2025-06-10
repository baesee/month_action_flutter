import 'package:hive/hive.dart';
import '../models/action_history_model.dart' as model;
import 'package:flutter/foundation.dart';

class ActionHistoryRepository {
  static const String boxName = 'action_histories';

  Future<Box<model.ActionHistory>> _openBox() async {
    if (Hive.isBoxOpen(boxName)) {
      return Hive.box<model.ActionHistory>(boxName);
    } else {
      return await Hive.openBox<model.ActionHistory>(boxName);
    }
  }

  // Create
  Future<void> addActionHistory(model.ActionHistory history) async {
    final box = await _openBox();
    await box.put(history.id, history);
  }

  // Read (단일)
  Future<model.ActionHistory?> getActionHistory(String id) async {
    final box = await _openBox();
    return box.get(id);
  }

  // Read (전체)
  Future<List<model.ActionHistory>> getAllActionHistories() async {
    final box = await _openBox();
    return box.values.toList();
  }

  // Update
  Future<void> updateActionHistory(model.ActionHistory history) async {
    final box = await _openBox();
    await box.put(history.id, history);
  }

  // Delete
  Future<void> deleteActionHistory(String id) async {
    final box = await _openBox();
    await box.delete(id);
  }

  // 특정 ActionId로 조회
  Future<List<model.ActionHistory>> getHistoriesByActionId(
    String actionId,
  ) async {
    final box = await _openBox();
    return box.values.where((h) => h.actionId == actionId).toList();
  }

  // 정렬: 완료일시순
  Future<List<model.ActionHistory>> getHistoriesSortedByCompletedAt({
    bool descending = false,
  }) async {
    final box = await _openBox();
    final list = box.values.toList();
    list.sort((a, b) => a.completedAt.compareTo(b.completedAt));
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
      debugPrint('ActionHistoryRepository error: $e\n$s');
      return null;
    }
  }
}
