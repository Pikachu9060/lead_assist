import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';

import '../hive/hive_config.dart';
import '../shared/utils/date_utils.dart';

part 'user_notification.g.dart';

@HiveType(typeId: HiveConfig.userNotificationTypeId)
class UserNotificationModel {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String message;

  @HiveField(2)
  bool isRead; // Changed to non-final for updates

  @HiveField(3)
  final DateTime timestamp;

  @HiveField(4)
  final String title;

  @HiveField(5)
  final String userId; // Changed from int to String

  @HiveField(6)
  final DateTime? readAt; // Added for read tracking

  @HiveField(7)
  final String enquiryId;

  UserNotificationModel({
    required this.id,
    required this.message,
    required this.isRead,
    required this.timestamp,
    required this.title,
    required this.userId,
    this.readAt,
    required this.enquiryId
  });

  factory UserNotificationModel.fromFirestore(
      Map<String, dynamic> data,
      String documentId,
      ) {
    return UserNotificationModel(
      id: documentId,
      message: data['message'] ?? '',
      timestamp: DateUtilHelper.parseTimestamp(data['timestamp']),
      isRead: data['isRead'] ?? false,
      userId: data['userId'] ?? '',
      title: data['title'] ?? '',
      readAt: data['readAt'] != null
          ? DateUtilHelper.parseTimestamp(data['readAt'])
          : null,
        enquiryId: data['enquiryId']
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'message': message,
      'timestamp': Timestamp.fromDate(timestamp),
      'userId': userId,
      'isRead': isRead,
      'enquiryId': enquiryId,
      if (readAt != null) 'readAt': Timestamp.fromDate(readAt!),
    };
  }
}