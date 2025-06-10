import 'package:hive/hive.dart';

part 'notification_model.g.dart';

@HiveType(typeId: 2)
class Notification extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String message;

  @HiveField(2)
  DateTime scheduledTime;

  // 생성자
  Notification({
    required this.id,
    required this.message,
    required this.scheduledTime,
  });

  factory Notification.fromJson(Map<String, dynamic> json) => Notification(
    id: json['id'] as String,
    message: json['message'] as String,
    scheduledTime: DateTime.parse(json['scheduledTime'] as String),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'message': message,
    'scheduledTime': scheduledTime.toIso8601String(),
  };
}
