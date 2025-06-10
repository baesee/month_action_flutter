import 'package:hive/hive.dart';

part 'action_model.g.dart';

@HiveType(typeId: 0)
class Action extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  String description;

  @HiveField(3)
  DateTime date;

  @HiveField(4)
  bool done;

  // 생성자
  Action({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
    this.done = false,
  });

  factory Action.fromJson(Map<String, dynamic> json) => Action(
    id: json['id'] as String,
    title: json['title'] as String,
    description: json['description'] as String,
    date: DateTime.parse(json['date'] as String),
    done: json['done'] as bool? ?? false,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'date': date.toIso8601String(),
    'done': done,
  };

  Action copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? date,
    bool? done,
  }) {
    return Action(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      date: date ?? this.date,
      done: done ?? this.done,
    );
  }
}
