import 'dart:async';

import '../hive/hive_data_manager.dart';
import '../models/customer_model.dart';
import '../refactor_services/customer_service.dart';

class CachedCustomerService {
  static final Map<String, StreamSubscription> _subscriptions = {};

  static Future<void> initializeCustomersStream(String organizationId) async {
    if (_subscriptions.containsKey(organizationId)) return;

    final stream = CustomerService.getCustomersStream(organizationId);
    _subscriptions[organizationId] = stream.listen((snapshot) async {
      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        // Add organizationId to the data since it might not be stored in Firestore
        final customerData = {
          ...data,
          'organizationId': organizationId,
        };
        final customerModel = CustomerModel.fromFirestore(customerData, doc.id);
        await HiveDataManager.saveCustomer(customerModel);
      }
    });
  }

  static Future<void> dispose() async {
    for (final subscription in _subscriptions.values) {
      await subscription.cancel();
    }
    _subscriptions.clear();
  }

  // CRUD Operations with Hive Sync
  static Future<String> addCustomer({
    required String organizationId,
    required String name,
    required String mobileNumber,
    required String address,
  }) async {
    final customerId = await CustomerService.addCustomer(
      organizationId: organizationId,
      name: name,
      mobileNumber: mobileNumber,
      address: address,
    );

    // Customer will be automatically cached via stream listener
    return customerId;
  }

  static Future<void> updateCustomer({
    required String organizationId,
    required String customerId,
    required String name,
    required String mobileNumber,
    required String address,
  }) async {
    await CustomerService.updateCustomer(
      organizationId: organizationId,
      customerId: customerId,
      name: name,
      mobileNumber: mobileNumber,
      address: address,
    );

    // Update cache immediately
    final cachedCustomer = await HiveDataManager.getCustomer(customerId);
    if (cachedCustomer != null) {
      final updatedCustomer = CustomerModel(
        customerId: cachedCustomer.customerId,
        organizationId: cachedCustomer.organizationId,
        name: name,
        mobileNumber: mobileNumber,
        address: address,
        totalEnquiries: cachedCustomer.totalEnquiries,
        activeEnquiries: cachedCustomer.activeEnquiries,
        createdAt: cachedCustomer.createdAt,
        updatedAt: DateTime.now(),
      );
      await HiveDataManager.saveCustomer(updatedCustomer);
    }
  }

  static Future<void> deleteCustomer(
      String organizationId,
      String customerId,
      ) async {
    await CustomerService.deleteCustomer(organizationId, customerId);
    await HiveDataManager.deleteCustomer(customerId);
  }

  static Future<void> updateCustomerEnquiryCount(
      String organizationId,
      String customerId, {
        bool increment = true,
      }) async {
    await CustomerService.updateCustomerEnquiryCount(
      organizationId,
      customerId,
      increment: increment,
    );

    // Update cache
    final cachedCustomer = await HiveDataManager.getCustomer(customerId);
    if (cachedCustomer != null) {
      final change = increment ? 1 : -1;
      final updatedCustomer = CustomerModel(
        customerId: cachedCustomer.customerId,
        organizationId: cachedCustomer.organizationId,
        name: cachedCustomer.name,
        mobileNumber: cachedCustomer.mobileNumber,
        address: cachedCustomer.address,
        totalEnquiries: cachedCustomer.totalEnquiries + change,
        activeEnquiries: cachedCustomer.activeEnquiries + change,
        createdAt: cachedCustomer.createdAt,
        updatedAt: DateTime.now(),
      );
      await HiveDataManager.saveCustomer(updatedCustomer);
    }
  }

  // Stream Getters (Read from Hive)
  static Stream<List<CustomerModel>> watchCustomers(String organizationId) {
    return HiveDataManager.watchCustomersByOrganization(organizationId);
  }

  static Stream<List<CustomerModel>> watchCustomersBySearch(String organizationId, String query) {
    return HiveDataManager.watchCustomersByOrganization(organizationId)
        .map((customers) {
      if (query.isEmpty) return customers;
      return customers.where((customer) =>
      customer.name.toLowerCase().contains(query.toLowerCase()) ||
          customer.mobileNumber.contains(query)).toList();
    });
  }

  // Direct Getters (Fallback to network if needed)
  static Future<CustomerModel?> getCustomerById(String organizationId, String customerId) async {
    final cachedCustomer = await HiveDataManager.getCustomer(customerId);
    if (cachedCustomer != null) return cachedCustomer;

    // Fallback to network if not in cache
    final customerDoc = await CustomerService.getCustomerById(organizationId, customerId);
    if (customerDoc.exists) {
      final data = customerDoc.data() as Map<String, dynamic>;
      final customerModel = CustomerModel.fromFirestore(data, customerId);
      await HiveDataManager.saveCustomer(customerModel);
      return customerModel;
    }
    return null;
  }


  static Future<CustomerModel?> getCustomerByMobile(String organizationId, String mobileNumber) async {
    final customers = await HiveDataManager.watchCustomersByOrganization(organizationId).first;
    final cachedCustomer = customers.firstWhere(
          (customer) => customer.mobileNumber == mobileNumber,
      orElse: () => null as CustomerModel,
    );

    if (cachedCustomer != null) return cachedCustomer;

    // Fallback to network
    final customerDoc = await CustomerService.getCustomerByMobile(organizationId, mobileNumber);
    if (customerDoc != null) {
      final customerModel = CustomerModel.fromFirestore(
        customerDoc.data() as Map<String, dynamic>,
        customerDoc.id,
      );
      await HiveDataManager.saveCustomer(customerModel);
      return customerModel;
    }
    return null;
  }

  static Future<bool> doesCustomerExist(String organizationId, String mobileNumber) async {
    final customers = await HiveDataManager.watchCustomersByOrganization(organizationId).first;
    return customers.any((customer) => customer.mobileNumber == mobileNumber);
  }
}