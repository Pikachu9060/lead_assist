import 'package:cloud_firestore/cloud_firestore.dart';

class CustomerService {
  static CollectionReference _getCustomersCollection(String organizationId) {
    return FirebaseFirestore.instance
        .collection('organizations')
        .doc(organizationId)
        .collection('customers');
  }

  // Check if customer with mobile already exists in organization
  static Future<bool> doesCustomerExist(String organizationId, String mobileNumber) async {
    try {
      final querySnapshot = await _getCustomersCollection(organizationId)
          .where('mobileNumber', isEqualTo: mobileNumber.trim())
          .limit(1)
          .get();

      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      throw 'Failed to check customer: $e';
    }
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
      final customerExists = await doesCustomerExist(organizationId, mobileNumber);
      if (customerExists) {
        throw 'Customer with mobile number $mobileNumber already exists in this organization';
      }

      final docRef = await _getCustomersCollection(organizationId).add({
        'name': name.trim(),
        'mobileNumber': mobileNumber.trim(),
        'address': address.trim(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'totalEnquiries': 0,
        'activeEnquiries': 0,
      });

      return docRef.id;
    } catch (e) {
      throw e.toString();
    }
  }

  // Get customer by mobile number in organization
  static Future<QueryDocumentSnapshot?> getCustomerByMobile(String organizationId, String mobileNumber) async {
    try {
      final querySnapshot = await _getCustomersCollection(organizationId)
          .where('mobileNumber', isEqualTo: mobileNumber.trim())
          .limit(1)
          .get();

      return querySnapshot.docs.isNotEmpty ? querySnapshot.docs.first : null;
    } catch (e) {
      throw 'Failed to get customer: $e';
    }
  }

  // Get customer by ID in organization
  static Future<DocumentSnapshot> getCustomerById(String organizationId, String customerId) async {
    return await _getCustomersCollection(organizationId).doc(customerId).get();
  }

  // Update customer enquiry counts
  static Future<void> updateCustomerEnquiryCount(String organizationId, String customerId, {bool increment = true}) async {
    try {
      await _getCustomersCollection(organizationId).doc(customerId).update({
        'totalEnquiries': FieldValue.increment(increment ? 1 : -1),
        'activeEnquiries': FieldValue.increment(increment ? 1 : -1),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw 'Failed to update customer count: $e';
    }
  }

  // Search customers by name or mobile in organization
  static Stream<QuerySnapshot> searchCustomers(String organizationId, String query) {
    return _getCustomersCollection(organizationId)
        .where('name', isGreaterThanOrEqualTo: query)
        .where('name', isLessThan: query + 'z')
        .snapshots();
  }

  // Get all customers in organization
  static Future<List<QueryDocumentSnapshot>> getAllCustomers(String organizationId) async {
    try {
      final querySnapshot = await _getCustomersCollection(organizationId)
          .orderBy('createdAt', descending: true)
          .get();
      return querySnapshot.docs;
    } catch (e) {
      throw 'Failed to load customers: $e';
    }
  }

  // Delete customer (hard delete - remove document)
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
      throw 'Failed to delete customer: $e';
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
          .where('mobileNumber', isEqualTo: mobileNumber.trim())
          .where(FieldPath.documentId, isNotEqualTo: customerId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        throw 'Another customer with mobile number $mobileNumber already exists in this organization';
      }

      await _getCustomersCollection(organizationId).doc(customerId).update({
        'name': name.trim(),
        'mobileNumber': mobileNumber.trim(),
        'address': address.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw e.toString();
    }
  }

  // Get customer by ID with error handling
  static Future<Map<String, dynamic>> getCustomer(String organizationId, String customerId) async {
    try {
      final doc = await _getCustomersCollection(organizationId).doc(customerId).get();
      if (!doc.exists) {
        throw 'Customer not found';
      }
      return doc.data() as Map<String, dynamic>;
    } catch (e) {
      throw 'Failed to get customer: $e';
    }
  }
}