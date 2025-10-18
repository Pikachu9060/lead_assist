import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:leadassist/shared/utils/date_utils.dart';
import '../hive/hive_data_manager.dart';
import '../models/enquiry_model.dart';
import '../models/update_model.dart';
import '../refactor_services/enquiry_service.dart';

class CachedEnquiryService {
  static final _enquiryService = EnquiryService();
  static final Map<String, StreamSubscription> _subscriptions = {};
  static final Map<String, StreamSubscription> _updatesSubscriptions = {};

  static Future<void> initializeEnquiriesStream(String organizationId) async {
    if (_subscriptions.containsKey(organizationId)) return;

    final stream = EnquiryService.getAllEnquiries(organizationId);
    _subscriptions[organizationId] = stream.listen((snapshot) async {
      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;

        // Create enquiry model with organizationId
        final enquiryModel = EnquiryModel(
          enquiryId: doc.id,
          organizationId: organizationId, // Add organizationId here
          customerId: data['customerId'] ?? '',
          product: data['product'] ?? '',
          description: data['description'] ?? '',
          assignedSalesmanId: data['assignedSalesmanId'] ?? '',
          status: data['status'] ?? 'pending',
          createdAt: DateUtilHelper.parseTimestamp(data['createdAt']),
          updatedAt: DateUtilHelper.parseTimestamp(data['updatedAt']),
        );

        await HiveDataManager.saveEnquiry(enquiryModel);
      }
    });
  }

  static Future<void> initializeEnquiryUpdatesStream(String organizationId, String enquiryId) async {
    final key = '$organizationId-$enquiryId';
    if (_updatesSubscriptions.containsKey(key)) return;

    final stream = EnquiryService.getEnquiryUpdates(organizationId, enquiryId);
    _updatesSubscriptions[key] = stream.listen((snapshot) async {
      for (final doc in snapshot.docs) {
        final updateModel = UpdateModel.fromFirestore(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
        await HiveDataManager.saveUpdate(updateModel);
      }
    });
  }

  static Future<void> dispose() async {
    for (final subscription in _subscriptions.values) {
      await subscription.cancel();
    }
    for (final subscription in _updatesSubscriptions.values) {
      await subscription.cancel();
    }
    _subscriptions.clear();
    _updatesSubscriptions.clear();
  }

  // CRUD Operations
  static Future<String> addEnquiry(
      String organizationId,
      Map<String, dynamic> enquiryData,
      ) async {
    return await EnquiryService.addEnquiry(organizationId, enquiryData);
  }

  static Future<String> addEnquiryWithCustomer({
    required String organizationId,
    required String customerId,
    required String customerMobile,
    required String product,
    required String description,
    required String assignedSalesmanId,
  }) async {
    return await EnquiryService.addEnquiryWithCustomer(
      organizationId: organizationId,
      customerId: customerId,
      customerMobile: customerMobile,
      product: product,
      description: description,
      assignedSalesmanId: assignedSalesmanId,
    );
  }


  static Future<void> updateEnquiryStatus(
      String organizationId,
      String enquiryId,
      String status,
      ) async {
    await EnquiryService.updateEnquiryStatus(organizationId, enquiryId, status);

    // Update cache
    final cachedEnquiry = await HiveDataManager.getEnquiry(enquiryId);
    if (cachedEnquiry != null) {
      final updatedEnquiry = EnquiryModel(
        enquiryId: cachedEnquiry.enquiryId,
        organizationId: cachedEnquiry.organizationId,
        customerId: cachedEnquiry.customerId,
        product: cachedEnquiry.product,
        description: cachedEnquiry.description,
        assignedSalesmanId: cachedEnquiry.assignedSalesmanId,
        status: status,
        createdAt: cachedEnquiry.createdAt,
        updatedAt: DateTime.now(),
      );
      await HiveDataManager.saveEnquiry(updatedEnquiry);
    }
  }

  static Future<void> addUpdateToEnquiry({
    required String organizationId,
    required String enquiryId,
    required String updateText,
    required String updatedBy,
    required String updatedByName,
  }) async {
    await EnquiryService.addUpdateToEnquiry(
      organizationId: organizationId,
      enquiryId: enquiryId,
      updateText: updateText,
      updatedBy: updatedBy,
      updatedByName: updatedByName,
    );
  }

  static Future<void> deleteEnquiry(
      String organizationId,
      String enquiryId,
      String customerId,
      ) async {
    await EnquiryService.deleteEnquiry(organizationId, enquiryId, customerId);
    await HiveDataManager.deleteEnquiry(enquiryId);
  }

  // Stream Getters
  static Stream<List<EnquiryModel>> watchAllEnquiries(String organizationId) {
    return HiveDataManager.watchEnquiriesByOrganization(organizationId);
  }

  static Stream<List<EnquiryModel>> watchEnquiriesForSalesman(
      String organizationId,
      String salesmanId,
  {List<String>? status}
      ) {
    return HiveDataManager.watchEnquiriesBySalesman(organizationId, salesmanId, status: status);
  }

  static Stream<List<EnquiryModel>> watchEnquiriesByCustomer(
      String organizationId,
      String customerId,
      ) {
    return HiveDataManager.watchEnquiriesByOrganization(organizationId)
        .map((enquiries) => enquiries.where((enquiry) => enquiry.customerId == customerId).toList());
  }

  static Stream<List<EnquiryModel>> watchEnquiriesByStatus(
      String organizationId,
      List<String> statuses,
      ) {
    return HiveDataManager.watchEnquiriesByStatus(organizationId, statuses);
  }

  static Stream<List<UpdateModel>> watchEnquiryUpdates(
      String organizationId,
      String enquiryId,
      ) {
    // Initialize updates stream if not already done
    initializeEnquiryUpdatesStream(organizationId, enquiryId);
    return HiveDataManager.watchUpdatesByEnquiry(enquiryId);
  }

  // Search
  // Search
  static Stream<List<EnquiryModel>> watchSearchEnquiries({
    required String organizationId,
    required String searchType,
    required String query,
    required List<String> statuses,
    String? salesmanId,
  }) {
    return HiveDataManager.watchEnquiriesByOrganization(organizationId)
        .map((enquiries) {
      var filteredEnquiries = enquiries;

      // Apply salesman filter
      if (salesmanId != null && salesmanId.isNotEmpty) {
        filteredEnquiries = filteredEnquiries
            .where((enquiry) => enquiry.assignedSalesmanId == salesmanId)
            .toList();
      }

      // Apply status filter
      if (statuses.isNotEmpty && !statuses.contains('all')) {
        filteredEnquiries = filteredEnquiries
            .where((enquiry) => statuses.contains(enquiry.status))
            .toList();
      }

      // Apply search filter
      if (query.isNotEmpty) {
        filteredEnquiries = filteredEnquiries.where((enquiry) {
          switch (searchType) {
            case 'salesman':
              return enquiry.assignedSalesmanId.contains(query.toLowerCase());
            case 'customer':
              return enquiry.customerId.contains(query.toLowerCase());
            default:
              return enquiry.product.toLowerCase().contains(query.toLowerCase());
          }
        }).toList();
      }

      // Ensure final list is sorted by updatedAt (newest first)
      filteredEnquiries.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

      return filteredEnquiries;
    });
  }

  // Direct Getters
  static Future<EnquiryModel?> getEnquiryById(
      String organizationId,
      String enquiryId,
      ) async {
    final cachedEnquiry = await HiveDataManager.getEnquiry(enquiryId);
    if (cachedEnquiry != null) return cachedEnquiry;

    // Fallback to network
    final enquiryDoc = await EnquiryService.getEnquiryById(organizationId, enquiryId);
    if (enquiryDoc.exists) {
      final enquiryModel = EnquiryModel.fromFirestore(
        enquiryDoc.data() as Map<String, dynamic>,
        enquiryId,
      );
      await HiveDataManager.saveEnquiry(enquiryModel);
      return enquiryModel;
    }
    return null;
  }

}