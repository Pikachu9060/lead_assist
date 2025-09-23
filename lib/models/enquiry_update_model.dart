import 'package:cloud_firestore/cloud_firestore.dart';

class EnquiryUpdate {
  final String id;
  final String description;
  final DateTime createdAt;

  EnquiryUpdate({
    required this.id,
    required this.description,
    required this.createdAt,
  });

  factory EnquiryUpdate.fromDocument(Map<String, dynamic> doc) {
    final createdAtField = doc['created_at'];
    DateTime createdAt;

    if (createdAtField is Timestamp) {
      createdAt = createdAtField.toDate();
    } else if (createdAtField is DateTime) {
      createdAt = createdAtField;
    } else {
      createdAt = DateTime.now(); // fallback if missing
    }

    return EnquiryUpdate(
      id: doc['id'] ?? '',
      description: doc['description'] ?? '',
      createdAt: createdAt,
    );
  }
}
