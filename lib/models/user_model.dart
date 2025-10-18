import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';
import 'package:leadassist/shared/utils/date_utils.dart';

import '../hive/hive_config.dart';

part 'user_model.g.dart';

@HiveType(typeId: HiveConfig.userModelTypeId)
class UserModel {
  @HiveField(0)
  final String userId;

  @HiveField(1)
  final String organizationId;

  @HiveField(2)
  final String name;

  @HiveField(3)
  final String email;

  @HiveField(4)
  final String mobileNumber;

  @HiveField(5)
  final String role;

  @HiveField(6)
  final String? region;

  @HiveField(7)
  final bool isActive;

  @HiveField(8)
  final DateTime createdAt;

  @HiveField(9)
  final DateTime updatedAt;

  @HiveField(10)
  final int totalEnquiries;

  @HiveField(11)
  final int completedEnquiries;

  @HiveField(12)
  final int pendingEnquiries;

  @HiveField(13)
  final Map<String, dynamic>? fcmTokens;

  UserModel({
    required this.userId,
    required this.organizationId,
    required this.name,
    required this.email,
    required this.mobileNumber,
    required this.role,
    this.region,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.totalEnquiries = 0,
    this.completedEnquiries = 0,
    this.pendingEnquiries = 0,
    this.fcmTokens,
  });

  factory UserModel.fromFirestore(Map<String, dynamic> data, String documentId) {
    return UserModel(
      userId: documentId,
      organizationId: data['organizationId'] ?? '',
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      mobileNumber: data['mobileNumber'] ?? '',
      role: data['role'] ?? '',
      region: data['region'],
      isActive: data['isActive'] ?? true,
      createdAt: DateUtilHelper.parseTimestamp(data['createdAt']),
      updatedAt: DateUtilHelper.parseTimestamp(data['updatedAt']),
      totalEnquiries: data['totalEnquiries'] ?? 0,
      completedEnquiries: data['completedEnquiries'] ?? 0,
      pendingEnquiries: data['pendingEnquiries'] ?? 0,
      fcmTokens: data['fcmTokens'] != null ? Map<String, dynamic>.from(data['fcmTokens']) : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'organizationId': organizationId,
      'name': name,
      'email': email,
      'mobileNumber': mobileNumber,
      'role': role,
      'region': region,
      'isActive': isActive,
      'totalEnquiries': totalEnquiries,
      'completedEnquiries': completedEnquiries,
      'pendingEnquiries': pendingEnquiries,
      'fcmTokens': fcmTokens,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}