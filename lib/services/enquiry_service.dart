import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/config.dart';
import 'customer_service.dart';

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

  // Add these methods to your existing enquiry_service.dart

  static Future<String> addEnquiryWithCustomer({
    required String customerId,
    required String customerName,
    required String customerMobile,
    required String product,
    required String description,
    required String assignedSalesmanId,
    required String assignedSalesmanName,
  }) async {
    try {
      final docRef = await _enquiries.add({
        'customerId': customerId,
        'customerName': customerName,
        'customerMobile': customerMobile,
        'product': product,
        'description': description,
        'assignedSalesmanId': assignedSalesmanId,
        'assignedSalesmanName': assignedSalesmanName,
        'status': AppConfig.pendingStatus,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Update customer enquiry count
      await CustomerService.updateCustomerEnquiryCount(customerId, increment: true);

      return docRef.id;
    } catch (e) {
      throw 'Failed to add enquiry: $e';
    }
  }

// Get enquiries by customer
  static Stream<QuerySnapshot> getEnquiriesByCustomer(String customerId) {
    return _enquiries
        .where('customerId', isEqualTo: customerId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // Add this method to handle enquiry deletion and cleanup
  static Future<void> deleteEnquiry(String enquiryId, String customerId) async {
    try {
      // First delete all updates in the subcollection
      final updatesSnapshot = await _enquiries
          .doc(enquiryId)
          .collection('updates')
          .get();

      // Delete each update document
      for (final doc in updatesSnapshot.docs) {
        await doc.reference.delete();
      }

      // Then delete the main enquiry document
      await _enquiries.doc(enquiryId).delete();

      // Update customer enquiry count
      await CustomerService.updateCustomerEnquiryCount(customerId, increment: false);
    } catch (e) {
      throw 'Failed to delete enquiry: $e';
    }
  }
}