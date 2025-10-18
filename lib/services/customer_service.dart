import 'package:cloud_firestore/cloud_firestore.dart';
import '../shared/utils/firestore_utils.dart';
import '../shared/utils/service_utils.dart';

class CustomerService {
  static CollectionReference _getCustomersCollection(String organizationId) {
    return FirestoreUtils.getCustomersCollection(organizationId);
  }

  static Future<bool> doesCustomerExist(
      String organizationId,
      String mobileNumber,
      ) async {
    return ServiceUtils.checkDocumentExists(
      collection: _getCustomersCollection(organizationId),
      field: 'mobileNumber',
      value: mobileNumber,
    );
  }

  static Future<String> addCustomer({
    required String organizationId,
    required String name,
    required String mobileNumber,
    required String address,
  }) async {
    return ServiceUtils.handleServiceOperation('add customer', () async {
      final customerExists = await doesCustomerExist(organizationId, mobileNumber);
      if (customerExists) {
        throw 'Customer with mobile number $mobileNumber already exists in this organization';
      }

      final customerData = ServiceUtils.prepareCreateData({
        'name': ServiceUtils.trimField(name),
        'mobileNumber': ServiceUtils.trimField(mobileNumber),
        'address': ServiceUtils.trimField(address),
        'totalEnquiries': 0,
        'activeEnquiries': 0,
      });

      final docRef = await _getCustomersCollection(organizationId).add(customerData);
      return docRef.id;
    });
  }

  static Future<QueryDocumentSnapshot?> getCustomerByMobile(
      String organizationId,
      String mobileNumber,
      ) async {
    final snapshot = await ServiceUtils.getDocumentByField(
      collection: _getCustomersCollection(organizationId),
      field: 'mobileNumber',
      value: mobileNumber,
    );
    return snapshot as QueryDocumentSnapshot?;
  }

  static Future<DocumentSnapshot> getCustomerById(
      String organizationId,
      String customerId,
      ) async {
    return await _getCustomersCollection(organizationId).doc(customerId).get();
  }

  static Future<void> updateCustomerEnquiryCount(
      String organizationId,
      String customerId, {
        bool increment = true,
      }) async {
    return ServiceUtils.handleServiceOperation('update customer count', () async {
      await ServiceUtils.runTransaction((transaction) async {
        final customerRef = _getCustomersCollection(organizationId).doc(customerId);
        final customerDoc = await transaction.get(customerRef);

        if (customerDoc.exists) {
          final data = customerDoc.data() as Map<String, dynamic>?;
          if (data != null) {
            final currentTotal = (data['totalEnquiries'] ?? 0) as int;
            final currentActive = (data['activeEnquiries'] ?? 0) as int;

            transaction.update(
              customerRef,
              ServiceUtils.prepareUpdateData({
                'totalEnquiries': increment ? currentTotal + 1 : currentTotal - 1,
                'activeEnquiries': increment ? currentActive + 1 : currentActive - 1,
              }),
            );
          }
        }
      });
    });
  }

  static Stream<QuerySnapshot> searchCustomers(
      String organizationId,
      String query,
      ) {
    return _getCustomersCollection(organizationId)
        .where('name', isGreaterThanOrEqualTo: query)
        .where('name', isLessThan: '${query}z')
        .snapshots();
  }

  static Future<List<QueryDocumentSnapshot>> getAllCustomers(String organizationId) async {
    return ServiceUtils.handleServiceOperation('load customers', () async {
      final querySnapshot = await _getCustomersCollection(organizationId)
          .orderBy('createdAt', descending: true)
          .get();
      return querySnapshot.docs;
    });
  }

  static Future<void> deleteCustomer(
      String organizationId,
      String customerId,
      ) async {
    return ServiceUtils.handleServiceOperation('Delete customer', () async {
      final customerDoc = await _getCustomersCollection(organizationId).doc(customerId).get();
      if (customerDoc.exists) {
        final data = customerDoc.data() as Map<String, dynamic>;
        final activeEnquiries = data['activeEnquiries'] ?? 0;

        if (activeEnquiries > 0) {
          throw 'Cannot delete customer with active enquiries';
        }
      }

      await _getCustomersCollection(organizationId).doc(customerId).delete();
    });
  }

  static Future<void> updateCustomer({
    required String organizationId,
    required String customerId,
    required String name,
    required String mobileNumber,
    required String address,
  }) async {
    return ServiceUtils.handleServiceOperation('update customer', () async {
      final mobileExists = await ServiceUtils.checkDocumentExists(
        collection: _getCustomersCollection(organizationId),
        field: 'mobileNumber',
        value: mobileNumber,
        excludeDocumentId: customerId,
      );

      if (mobileExists) {
        throw 'Another customer with mobile number $mobileNumber already exists in this organization';
      }

      await _getCustomersCollection(organizationId).doc(customerId).update(
        ServiceUtils.prepareUpdateData({
          'name': ServiceUtils.trimField(name),
          'mobileNumber': ServiceUtils.trimField(mobileNumber),
          'address': ServiceUtils.trimField(address),
        }),
      );
    });
  }

  static Future<Map<String, dynamic>> getCustomer(
      String organizationId,
      String customerId,
      ) async {
    return ServiceUtils.handleServiceOperation('get customer', () async {
      final doc = await _getCustomersCollection(organizationId).doc(customerId).get();
      if (!doc.exists) throw 'Customer not found';
      return doc.data() as Map<String, dynamic>;
    });
  }
}