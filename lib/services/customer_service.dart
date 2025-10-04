import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/config.dart';

class CustomerService {
  static final CollectionReference _customersCollection =
  FirebaseFirestore.instance.collection(AppConfig.customersCollection);

  // Check if customer with mobile already exists
  static Future<bool> doesCustomerExist(String mobileNumber) async {
    try {
      final querySnapshot = await _customersCollection
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
    required String name,
    required String mobileNumber,
    required String address,
  }) async {
    try {
      // Check if customer with same mobile already exists
      final customerExists = await doesCustomerExist(mobileNumber);
      if (customerExists) {
        throw 'Customer with mobile number $mobileNumber already exists';
      }

      final docRef = await _customersCollection.add({
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

  // Get customer by mobile number
  static Future<QueryDocumentSnapshot?> getCustomerByMobile(String mobileNumber) async {
    try {
      final querySnapshot = await _customersCollection
          .where('mobileNumber', isEqualTo: mobileNumber.trim())
          .limit(1)
          .get();

      return querySnapshot.docs.isNotEmpty ? querySnapshot.docs.first : null;
    } catch (e) {
      throw 'Failed to get customer: $e';
    }
  }

  // Get customer by ID
  static Future<DocumentSnapshot> getCustomerById(String customerId) async {
    return await _customersCollection.doc(customerId).get();
  }

  // Update customer enquiry counts
  static Future<void> updateCustomerEnquiryCount(String customerId, {bool increment = true}) async {
    try {
      await _customersCollection.doc(customerId).update({
        'totalEnquiries': FieldValue.increment(increment ? 1 : -1),
        'activeEnquiries': FieldValue.increment(increment ? 1 : -1),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw 'Failed to update customer count: $e';
    }
  }

  // Search customers by name or mobile
  static Stream<QuerySnapshot> searchCustomers(String query) {
    return _customersCollection
        .where('name', isGreaterThanOrEqualTo: query)
        .where('name', isLessThan: query + 'z')
        .snapshots();
  }

  // Add these methods to your existing customer_service.dart

// Get all customers
  static Future<List<QueryDocumentSnapshot>> getAllCustomers() async {
    try {
      final querySnapshot = await _customersCollection
          .orderBy('createdAt', descending: true)
          .get();
      return querySnapshot.docs;
    } catch (e) {
      throw 'Failed to load customers: $e';
    }
  }

// Delete customer (hard delete - remove document)
  static Future<void> deleteCustomer(String customerId) async {
    try {
      // Check if customer has active enquiries
      final customerDoc = await _customersCollection.doc(customerId).get();
      if (customerDoc.exists) {
        final data = customerDoc.data() as Map<String, dynamic>;
        final activeEnquiries = data['activeEnquiries'] ?? 0;

        if (activeEnquiries > 0) {
          throw 'Cannot delete customer with active enquiries';
        }
      }

      await _customersCollection.doc(customerId).delete();
    } catch (e) {
      throw 'Failed to delete customer: $e';
    }
  }

// Update customer profile
  static Future<void> updateCustomer({
    required String customerId,
    required String name,
    required String mobileNumber,
    required String address,
  }) async {
    try {
      // Check if another customer with same mobile exists (excluding current customer)
      final querySnapshot = await _customersCollection
          .where('mobileNumber', isEqualTo: mobileNumber.trim())
          .where(FieldPath.documentId, isNotEqualTo: customerId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        throw 'Another customer with mobile number $mobileNumber already exists';
      }

      await _customersCollection.doc(customerId).update({
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
  static Future<Map<String, dynamic>> getCustomer(String customerId) async {
    try {
      final doc = await _customersCollection.doc(customerId).get();
      if (!doc.exists) {
        throw 'Customer not found';
      }
      return doc.data() as Map<String, dynamic>;
    } catch (e) {
      throw 'Failed to get customer: $e';
    }
  }
}