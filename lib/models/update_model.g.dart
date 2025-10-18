// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'update_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UpdateModelAdapter extends TypeAdapter<UpdateModel> {
  @override
  final int typeId = 4;

  @override
  UpdateModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UpdateModel(
      updateId: fields[0] as String,
      enquiryId: fields[1] as String,
      text: fields[2] as String,
      updatedBy: fields[3] as String,
      updatedByName: fields[4] as String,
      createdAt: fields[5] as DateTime,
      isRead: fields[6] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, UpdateModel obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.updateId)
      ..writeByte(1)
      ..write(obj.enquiryId)
      ..writeByte(2)
      ..write(obj.text)
      ..writeByte(3)
      ..write(obj.updatedBy)
      ..writeByte(4)
      ..write(obj.updatedByName)
      ..writeByte(5)
      ..write(obj.createdAt)
      ..writeByte(6)
      ..write(obj.isRead);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UpdateModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
