// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'action_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ActionAdapter extends TypeAdapter<Action> {
  @override
  final int typeId = 0;

  @override
  Action read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Action(
      id: fields[0] as String,
      title: fields[1] as String,
      description: fields[2] as String?,
      category: fields[3] as CategoryType,
      date: fields[4] as DateTime?,
      repeatType: fields[5] as RepeatType?,
      pushSchedules: (fields[6] as List).cast<PushSchedule>(),
      done: fields[7] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, Action obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.category)
      ..writeByte(4)
      ..write(obj.date)
      ..writeByte(5)
      ..write(obj.repeatType)
      ..writeByte(6)
      ..write(obj.pushSchedules)
      ..writeByte(7)
      ..write(obj.done);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ActionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class CategoryTypeAdapter extends TypeAdapter<CategoryType> {
  @override
  final int typeId = 10;

  @override
  CategoryType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return CategoryType.expense;
      case 1:
        return CategoryType.todo;
      default:
        return CategoryType.expense;
    }
  }

  @override
  void write(BinaryWriter writer, CategoryType obj) {
    switch (obj) {
      case CategoryType.expense:
        writer.writeByte(0);
        break;
      case CategoryType.todo:
        writer.writeByte(1);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CategoryTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class RepeatTypeAdapter extends TypeAdapter<RepeatType> {
  @override
  final int typeId = 11;

  @override
  RepeatType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return RepeatType.weekly;
      case 1:
        return RepeatType.monthly;
      case 2:
        return RepeatType.quarterly;
      case 3:
        return RepeatType.halfYearly;
      default:
        return RepeatType.weekly;
    }
  }

  @override
  void write(BinaryWriter writer, RepeatType obj) {
    switch (obj) {
      case RepeatType.weekly:
        writer.writeByte(0);
        break;
      case RepeatType.monthly:
        writer.writeByte(1);
        break;
      case RepeatType.quarterly:
        writer.writeByte(2);
        break;
      case RepeatType.halfYearly:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RepeatTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class PushScheduleAdapter extends TypeAdapter<PushSchedule> {
  @override
  final int typeId = 12;

  @override
  PushSchedule read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return PushSchedule.sameDay;
      case 1:
        return PushSchedule.oneDayBefore;
      case 2:
        return PushSchedule.threeDaysBefore;
      case 3:
        return PushSchedule.sevenDaysBefore;
      default:
        return PushSchedule.sameDay;
    }
  }

  @override
  void write(BinaryWriter writer, PushSchedule obj) {
    switch (obj) {
      case PushSchedule.sameDay:
        writer.writeByte(0);
        break;
      case PushSchedule.oneDayBefore:
        writer.writeByte(1);
        break;
      case PushSchedule.threeDaysBefore:
        writer.writeByte(2);
        break;
      case PushSchedule.sevenDaysBefore:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PushScheduleAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
