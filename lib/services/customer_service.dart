import 'package:cloud_firestore/cloud_firestore.dart';
import '../shared/utils/error_utils.dart';
import '../shared/utils/firestore_utils.dart';

class CustomerService {
  static CollectionReference _getCustomersCollection(String organizationId) {
    return FirestoreUtils.getCustomersCollection(organizationId);
  }

  // Check if customer with mobile already exists in organization
  static Future<bool> doesCustomerExist(
    String organizationId,
    String mobileNumber,
  ) async {
    return await FirestoreUtils.doesDocumentExist(
      _getCustomersCollection(organizationId),
      'mobileNumber',
      mobileNumber,
    );
  }

  // Add new customer (only name, mobile, address)
  static Future<String> addCustomer({
    required String organizationId,
    required String name,
    required String mobileNumber,
    required String address,
  }) async {
    try {
      // Check if customer with same mobile already exists in organization
      final customerExists = await doesCustomerExist(
        organizationId,
        mobileNumber,
      );
      if (customerExists) {
        throw 'Customer with mobile number $mobileNumber already exists in this organization';
      }

      final customerData = FirestoreUtils.addTimestamps({
        'name': FirestoreUtils.trimField(name),
        'mobileNumber': FirestoreUtils.trimField(mobileNumber),
        'address': FirestoreUtils.trimField(address),
        'totalEnquiries': 0,
        'activeEnquiries': 0,
      });

      final docRef = await _getCustomersCollection(
        organizationId,
      ).add(customerData);
      return docRef.id;
    } catch (e) {
      throw e.toString();
    }
  }

  // Get customer by mobile number in organization
  static Future<QueryDocumentSnapshot?> getCustomerByMobile(
    String organizationId,
    String mobileNumber,
  ) async {
    final snapshot = await FirestoreUtils.getDocumentByField(
      _getCustomersCollection(organizationId),
      'mobileNumber',
      mobileNumber,
    );
    return snapshot as QueryDocumentSnapshot?;
  }

  // Get customer by ID in organization
  static Future<DocumentSnapshot> getCustomerById(
    String organizationId,
    String customerId,
  ) async {
    return await _getCustomersCollection(organizationId).doc(customerId).get();
  }

  // Update customer enquiry counts
  // customer_service.dart - Fixed count updates with transactions
  static Future<void> updateCustomerEnquiryCount(
    String organizationId,
    String customerId, {
    bool increment = true,
  }) async {
    try {
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final customerRef = _getCustomersCollection(
          organizationId,
        ).doc(customerId);
        final customerDoc = await transaction.get(customerRef);

        if (customerDoc.exists) {
          final data = customerDoc.data() as Map<String, dynamic>?;
          if (data != null) {
            final currentTotal = (data['totalEnquiries'] ?? 0) as int;
            final currentActive = (data['activeEnquiries'] ?? 0) as int;

            transaction.update(
              customerRef,
              FirestoreUtils.updateTimestamp({
                'totalEnquiries': increment
                    ? currentTotal + 1
                    : currentTotal - 1,
                'activeEnquiries': increment
                    ? currentActive + 1
                    : currentActive - 1,
              }),
            );
          }
        }
      });
    } catch (e) {
      throw ErrorUtils.handleFirestoreError('update customer count', e);
    }
  }

  // Search customers by name or mobile in organization
  static Stream<QuerySnapshot> searchCustomers(
    String organizationId,
    String query,
  ) {
    return _getCustomersCollection(organizationId)
        .where('name', isGreaterThanOrEqualTo: query)
        .where('name', isLessThan: '${query}z')
        .snapshots();
  }

  // Get all customers in organization
  static Future<List<QueryDocumentSnapshot>> getAllCustomers(
    String organizationId,
  ) async {
    try {
      final querySnapshot = await _getCustomersCollection(
        organizationId,
      ).orderBy('createdAt', descending: true).get();
      return querySnapshot.docs;
    } catch (e) {
      throw ErrorUtils.handleFirestoreError('load customers', e);
    }
  }

  // Delete customer (hard delete - remove document)
  static Future<void> deleteCustomer(
    String organizationId,
    String customerId,
  ) async {
    try {
      // Check if customer has active enquiries
      final customerDoc = await _getCustomersCollection(
        organizationId,
      ).doc(customerId).get();
      if (customerDoc.exists) {
        final data = customerDoc.data() as Map<String, dynamic>;
        final activeEnquiries = data['activeEnquiries'] ?? 0;

        if (activeEnquiries > 0) {
          throw 'Cannot delete customer with active enquiries';
        }
      }

      await _getCustomersCollection(organizationId).doc(customerId).delete();
    } catch (e) {
      throw ErrorUtils.handleGenericError('Delete customer', e);
    }
  }

  // Update customer profile
  static Future<void> updateCustomer({
    required String organizationId,
    required String customerId,
    required String name,
    required String mobileNumber,
    required String address,
  }) async {
    try {
      // Check if another customer with same mobile exists (excluding current customer)
      final querySnapshot = await _getCustomersCollection(organizationId)
          .where(
            'mobileNumber',
            isEqualTo: FirestoreUtils.trimField(mobileNumber),
          )
          .where(FieldPath.documentId, isNotEqualTo: customerId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        throw 'Another customer with mobile number $mobileNumber already exists in this organization';
      }

      await _getCustomersCollection(organizationId)
          .doc(customerId)
          .update(
            FirestoreUtils.updateTimestamp({
              'name': FirestoreUtils.trimField(name),
              'mobileNumber': FirestoreUtils.trimField(mobileNumber),
              'address': FirestoreUtils.trimField(address),
            }),
          );
    } catch (e) {
      throw e.toString();
    }
  }

  // Get customer by ID with error handling
  static Future<Map<String, dynamic>> getCustomer(
    String organizationId,
    String customerId,
  ) async {
    try {
      final doc = await _getCustomersCollection(
        organizationId,
      ).doc(customerId).get();
      if (!doc.exists) {
        throw 'Customer not found';
      }
      return doc.data() as Map<String, dynamic>;
    } catch (e) {
      throw ErrorUtils.handleFirestoreError('get customer', e);
    }
  }
}
