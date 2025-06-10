import 'package:hive/hive.dart';
import '../models/notification_model.dart' as model;
import 'package:flutter/foundation.dart';

class NotificationRepository {
  static const String boxName = 'notifications';

  Future<Box<model.Notification>> _openBox() async {
    if (Hive.isBoxOpen(boxName)) {
      return Hive.box<model.Notification>(boxName);
    } else {
      return await Hive.openBox<model.Notification>(boxName);
    }
  }

  // Create
  Future<void> addNotification(model.Notification notification) async {
    final box = await _openBox();
    await box.put(notification.id, notification);
  }

  // Read (단일)
  Future<model.Notification?> getNotification(String id) async {
    final box = await _openBox();
    return box.get(id);
  }

  // Read (전체)
  Future<List<model.Notification>> getAllNotifications() async {
    final box = await _openBox();
    return box.values.toList();
  }

  // Update
  Future<void> updateNotification(model.Notification notification) async {
    final box = await _openBox();
    await box.put(notification.id, notification);
  }

  // Delete
  Future<void> deleteNotification(String id) async {
    final box = await _openBox();
    await box.delete(id);
  }

  // 특정 시간 이후 알림 조회
  Future<List<model.Notification>> getNotificationsAfter(DateTime time) async {
    final box = await _openBox();
    return box.values.where((n) => n.scheduledTime.isAfter(time)).toList();
  }

  // 정렬: 시간순
  Future<List<model.Notification>> getNotificationsSortedByTime({
    bool descending = false,
  }) async {
    final box = await _openBox();
    final list = box.values.toList();
    list.sort((a, b) => a.scheduledTime.compareTo(b.scheduledTime));
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
      debugPrint('NotificationRepository error: $e\n$s');
      return null;
    }
  }
}
