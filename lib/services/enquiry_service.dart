import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/config.dart';
import '../shared/utils/error_utils.dart';
import '../shared/utils/firestore_utils.dart';
import 'customer_service.dart';

class EnquiryService {
  static CollectionReference _getEnquiriesCollection(String organizationId) {
    return FirestoreUtils.getEnquiriesCollection(organizationId);
  }

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

  static Future<void> updateEnquiryStatus(String organizationId, String enquiryId, String status) async {
    try {
      await _getEnquiriesCollection(organizationId).doc(enquiryId).update(
          FirestoreUtils.updateTimestamp({
            'status': status,
          })
      );
    } catch (e) {
      throw ErrorUtils.handleGenericError('update enquiry status', e);
    }
  }

  static Stream<QuerySnapshot> getEnquiriesForSalesman(String organizationId, String salesmanId) {
    return _getEnquiriesCollection(organizationId)
        .where('assignedSalesmanId', isEqualTo: salesmanId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  static Stream<QuerySnapshot> getAllEnquiries(String organizationId) {
    return _getEnquiriesCollection(organizationId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  static Future<DocumentSnapshot> getEnquiryById(String organizationId, String enquiryId) async {
    return await _getEnquiriesCollection(organizationId).doc(enquiryId).get();
  }

  static Future<void> addUpdateToEnquiry({
    required String organizationId,
    required String enquiryId,
    required String updateText,
    required String updatedBy,
    required String updatedByName,
  }) async {
    try {
      await _getEnquiriesCollection(organizationId).doc(enquiryId).collection('updates').add(
          FirestoreUtils.addTimestamps({
            'text': updateText,
            'updatedBy': updatedBy,
            'updatedByName': updatedByName,
          }, includeUpdated: false)
      );

      // Also update the main enquiry timestamp
      await _getEnquiriesCollection(organizationId).doc(enquiryId).update(
          FirestoreUtils.updateTimestamp({})
      );
    } catch (e) {
      throw ErrorUtils.handleGenericError('add update', e);
    }
  }

  static Stream<QuerySnapshot> getEnquiryUpdates(String organizationId, String enquiryId) {
    return _getEnquiriesCollection(organizationId)
        .doc(enquiryId)
        .collection('updates')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  static Future<String> addEnquiryWithCustomer({
    required String organizationId,
    required String customerId,
    required String customerName,
    required String customerMobile,
    required String product,
    required String description,
    required String assignedSalesmanId,
    required String assignedSalesmanName,
  }) async {
    try {
      final docRef = await _getEnquiriesCollection(organizationId).add(
          FirestoreUtils.addTimestamps({
            'customerId': customerId,
            'product': product,
            'description': description,
            'assignedSalesmanId': assignedSalesmanId,
            'assignedSalesmanName': assignedSalesmanName,
            'status': AppConfig.pendingStatus,
          })
      );

      // Update customer enquiry count
      await CustomerService.updateCustomerEnquiryCount(organizationId, customerId, increment: true);

      return docRef.id;
    } catch (e) {
      throw ErrorUtils.handleGenericError('add enquiry', e);
    }
  }

  // Get enquiries by customer
  static Stream<QuerySnapshot> getEnquiriesByCustomer(String organizationId, String customerId) {
    return _getEnquiriesCollection(organizationId)
        .where('customerId', isEqualTo: customerId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // Add this method to handle enquiry deletion and cleanup
  static Future<void> deleteEnquiry(String organizationId, String enquiryId, String customerId) async {
    try {
      // First delete all updates in the subcollection
      final updatesSnapshot = await _getEnquiriesCollection(organizationId)
          .doc(enquiryId)
          .collection('updates')
          .get();

      // Delete each update document
      for (final doc in updatesSnapshot.docs) {
        await doc.reference.delete();
      }

      // Then delete the main enquiry document
      await _getEnquiriesCollection(organizationId).doc(enquiryId).delete();

      // Update customer enquiry count
      await CustomerService.updateCustomerEnquiryCount(organizationId, customerId, increment: false);
    } catch (e) {
      throw ErrorUtils.handleGenericError('delete enquiry', e);
    }
  }

  static Stream<QuerySnapshot> getEnquiriesByStatuses(String organizationId, List<String> statuses) {
    final collection = _getEnquiriesCollection(organizationId).orderBy('createdAt', descending: true);

    if (statuses.isEmpty || statuses.contains('all')) {
      return collection.snapshots();
    }

    return collection.where('status', whereIn: statuses).snapshots();
  }

  static Stream<QuerySnapshot> searchEnquiries({
    required String organizationId,
    required String searchType,
    required String query,
    required List<String> statuses,
    String? salesmanId,
  }) {
    Query baseQuery = _getEnquiriesCollection(organizationId).orderBy('createdAt', descending: true);

    // Apply salesman filter if provided
    if (salesmanId != null && salesmanId.isNotEmpty) {
      baseQuery = baseQuery.where('assignedSalesmanId', isEqualTo: salesmanId);
    }

    // If no query, show based on status only
    if (query.trim().isEmpty) {
      if (statuses.isEmpty) return baseQuery.snapshots();
      return baseQuery.where('status', whereIn: statuses).snapshots();
    }

    // Determine the field to search on
    String field;
    switch (searchType) {
      case 'salesman':
        field = 'assignedSalesmanName';
        break;
      case 'customer':
        field = 'customerName';
        break;
      default:
        field = 'product'; // treat as "enquiry name" or "product"
    }

    // Apply status filter if statuses are provided
    if (statuses.isNotEmpty) {
      baseQuery = baseQuery.where('status', whereIn: statuses);
    }

    // Firestore doesn't support "contains" search easily;
    // So we'll simulate simple prefix search using startAt/endAt
    return baseQuery
        .where(field, isGreaterThanOrEqualTo: query)
        .where(field, isLessThanOrEqualTo: '$query\uf8ff')
        .snapshots();
  }
}