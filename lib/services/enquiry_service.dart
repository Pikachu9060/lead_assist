import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/config.dart';
import '../shared/utils/firestore_utils.dart';
import '../shared/utils/service_utils.dart';
import 'customer_service.dart';

class EnquiryService {
  static CollectionReference _getEnquiriesCollection(String organizationId) {
    return FirestoreUtils.getEnquiriesCollection(organizationId);
  }

  static Future<String> addEnquiry(
      String organizationId,
      Map<String, dynamic> enquiryData,
      ) async {
    return ServiceUtils.handleServiceOperation('add enquiry', () async {
      final dataWithDefaults = ServiceUtils.prepareCreateData({
        ...enquiryData,
        'status': AppConfig.pendingStatus,
      });

      final docRef = await _getEnquiriesCollection(organizationId).add(dataWithDefaults);
      return docRef.id;
    });
  }

  static Future<void> updateEnquiryStatus(
      String organizationId,
      String enquiryId,
      String status,
      ) async {
    return ServiceUtils.handleServiceOperation('update enquiry status', () async {
      await _getEnquiriesCollection(organizationId).doc(enquiryId).update(
        ServiceUtils.prepareUpdateData({'status': status}),
      );
    });
  }

  static Stream<QuerySnapshot> getEnquiriesForSalesman(
      String organizationId,
      String salesmanId,
      ) {
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

  static Future<DocumentSnapshot> getEnquiryById(
      String organizationId,
      String enquiryId,
      ) async {
    return await _getEnquiriesCollection(organizationId).doc(enquiryId).get();
  }

  static Future<void> addUpdateToEnquiry({
    required String organizationId,
    required String enquiryId,
    required String updateText,
    required String updatedBy,
    required String updatedByName,
  }) async {
    return ServiceUtils.handleServiceOperation('add update', () async {
      await _getEnquiriesCollection(organizationId)
          .doc(enquiryId)
          .collection('updates')
          .add(ServiceUtils.prepareCreateData({
        'text': updateText,
        'updatedBy': updatedBy,
        'updatedByName': updatedByName,
      }));

      await _getEnquiriesCollection(organizationId)
          .doc(enquiryId)
          .update(ServiceUtils.prepareUpdateData({}));
    });
  }

  static Stream<QuerySnapshot> getEnquiryUpdates(
      String organizationId,
      String enquiryId,
      ) {
    return _getEnquiriesCollection(organizationId)
        .doc(enquiryId)
        .collection('updates')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  static Future<String> addEnquiryWithCustomer({
    required String organizationId,
    required String customerId,
    required String customerMobile,
    required String product,
    required String description,
    required String assignedSalesmanId,
  }) async {
    return ServiceUtils.handleServiceOperation('add enquiry', () async {
      final enquiryId = await ServiceUtils.runTransaction((transaction) async {
        final enquiryRef = _getEnquiriesCollection(organizationId).doc();
        final enquiryData = ServiceUtils.prepareCreateData({
          'customerId': customerId,
          'product': product,
          'description': description,
          'assignedSalesmanId': assignedSalesmanId,
          'status': AppConfig.pendingStatus,
        });

        transaction.set(enquiryRef, enquiryData);

        final customerRef = FirebaseFirestore.instance
            .collection('organizations')
            .doc(organizationId)
            .collection('customers')
            .doc(customerId);

        final customerDoc = await transaction.get(customerRef);
        if (customerDoc.exists) {
          final currentTotal = (customerDoc.data()!['totalEnquiries'] ?? 0) as int;
          final currentActive = (customerDoc.data()!['activeEnquiries'] ?? 0) as int;

          transaction.update(customerRef, {
            'totalEnquiries': currentTotal + 1,
            'activeEnquiries': currentActive + 1,
          });
        }

        return enquiryRef.id;
      });

      return enquiryId;
    });
  }

  static Stream<QuerySnapshot> getEnquiriesByCustomer(
      String organizationId,
      String customerId,
      ) {
    return _getEnquiriesCollection(organizationId)
        .where('customerId', isEqualTo: customerId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  static Future<void> deleteEnquiry(
      String organizationId,
      String enquiryId,
      String customerId,
      ) async {
    return ServiceUtils.handleServiceOperation('delete enquiry', () async {
      final updatesSnapshot = await _getEnquiriesCollection(organizationId)
          .doc(enquiryId)
          .collection('updates')
          .get();

      for (final doc in updatesSnapshot.docs) {
        await doc.reference.delete();
      }

      await _getEnquiriesCollection(organizationId).doc(enquiryId).delete();

      await CustomerService.updateCustomerEnquiryCount(
        organizationId,
        customerId,
        increment: false,
      );
    });
  }

  static Stream<QuerySnapshot> getEnquiriesByStatuses(
      String organizationId,
      List<String> statuses,
      ) {
    final collection = _getEnquiriesCollection(organizationId)
        .orderBy('createdAt', descending: true);

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
    Query baseQuery = _getEnquiriesCollection(organizationId)
        .orderBy('createdAt', descending: true);

    if (salesmanId != null && salesmanId.isNotEmpty) {
      baseQuery = baseQuery.where('assignedSalesmanId', isEqualTo: salesmanId);
    }

    if (query.trim().isEmpty) {
      if (statuses.isEmpty) return baseQuery.snapshots();
      return baseQuery.where('status', whereIn: statuses).snapshots();
    }

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

    if (statuses.isNotEmpty) {
      baseQuery = baseQuery.where('status', whereIn: statuses);
    }

    return baseQuery
        .where(field, isGreaterThanOrEqualTo: query)
        .where(field, isLessThanOrEqualTo: '$query\uf8ff')
        .snapshots();
  }
}