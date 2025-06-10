import 'package:hive/hive.dart';

part 'action_history_model.g.dart';

@HiveType(typeId: 3)
class ActionHistory extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String actionId;

  @HiveField(2)
  DateTime completedAt;

  // 생성자
  ActionHistory({
    required this.id,
    required this.actionId,
    required this.completedAt,
  });

  factory ActionHistory.fromJson(Map<String, dynamic> json) => ActionHistory(
    id: json['id'] as String,
    actionId: json['actionId'] as String,
    completedAt: DateTime.parse(json['completedAt'] as String),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'actionId': actionId,
    'completedAt': completedAt.toIso8601String(),
  };
}
