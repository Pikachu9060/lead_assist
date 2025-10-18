import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/config.dart';
import '../shared/utils/error_utils.dart';
import '../shared/utils/firestore_utils.dart';

class EnquiryService {
  static CollectionReference _getEnquiriesCollection(String organizationId) {
    return FirestoreUtils.getEnquiriesCollection(organizationId);
  }

  // Add enquiry
  static Future<String> addEnquiry(String organizationId, Map<String, dynamic> enquiryData) async {
    try {
      final dataWithDefaults = FirestoreUtils.addTimestamps({
        ...enquiryData,
        'status': AppConfig.pendingStatus,
      });

      final docRef = await _getEnquiriesCollection(organizationId).add(dataWithDefaults);
      return docRef.id;
    } catch (e) {
      throw ErrorUtils.handleGenericError('add enquiry', e);
    }
  }

  // Add enquiry with customer
  static Future<String> addEnquiryWithCustomer({
    required String organizationId,
    required String customerId,
    required String customerMobile,
    required String product,
    required String description,
    required String assignedSalesmanId,
  }) async {
    try {
      return await FirebaseFirestore.instance.runTransaction((transaction) async {
        // Create enquiry
        final enquiryRef = _getEnquiriesCollection(organizationId).doc();
        final enquiryData = FirestoreUtils.addTimestamps({
          'customerId': customerId,
          'product': product,
          'description': description,
          'assignedSalesmanId': assignedSalesmanId,
          'status': AppConfig.pendingStatus,
        });

        transaction.set(enquiryRef, enquiryData);

        // Update customer counts
        final customerRef = FirebaseFirestore.instance
            .collection('organizations')
            .doc(organizationId)
            .collection('customers')
            .doc(customerId);

        final customerDoc = await transaction.get(customerRef);
        if (customerDoc.exists) {
          transaction.update(customerRef, {
            'totalEnquiries': FieldValue.increment(1),
            'activeEnquiries': FieldValue.increment(1),
          });
        }

        return enquiryRef.id;
      });
    } catch (e) {
      throw ErrorUtils.handleGenericError('add enquiry with customer', e);
    }
  }

  // Update enquiry status
  static Future<void> updateEnquiryStatus(
      String organizationId,
      String enquiryId,
      String status,
      ) async {
    try {
      await _getEnquiriesCollection(organizationId)
          .doc(enquiryId)
          .update(FirestoreUtils.updateTimestamp({'status': status}));
    } catch (e) {
      throw ErrorUtils.handleGenericError('update enquiry status', e);
    }
  }

  // Get enquiry by ID
  static Future<DocumentSnapshot> getEnquiryById(String organizationId, String enquiryId) async {
    return await _getEnquiriesCollection(organizationId).doc(enquiryId).get();
  }

  // Get all enquiries stream
  static Stream<QuerySnapshot> getAllEnquiries(String organizationId) {
    return _getEnquiriesCollection(organizationId)
        .orderBy('updatedAt', descending: true)
        .snapshots();
  }

  // Get enquiries for salesman
  static Stream<QuerySnapshot> getEnquiriesForSalesman(String organizationId, String salesmanId) {
    return _getEnquiriesCollection(organizationId)
        .where('assignedSalesmanId', isEqualTo: salesmanId)
        .orderBy('updatedAt', descending: true)
        .snapshots();
  }

  // Get enquiries by customer
  static Stream<QuerySnapshot> getEnquiriesByCustomer(String organizationId, String customerId) {
    return _getEnquiriesCollection(organizationId)
        .where('customerId', isEqualTo: customerId)
        .orderBy('updatedAt', descending: true)
        .snapshots();
  }

  // Add update to enquiry
  static Future<void> addUpdateToEnquiry({
    required String organizationId,
    required String enquiryId,
    required String updateText,
    required String updatedBy,
    required String updatedByName,
  }) async {
    try {
      await _getEnquiriesCollection(organizationId)
          .doc(enquiryId)
          .collection('updates')
          .add(FirestoreUtils.addTimestamps({
        'text': updateText,
        'updatedBy': updatedBy,
        'updatedByName': updatedByName,
      }));

      // Update main enquiry timestamp
      await _getEnquiriesCollection(organizationId)
          .doc(enquiryId)
          .update(FirestoreUtils.updateTimestamp({}));
    } catch (e) {
      throw ErrorUtils.handleGenericError('add update to enquiry', e);
    }
  }

  // Get enquiry updates
  static Stream<QuerySnapshot> getEnquiryUpdates(String organizationId, String enquiryId) {
    return _getEnquiriesCollection(organizationId)
        .doc(enquiryId)
        .collection('updates')
        .orderBy('updatedAt', descending: true)
        .snapshots();
  }

  // Delete enquiry
  static Future<void> deleteEnquiry(
      String organizationId,
      String enquiryId,
      String customerId,
      ) async {
    try {
      // Delete all updates first
      final updatesSnapshot = await _getEnquiriesCollection(organizationId)
          .doc(enquiryId)
          .collection('updates')
          .get();

      for (final doc in updatesSnapshot.docs) {
        await doc.reference.delete();
      }

      // Delete main enquiry
      await _getEnquiriesCollection(organizationId).doc(enquiryId).delete();
    } catch (e) {
      throw ErrorUtils.handleGenericError('delete enquiry', e);
    }
  }

  // Search enquiries
  static Stream<QuerySnapshot> searchEnquiries({
    required String organizationId,
    required String searchType,
    required String query,
    required List<String> statuses,
    String? salesmanId,
  }) {
    Query baseQuery = _getEnquiriesCollection(organizationId)
        .orderBy('createdAt', descending: true);

    // Apply salesman filter
    if (salesmanId != null && salesmanId.isNotEmpty) {
      baseQuery = baseQuery.where('assignedSalesmanId', isEqualTo: salesmanId);
    }

    // If no query, return based on status
    if (query.trim().isEmpty) {
      if (statuses.isEmpty || statuses.contains('all')) {
        return baseQuery.snapshots();
      }
      return baseQuery.where('status', whereIn: statuses).snapshots();
    }

    // Determine search field
    String field;
    switch (searchType) {
      case 'salesman':
        field = 'assignedSalesmanName';
        break;
      case 'customer':
        field = 'customerName';
        break;
      default:
        field = 'product';
    }

    // Apply status filter
    if (statuses.isNotEmpty && !statuses.contains('all')) {
      baseQuery = baseQuery.where('status', whereIn: statuses);
    }

    // Apply search
    return baseQuery
        .where(field, isGreaterThanOrEqualTo: query)
        .where(field, isLessThanOrEqualTo: '$query\uf8ff')
        .snapshots();
  }
}