import 'package:hive/hive.dart';

part 'action_model.g.dart';

// 카테고리 타입
@HiveType(typeId: 10)
enum CategoryType {
  @HiveField(0)
  expense, // 지출
  @HiveField(1)
  todo, // 할일
}

// 반복 타입
@HiveType(typeId: 11)
enum RepeatType {
  @HiveField(0)
  weekly, // 매주
  @HiveField(1)
  monthly, // 매월
  @HiveField(2)
  quarterly, // 3개월
  @HiveField(3)
  halfYearly, // 6개월
}

// 푸시 알림 일정
@HiveType(typeId: 12)
enum PushSchedule {
  @HiveField(0)
  sameDay, // 당일
  @HiveField(1)
  oneDayBefore, // 1일 전
  @HiveField(2)
  threeDaysBefore, // 3일 전
  @HiveField(3)
  sevenDaysBefore, // 7일 전
}

@HiveType(typeId: 0)
class Action extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  String? description;

  @HiveField(3)
  CategoryType category;

  @HiveField(4)
  DateTime? date;

  @HiveField(5)
  RepeatType? repeatType;

  @HiveField(6)
  List<PushSchedule> pushSchedules;

  @HiveField(7)
  bool done;

  @HiveField(8)
  int amount;

  @HiveField(9)
  String? repeatGroupId;

  @HiveField(10)
  DateTime? notificationDateTime;

  @HiveField(11)
  String? notificationTime; // HH:mm 포맷 문자열로 저장 (TimeOfDay는 직접 저장 불가)

  // 생성자
  Action({
    required this.id,
    required this.title,
    this.description,
    required this.category,
    this.date,
    this.repeatType,
    this.pushSchedules = const [PushSchedule.sameDay],
    this.done = false,
    this.amount = 0,
    this.repeatGroupId,
    this.notificationDateTime,
    this.notificationTime,
  });

  factory Action.fromJson(Map<String, dynamic> json) => Action(
    id: json['id'] as String,
    title: json['title'] as String,
    description: json['description'] as String?,
    category: CategoryType.values.firstWhere(
      (e) => e.toString() == 'CategoryType.${json['category'] as String}',
    ),
    date: json['date'] != null ? DateTime.tryParse(json['date']) : null,
    repeatType:
        json['repeatType'] != null
            ? RepeatType.values.firstWhere(
              (e) =>
                  e.toString() == 'RepeatType.${json['repeatType'] as String}',
            )
            : null,
    pushSchedules:
        (json['pushSchedules'] as List?)
            ?.map(
              (e) => PushSchedule.values.firstWhere(
                (ps) => ps.toString() == 'PushSchedule.${e as String}',
              ),
            )
            .toList() ??
        [PushSchedule.sameDay],
    done: json['done'] as bool? ?? false,
    amount: json['amount'] as int? ?? 0,
    repeatGroupId: json['repeatGroupId'] as String?,
    notificationDateTime:
        json['notificationDateTime'] != null
            ? DateTime.tryParse(json['notificationDateTime'])
            : null,
    notificationTime: json['notificationTime'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'category': category.name,
    'date': date?.toIso8601String(),
    'repeatType': repeatType?.name,
    'pushSchedules': pushSchedules.map((e) => e.name).toList(),
    'done': done,
    'amount': amount,
    'repeatGroupId': repeatGroupId,
    'notificationDateTime': notificationDateTime?.toIso8601String(),
    'notificationTime': notificationTime,
  };

  Action copyWith({
    String? id,
    String? title,
    String? description,
    CategoryType? category,
    DateTime? date,
    RepeatType? repeatType,
    List<PushSchedule>? pushSchedules,
    bool? done,
    int? amount,
    String? repeatGroupId,
    DateTime? notificationDateTime,
    String? notificationTime,
  }) {
    return Action(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      date: date ?? this.date,
      repeatType: repeatType ?? this.repeatType,
      pushSchedules: pushSchedules ?? this.pushSchedules,
      done: done ?? this.done,
      amount: amount ?? this.amount,
      repeatGroupId: repeatGroupId ?? this.repeatGroupId,
      notificationDateTime: notificationDateTime ?? this.notificationDateTime,
      notificationTime: notificationTime ?? this.notificationTime,
    );
  }
}
