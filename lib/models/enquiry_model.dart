import 'package:cloud_firestore/cloud_firestore.dart';

class Enquiry {
  final String id;
  final String title;
  final String description;
  final String enquiryType;
  final String customerId;     // customer_id
  final String assignedTo;     // salesman_id
  final String status;         // pending/in-progress/done/closed
  final Timestamp? createdAt;
  final Timestamp? updatedAt;

  Enquiry({
    required this.id,
    required this.title,
    required this.description,
    required this.enquiryType,
    required this.customerId,
    required this.assignedTo,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create Enquiry from Firestore document
  factory Enquiry.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Enquiry(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      enquiryType: data['enquiry_type'] ?? '',
      customerId: data['customer_id'] ?? '',
      assignedTo: data['assigned_to'] ?? '',
      status: data['status'] ?? 'pending',
      createdAt: data['created_at'].toDate() ?? '',
      updatedAt: data['updated_at'].toDate() ?? '',
    );
  }

  /// Create Enquiry from a map/JSON
  factory Enquiry.fromJSON(Map<String, dynamic> map) {
    return Enquiry(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      enquiryType: map['enquiry_type'] ?? '',
      customerId: map['customer_id'] ?? '',
      assignedTo: map['assigned_to'] ?? '',
      status: map['status'] ?? 'pending',
      createdAt: map['created_at'] ?? '',
      updatedAt: map['updated_at'],
    );
  }

  /// Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'enquiry_type': enquiryType,
      'customer_id': customerId,
      'assigned_to': assignedTo,
      'status': status,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}
