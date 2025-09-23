import 'package:cloud_firestore/cloud_firestore.dart';

class EnquiryUpdate {
  final String id;
  final String description;
  final DateTime createdAt;
  final String enquiryId;

  EnquiryUpdate({
    required this.id,
    required this.description,
    required this.createdAt,
    required this.enquiryId,
  });

  factory EnquiryUpdate.fromDocument(Map<String, dynamic> doc) {
    final createdAt = doc['created_at'];
    DateTime date;

    // Convert Firestore Timestamp to DateTime
    if (createdAt is Timestamp) {
      date = createdAt.toDate();
    } else if (createdAt is DateTime) {
      date = createdAt;
    } else {
      date = DateTime.now(); // fallback
    }

    return EnquiryUpdate(
      id: doc['id'],
      description: doc['description'] ?? '',
      createdAt: date,
      enquiryId: doc['enquiryId'] ?? '',
    );
  }
}
