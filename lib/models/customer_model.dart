import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';

import '../hive/hive_config.dart';
import '../shared/utils/date_utils.dart';

part 'customer_model.g.dart';

@HiveType(typeId: HiveConfig.customerModelTypeId)
class CustomerModel {
  @HiveField(0)
  final String customerId;

  @HiveField(1)
  final String organizationId;

  @HiveField(2)
  final String name;

  @HiveField(3)
  final String mobileNumber;

  @HiveField(4)
  final String address;

  @HiveField(5)
  final int totalEnquiries;

  @HiveField(6)
  final int activeEnquiries;

  @HiveField(7)
  final DateTime createdAt;

  @HiveField(8)
  final DateTime updatedAt;

  CustomerModel({
    required this.customerId,
    required this.organizationId,
    required this.name,
    required this.mobileNumber,
    required this.address,
    this.totalEnquiries = 0,
    this.activeEnquiries = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CustomerModel.fromFirestore(Map<String, dynamic> data, String documentId) {
    return CustomerModel(
      customerId: documentId,
      organizationId: data['organizationId'] ?? '', // This might not be in the document
      name: data['name'] ?? '',
      mobileNumber: data['mobileNumber'] ?? '',
      address: data['address'] ?? '',
      totalEnquiries: data['totalEnquiries'] ?? 0,
      activeEnquiries: data['activeEnquiries'] ?? 0,
      createdAt: DateUtilHelper.parseTimestamp(data['createdAt']),
      updatedAt: DateUtilHelper.parseTimestamp(data['updatedAt']),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'mobileNumber': mobileNumber,
      'address': address,
      'totalEnquiries': totalEnquiries,
      'activeEnquiries': activeEnquiries,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}