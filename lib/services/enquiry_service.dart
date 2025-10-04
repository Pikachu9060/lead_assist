import 'package:cloud_firestore/cloud_firestore.dart';
import '../config/config.dart';

class EnquiryService {
  static final CollectionReference enquiriesCollection =
  FirebaseFirestore.instance.collection(Config.enquiriesCollection);

  static Future<String> addEnquiry(Map<String, dynamic> enquiryData) async {
    try {
      final docRef = await enquiriesCollection.add({
        ...enquiryData,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'status': 'pending',
      });
      return docRef.id;
    } catch (e) {
      throw 'Failed to add enquiry: $e';
    }
  }

  static Future<void> updateEnquiryStatus(
      String enquiryId, String status) async {
    try {
      await enquiriesCollection.doc(enquiryId).update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw 'Failed to update enquiry: $e';
    }
  }

  static Stream<QuerySnapshot> getEnquiriesForSalesman(String salesmanId) {
    return enquiriesCollection
        .where('assignedSalesmanId', isEqualTo: salesmanId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  static Stream<QuerySnapshot> getAllEnquiries() {
    return enquiriesCollection
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  static Future<DocumentSnapshot> getEnquiryById(String enquiryId) async {
    return await enquiriesCollection.doc(enquiryId).get();
  }
}