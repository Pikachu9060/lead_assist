import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';
import 'package:leadassist/shared/utils/date_utils.dart';

import '../hive/hive_config.dart';

part 'enquiry_model.g.dart';

@HiveType(typeId: HiveConfig.enquiryModelTypeId)
class EnquiryModel {
  @HiveField(0)
  final String enquiryId;

  @HiveField(1)
  final String organizationId;

  @HiveField(2)
  final String customerId;

  @HiveField(3)
  final String product;

  @HiveField(4)
  final String description;

  @HiveField(5)
  final String assignedSalesmanId;

  @HiveField(6)
  final String status;

  @HiveField(7)
  final DateTime createdAt;

  @HiveField(8)
  final DateTime updatedAt;

  EnquiryModel({
    required this.enquiryId,
    required this.organizationId,
    required this.customerId,
    required this.product,
    required this.description,
    required this.assignedSalesmanId,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory EnquiryModel.fromFirestore(Map<String, dynamic> data, String documentId) {
    return EnquiryModel(
      enquiryId: documentId,
      organizationId: data['organizationId'] ?? '',
      customerId: data['customerId'] ?? '',
      product: data['product'] ?? '',
      description: data['description'] ?? '',
      assignedSalesmanId: data['assignedSalesmanId'] ?? '',
      status: data['status'] ?? 'pending',
      createdAt: DateUtilHelper.parseTimestamp(data['createdAt']),
      updatedAt: DateUtilHelper.parseTimestamp(data['updatedAt']),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'customerId': customerId,
      'product': product,
      'description': description,
      'assignedSalesmanId': assignedSalesmanId,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}