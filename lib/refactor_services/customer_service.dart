import 'package:cloud_firestore/cloud_firestore.dart';
import '../shared/utils/error_utils.dart';
import '../shared/utils/firestore_utils.dart';

class CustomerService {
  static CollectionReference _getCustomersCollection(String organizationId) {
    return FirestoreUtils.getCustomersCollection(organizationId);
  }

  // Check if customer exists
  static Future<bool> doesCustomerExist(String organizationId, String mobileNumber) async {
    try {
      final querySnapshot = await _getCustomersCollection(organizationId)
          .where('mobileNumber', isEqualTo: FirestoreUtils.trimField(mobileNumber))
          .limit(1)
          .get();
      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      throw ErrorUtils.handleFirestoreError('check customer exists', e);
    }
  }

  // Add customer
  static Future<String> addCustomer({
    required String organizationId,
    required String name,
    required String mobileNumber,
    required String address,
  }) async {
    try {
      // Check if customer already exists
      final customerExists = await doesCustomerExist(organizationId, mobileNumber);
      if (customerExists) {
        throw 'Customer with mobile number $mobileNumber already exists';
      }

      final customerData = FirestoreUtils.addTimestamps({
        'name': FirestoreUtils.trimField(name),
        'mobileNumber': FirestoreUtils.trimField(mobileNumber),
        'address': FirestoreUtils.trimField(address),
        'totalEnquiries': 0,
        'activeEnquiries': 0,
      });

      final docRef = await _getCustomersCollection(organizationId).add(customerData);
      return docRef.id;
    } catch (e) {
      throw ErrorUtils.handleGenericError('add customer', e);
    }
  }

  // Get customer by mobile
  static Future<QueryDocumentSnapshot?> getCustomerByMobile(
      String organizationId,
      String mobileNumber,
      ) async {
    try {
      final querySnapshot = await _getCustomersCollection(organizationId)
          .where('mobileNumber', isEqualTo: FirestoreUtils.trimField(mobileNumber))
          .limit(1)
          .get();
      return querySnapshot.docs.isNotEmpty ? querySnapshot.docs.first : null;
    } catch (e) {
      throw ErrorUtils.handleFirestoreError('get customer by mobile', e);
    }
  }

  // Get customer by ID
  static Future<DocumentSnapshot> getCustomerById(String organizationId, String customerId) async {
    return await _getCustomersCollection(organizationId).doc(customerId).get();
  }

  // Get customers stream
  static Stream<QuerySnapshot> getCustomersStream(String organizationId) {
    return _getCustomersCollection(organizationId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // Search customers
  static Stream<QuerySnapshot> searchCustomers(String organizationId, String query) {
    if (query.isEmpty) {
      return _getCustomersCollection(organizationId)
          .orderBy('createdAt', descending: true)
          .snapshots();
    }

    return _getCustomersCollection(organizationId)
        .where('name', isGreaterThanOrEqualTo: query)
        .where('name', isLessThan: '${query}z')
        .snapshots();
  }

  // Update customer
  static Future<void> updateCustomer({
    required String organizationId,
    required String customerId,
    required String name,
    required String mobileNumber,
    required String address,
  }) async {
    try {
      // Check if mobile number is unique
      final querySnapshot = await _getCustomersCollection(organizationId)
          .where('mobileNumber', isEqualTo: FirestoreUtils.trimField(mobileNumber))
          .where(FieldPath.documentId, isNotEqualTo: customerId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        throw 'Another customer with mobile number $mobileNumber already exists';
      }

      await _getCustomersCollection(organizationId).doc(customerId).update(
        FirestoreUtils.updateTimestamp({
          'name': FirestoreUtils.trimField(name),
          'mobileNumber': FirestoreUtils.trimField(mobileNumber),
          'address': FirestoreUtils.trimField(address),
        }),
      );
    } catch (e) {
      throw ErrorUtils.handleGenericError('update customer', e);
    }
  }

  // Update customer enquiry count
  static Future<void> updateCustomerEnquiryCount(
      String organizationId,
      String customerId, {
        bool increment = true,
      }) async {
    try {
      final change = increment ? 1 : -1;
      await _getCustomersCollection(organizationId).doc(customerId).update(
        FirestoreUtils.updateTimestamp({
          'totalEnquiries': FieldValue.increment(change),
          'activeEnquiries': FieldValue.increment(change),
        }),
      );
    } catch (e) {
      throw ErrorUtils.handleFirestoreError('update customer count', e);
    }
  }

  // Delete customer
  static Future<void> deleteCustomer(String organizationId, String customerId) async {
    try {
      // Check if customer has active enquiries
      final customerDoc = await _getCustomersCollection(organizationId).doc(customerId).get();
      if (customerDoc.exists) {
        final data = customerDoc.data() as Map<String, dynamic>;
        final activeEnquiries = data['activeEnquiries'] ?? 0;

        if (activeEnquiries > 0) {
          throw 'Cannot delete customer with active enquiries';
        }
      }

      await _getCustomersCollection(organizationId).doc(customerId).delete();
    } catch (e) {
      throw ErrorUtils.handleGenericError('delete customer', e);
    }
  }
}