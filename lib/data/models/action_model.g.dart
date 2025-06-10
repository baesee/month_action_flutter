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
      description: fields[2] as String,
      date: fields[3] as DateTime,
      done: fields[4] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, Action obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.date)
      ..writeByte(4)
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
