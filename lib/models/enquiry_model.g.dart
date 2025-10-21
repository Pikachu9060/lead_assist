// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'enquiry_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class EnquiryModelAdapter extends TypeAdapter<EnquiryModel> {
  @override
  final int typeId = 3;

  @override
  EnquiryModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return EnquiryModel(
      enquiryId: fields[0] as String,
      organizationId: fields[1] as String,
      customerId: fields[2] as String,
      product: fields[3] as String,
      description: fields[4] as String,
      assignedSalesmanId: fields[5] as String,
      status: fields[6] as String,
      createdAt: fields[7] as DateTime,
      updatedAt: fields[8] as DateTime,
      lastUpdatedBy: fields[9] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, EnquiryModel obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.enquiryId)
      ..writeByte(1)
      ..write(obj.organizationId)
      ..writeByte(2)
      ..write(obj.customerId)
      ..writeByte(3)
      ..write(obj.product)
      ..writeByte(4)
      ..write(obj.description)
      ..writeByte(5)
      ..write(obj.assignedSalesmanId)
      ..writeByte(6)
      ..write(obj.status)
      ..writeByte(7)
      ..write(obj.createdAt)
      ..writeByte(8)
      ..write(obj.updatedAt)
      ..writeByte(9)
      ..write(obj.lastUpdatedBy);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EnquiryModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
