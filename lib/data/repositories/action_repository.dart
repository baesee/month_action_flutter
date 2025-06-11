import 'package:hive/hive.dart';
import '../models/action_model.dart';
import 'package:flutter/foundation.dart';

class ActionRepository {
  static const String boxName = 'actions';

  Future<Box<Action>> _openBox() async {
    if (Hive.isBoxOpen(boxName)) {
      return Hive.box<Action>(boxName);
    } else {
      return await Hive.openBox<Action>(boxName);
    }
  }

  // Create
  Future<void> addAction(Action action) async {
    final box = await _openBox();
    await box.put(action.id, action);
  }

  // Read (단일)
  Future<Action?> getAction(String id) async {
    final box = await _openBox();
    return box.get(id);
  }

  // Read (전체)
  Future<List<Action>> getAllActions() async {
    final box = await _openBox();
    return box.values.toList();
  }

  // Update
  Future<void> updateAction(Action action) async {
    final box = await _openBox();
    await box.put(action.id, action);
  }

  // Delete
  Future<void> deleteAction(String id) async {
    final box = await _openBox();
    await box.delete(id);
  }

  // 필터: 특정 날짜 (연/월/일만 비교)
  Future<List<Action>> getActionsByDate(DateTime date) async {
    final box = await _openBox();
    return box.values
        .where(
          (a) =>
              a.date != null &&
              a.date!.year == date.year &&
              a.date!.month == date.month &&
              a.date!.day == date.day,
        )
        .toList();
  }

  // 필터: 주간(시작~끝 날짜 범위)
  Future<List<Action>> getActionsByWeek(DateTime start, DateTime end) async {
    final box = await _openBox();
    return box.values.where((a) {
      final d = a.date;
      if (d == null) return false;
      return !d.isBefore(start) && !d.isAfter(end);
    }).toList();
  }

  // 정렬: 날짜순
  Future<List<Action>> getActionsSortedByDate({bool descending = false}) async {
    final box = await _openBox();
    final list = box.values.where((a) => a.date != null).toList();
    list.sort((a, b) => a.date!.compareTo(b.date!));
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
      debugPrint('ActionRepository error: $e\n$s');
      return null;
    }
  }

  // 월별 행동 조회
  Future<List<Action>> getActionsByMonth(DateTime month) async {
    final box = await _openBox();
    return box.values
        .where(
          (a) =>
              a.date != null &&
              a.date!.year == month.year &&
              a.date!.month == month.month,
        )
        .toList();
  }
}
