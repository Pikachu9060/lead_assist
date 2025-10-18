import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';

import '../hive/hive_config.dart';
import '../shared/utils/date_utils.dart';

part 'update_model.g.dart';

@HiveType(typeId: HiveConfig.updateModelTypeId)
class UpdateModel {
  @HiveField(0)
  final String updateId;

  @HiveField(1)
  final String enquiryId;

  @HiveField(2)
  final String text;

  @HiveField(3)
  final String updatedBy;

  @HiveField(4)
  final String updatedByName;

  @HiveField(5)
  final DateTime createdAt;

  @HiveField(6)
  final bool isRead;

  UpdateModel({
    required this.updateId,
    required this.enquiryId,
    required this.text,
    required this.updatedBy,
    required this.updatedByName,
    required this.createdAt,
    this.isRead = false,
  });

  factory UpdateModel.fromFirestore(Map<String, dynamic> data, String documentId) {
    return UpdateModel(
      updateId: documentId,
      enquiryId: data['enquiryId'] ?? '',
      text: data['text'] ?? '',
      updatedBy: data['updatedBy'] ?? '',
      updatedByName: data['updatedByName'] ?? '',
      createdAt:  DateUtilHelper.parseTimestamp(data['createdAt']),
      isRead: data['isRead'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'enquiryId': enquiryId,
      'text': text,
      'updatedBy': updatedBy,
      'updatedByName': updatedByName,
      'isRead': isRead,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}