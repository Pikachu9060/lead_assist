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

  // Add new customer
  static Future<String> addCustomer({
    required String name,
    required String mobileNumber,
    String? email,
    String? address,
    String? company,
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
        'email': email?.trim(),
        'address': address?.trim(),
        'company': company?.trim(),
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

  // Get all customers
  static Stream<QuerySnapshot> getAllCustomers() {
    return _customersCollection
        .orderBy('createdAt', descending: true)
        .snapshots();
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
}