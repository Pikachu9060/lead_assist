// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_notification.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UserNotificationModelAdapter extends TypeAdapter<UserNotificationModel> {
  @override
  final int typeId = 5;

  @override
  UserNotificationModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UserNotificationModel(
      id: fields[0] as String,
      message: fields[1] as String,
      isRead: fields[2] as bool,
      timestamp: fields[3] as DateTime,
      title: fields[4] as String,
      userId: fields[5] as String,
      readAt: fields[6] as DateTime?,
      enquiryId: fields[7] as String,
    );
  }

  @override
  void write(BinaryWriter writer, UserNotificationModel obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.message)
      ..writeByte(2)
      ..write(obj.isRead)
      ..writeByte(3)
      ..write(obj.timestamp)
      ..writeByte(4)
      ..write(obj.title)
      ..writeByte(5)
      ..write(obj.userId)
      ..writeByte(6)
      ..write(obj.readAt)
      ..writeByte(7)
      ..write(obj.enquiryId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserNotificationModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
