import 'package:hive/hive.dart';

part 'category_model.g.dart';

@HiveType(typeId: 1)
class Category extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  // 생성자
  Category({required this.id, required this.name});

  factory Category.fromJson(Map<String, dynamic> json) =>
      Category(id: json['id'] as String, name: json['name'] as String);

  Map<String, dynamic> toJson() => {'id': id, 'name': name};
}
