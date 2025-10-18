// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UserModelAdapter extends TypeAdapter<UserModel> {
  @override
  final int typeId = 1;

  @override
  UserModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UserModel(
      userId: fields[0] as String,
      organizationId: fields[1] as String,
      name: fields[2] as String,
      email: fields[3] as String,
      mobileNumber: fields[4] as String,
      role: fields[5] as String,
      region: fields[6] as String?,
      isActive: fields[7] as bool,
      createdAt: fields[8] as DateTime,
      updatedAt: fields[9] as DateTime,
      totalEnquiries: fields[10] as int,
      completedEnquiries: fields[11] as int,
      pendingEnquiries: fields[12] as int,
      fcmTokens: (fields[13] as Map?)?.cast<String, dynamic>(),
    );
  }

  @override
  void write(BinaryWriter writer, UserModel obj) {
    writer
      ..writeByte(14)
      ..writeByte(0)
      ..write(obj.userId)
      ..writeByte(1)
      ..write(obj.organizationId)
      ..writeByte(2)
      ..write(obj.name)
      ..writeByte(3)
      ..write(obj.email)
      ..writeByte(4)
      ..write(obj.mobileNumber)
      ..writeByte(5)
      ..write(obj.role)
      ..writeByte(6)
      ..write(obj.region)
      ..writeByte(7)
      ..write(obj.isActive)
      ..writeByte(8)
      ..write(obj.createdAt)
      ..writeByte(9)
      ..write(obj.updatedAt)
      ..writeByte(10)
      ..write(obj.totalEnquiries)
      ..writeByte(11)
      ..write(obj.completedEnquiries)
      ..writeByte(12)
      ..write(obj.pendingEnquiries)
      ..writeByte(13)
      ..write(obj.fcmTokens);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
