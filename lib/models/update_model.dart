import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';
import 'package:leadassist/shared/utils/date_utils.dart';
import '../hive/hive_config.dart';

part 'update_model.g.dart';

@HiveType(typeId: HiveConfig.updateModelTypeId)
class UpdateModel {
  @HiveField(0)
  final String updateId;

  @HiveField(1)
  final String enquiryId;

  @HiveField(2)
  final String organizationId;

  @HiveField(3)
  final String text;

  @HiveField(4)
  final String updatedBy;

  @HiveField(5)
  final String updatedByName;

  @HiveField(6)
  final DateTime createdAt;

  @HiveField(7)
  final DateTime updatedAt;

  UpdateModel({
    required this.updateId,
    required this.enquiryId,
    required this.organizationId,
    required this.text,
    required this.updatedBy,
    required this.updatedByName,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UpdateModel.fromFirestore(Map<String, dynamic> data, String documentId) {
    return UpdateModel(
      updateId: documentId,
      enquiryId: data['enquiryId'] ?? '',
      organizationId: data['organizationId'] ?? '',
      text: data['text'] ?? '',
      updatedBy: data['updatedBy'] ?? '',
      updatedByName: data['updatedByName'] ?? '',
      createdAt: DateUtilHelper.parseTimestamp(data['createdAt']),
      updatedAt: DateUtilHelper.parseTimestamp(data['updatedAt']),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'enquiryId': enquiryId,
      'organizationId': organizationId,
      'text': text,
      'updatedBy': updatedBy,
      'updatedByName': updatedByName,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}