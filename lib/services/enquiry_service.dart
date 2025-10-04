import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/config.dart';

class EnquiryService {
  static final CollectionReference _enquiries =
  FirebaseFirestore.instance.collection(AppConfig.enquiriesCollection);

  static Future<String> addEnquiry(Map<String, dynamic> enquiryData) async {
    try {
      final docRef = await _enquiries.add({
        ...enquiryData,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'status': AppConfig.pendingStatus,
      });
      return docRef.id;
    } catch (e) {
      throw 'Failed to add enquiry: $e';
    }
  }

  static Future<void> updateEnquiryStatus(String enquiryId, String status) async {
    try {
      await _enquiries.doc(enquiryId).update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw 'Failed to update enquiry status: $e';
    }
  }

  static Stream<QuerySnapshot> getEnquiriesForSalesman(String salesmanId) {
    return _enquiries
        .where('assignedSalesmanId', isEqualTo: salesmanId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  static Stream<QuerySnapshot> getAllEnquiries() {
    return _enquiries
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  static Future<DocumentSnapshot> getEnquiryById(String enquiryId) async {
    return await _enquiries.doc(enquiryId).get();
  }

  static Future<void> addUpdateToEnquiry({
    required String enquiryId,
    required String updateText,
    required String updatedBy,
    required String updatedByName,
  }) async {
    try {
      await _enquiries.doc(enquiryId).collection('updates').add({
        'text': updateText,
        'updatedBy': updatedBy,
        'updatedByName': updatedByName,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Also update the main enquiry timestamp
      await _enquiries.doc(enquiryId).update({
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw 'Failed to add update: $e';
    }
  }

  static Stream<QuerySnapshot> getEnquiryUpdates(String enquiryId) {
    return _enquiries
        .doc(enquiryId)
        .collection('updates')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

}