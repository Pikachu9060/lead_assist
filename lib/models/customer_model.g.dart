// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'customer_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CustomerModelAdapter extends TypeAdapter<CustomerModel> {
  @override
  final int typeId = 2;

  @override
  CustomerModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CustomerModel(
      customerId: fields[0] as String,
      organizationId: fields[1] as String,
      name: fields[2] as String,
      mobileNumber: fields[3] as String,
      address: fields[4] as String,
      totalEnquiries: fields[5] as int,
      activeEnquiries: fields[6] as int,
      createdAt: fields[7] as DateTime,
      updatedAt: fields[8] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, CustomerModel obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.customerId)
      ..writeByte(1)
      ..write(obj.organizationId)
      ..writeByte(2)
      ..write(obj.name)
      ..writeByte(3)
      ..write(obj.mobileNumber)
      ..writeByte(4)
      ..write(obj.address)
      ..writeByte(5)
      ..write(obj.totalEnquiries)
      ..writeByte(6)
      ..write(obj.activeEnquiries)
      ..writeByte(7)
      ..write(obj.createdAt)
      ..writeByte(8)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CustomerModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
