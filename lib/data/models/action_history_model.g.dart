// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'action_history_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ActionHistoryAdapter extends TypeAdapter<ActionHistory> {
  @override
  final int typeId = 3;

  @override
  ActionHistory read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ActionHistory(
      id: fields[0] as String,
      actionId: fields[1] as String,
      completedAt: fields[2] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, ActionHistory obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.actionId)
      ..writeByte(2)
      ..write(obj.completedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ActionHistoryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
