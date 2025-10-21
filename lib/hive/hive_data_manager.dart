import 'package:hive/hive.dart';
import 'package:leadassist/models/user_notification.dart';
import 'package:rxdart/rxdart.dart';
import '../models/user_model.dart';
import '../models/customer_model.dart';
import '../models/enquiry_model.dart';
import '../models/update_model.dart';
import 'hive_config.dart';

class HiveDataManager {
  // Stream controllers for real-time updates
  static final BehaviorSubject<List<UserModel>> _usersController =
  BehaviorSubject<List<UserModel>>();
  static final BehaviorSubject<List<CustomerModel>> _customersController =
  BehaviorSubject<List<CustomerModel>>();
  static final BehaviorSubject<List<EnquiryModel>> _enquiriesController =
  BehaviorSubject<List<EnquiryModel>>();
  static final BehaviorSubject<List<UpdateModel>> _updatesController =
  BehaviorSubject<List<UpdateModel>>();

  static final BehaviorSubject<List<UserNotificationModel>> _userNotificationsController =
  BehaviorSubject<List<UserNotificationModel>>();

  // User operations (from platform_users collection)
  static Future<void> saveUser(UserModel user) async {
    final box = Hive.box<UserModel>(HiveConfig.usersBox);
    await box.put(user.userId, user);
    _emitUsersUpdate();
  }

  static Future<UserModel?> getUser(String userId) async {
    final box = Hive.box<UserModel>(HiveConfig.usersBox);
    return box.get(userId);
  }

  static Stream<List<UserModel>> watchUsersByOrganization(String organizationId) {
    return _usersController.stream.map((users) =>
        users.where((user) => user.organizationId == organizationId).toList());
  }

  static Stream<List<UserModel>> watchUsersByRole(String organizationId, String role) {
    return _usersController.stream.map((users) => users
        .where((user) => user.organizationId == organizationId && user.role == role && user.isActive)
        .toList());
  }

  static Future<void> deleteUser(String userId) async {
    final box = Hive.box<UserModel>(HiveConfig.usersBox);
    await box.delete(userId);
    _emitUsersUpdate();
  }

  // Customer operations (from organizations/{orgId}/customers)
  static Future<void> saveCustomer(CustomerModel customer) async {
    final box = Hive.box<CustomerModel>(HiveConfig.customersBox);
    await box.put(customer.customerId, customer);
    _emitCustomersUpdate();
  }

  static Future<CustomerModel?> getCustomer(String customerId) async {
    final box = Hive.box<CustomerModel>(HiveConfig.customersBox);
    return box.get(customerId);
  }

  static Stream<List<CustomerModel>> watchCustomersByOrganization(String organizationId) {
    return _customersController.stream.map((customers) =>
        customers.where((customer) => customer.organizationId == organizationId).toList());
  }

  static Future<void> deleteCustomer(String customerId) async {
    final box = Hive.box<CustomerModel>(HiveConfig.customersBox);
    await box.delete(customerId);
    _emitCustomersUpdate();
  }

  // Enquiry operations (from organizations/{orgId}/enquiries)
  static Future<void> saveEnquiry(EnquiryModel enquiry) async {
    final box = Hive.box<EnquiryModel>(HiveConfig.enquiriesBox);
    await box.put(enquiry.enquiryId, enquiry);
    _emitEnquiriesUpdate();
  }

  static Future<EnquiryModel?> getEnquiry(String enquiryId) async {
    final box = Hive.box<EnquiryModel>(HiveConfig.enquiriesBox);
    return box.get(enquiryId);
  }

  static Stream<List<EnquiryModel>> watchEnquiriesByOrganization(String organizationId) {
    return _enquiriesController.stream.map((enquiries) {
      final filteredEnquiries = enquiries
          .where((enquiry) => enquiry.organizationId == organizationId)
          .toList();
      print("Filtered list : ${filteredEnquiries.length}");
      // Sort by updatedAt in descending order (newest first)
      filteredEnquiries.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

      return filteredEnquiries;
    });
  }

  static Stream<List<EnquiryModel>> watchEnquiriesBySalesman(
      String organizationId,
      String salesmanId, {
        List<String>? status,
      }) {
    return _enquiriesController.stream.map((enquiries) {
      var filteredEnquiries = enquiries.where((enquiry) =>
      enquiry.organizationId == organizationId &&
          enquiry.assignedSalesmanId == salesmanId
      ).toList();

      // Apply status filter if provided
      if (status != null && status.isNotEmpty) {
        filteredEnquiries = filteredEnquiries.where((enquiry) =>
            status.contains(enquiry.status)
        ).toList();
      }

      // Sort by updatedAt in descending order (newest first)
      filteredEnquiries.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

      return filteredEnquiries;
    });
  }

  static Stream<List<EnquiryModel>> watchEnquiriesByStatus(String organizationId, List<String> statuses) {
    return _enquiriesController.stream.map((enquiries) {
      final filteredEnquiries = enquiries
          .where((enquiry) => enquiry.organizationId == organizationId && statuses.contains(enquiry.status))
          .toList();

      // Sort by updatedAt in descending order (newest first)
      filteredEnquiries.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

      return filteredEnquiries;
    });
  }

  static Stream<List<EnquiryModel>> watchEnquiriesByCustomer(String organizationId, String customerId) {
    return _enquiriesController.stream.map((enquiries) {
      final filteredEnquiries = enquiries
          .where((enquiry) => enquiry.organizationId == organizationId && enquiry.customerId == customerId)
          .toList();

      // Sort by updatedAt in descending order (newest first)
      filteredEnquiries.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

      return filteredEnquiries;
    });
  }

  static Future<void> deleteEnquiry(String enquiryId) async {
    final box = Hive.box<EnquiryModel>(HiveConfig.enquiriesBox);
    await box.delete(enquiryId);
    _emitEnquiriesUpdate();
  }

  // Update operations (from organizations/{orgId}/enquiries/{enquiryId}/updates)
  static Future<void> saveUpdate(UpdateModel update) async {
    final box = Hive.box<UpdateModel>(HiveConfig.updatesBox);
    await box.put(update.updateId, update);
    _emitUpdatesUpdate();
  }

  static Stream<List<UpdateModel>> watchUpdatesByEnquiry(String enquiryId, String organizationId) {
    final data =  _updatesController.stream.map((updates) =>
        updates.where((update) => update.enquiryId == enquiryId && update.organizationId == organizationId).toList());
    return data;
  }

  static Future<void> deleteUpdate(String updateId) async {
    final box = Hive.box<UpdateModel>(HiveConfig.updatesBox);
    await box.delete(updateId);
    _emitUpdatesUpdate();
  }


// User Notification operations
  static Future<void> saveUserNotification(UserNotificationModel notification) async {
    final box = Hive.box<UserNotificationModel>(HiveConfig.userNotificationBox);
    await box.put(notification.id, notification);
    _emitUserNotificationsUpdate();
  }

  static Future<UserNotificationModel?> getUserNotification(String notificationId) async {
    final box = Hive.box<UserNotificationModel>(HiveConfig.userNotificationBox);
    return box.get(notificationId);
  }

  static Future<List<UserNotificationModel>> getUserNotifications() async {
    final box = Hive.box<UserNotificationModel>(HiveConfig.userNotificationBox);
    return box.values.toList();
  }

  static Stream<List<UserNotificationModel>> watchUserNotifications() {
    return _userNotificationsController.stream.map((notifications){
      notifications.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return notifications;
    });
  }

  static Future<void> deleteUserNotification(String notificationId) async {
    final box = Hive.box<UserNotificationModel>(HiveConfig.userNotificationBox);
    await box.delete(notificationId);
    _emitUserNotificationsUpdate();
  }

// Add to your _emit methods
  static void _emitUserNotificationsUpdate() {
    final box = Hive.box<UserNotificationModel>(HiveConfig.userNotificationBox);
    _userNotificationsController.add(box.values.toList());
  }


  // Emit updates
  static void _emitUsersUpdate() {
    final box = Hive.box<UserModel>(HiveConfig.usersBox);
    _usersController.add(box.values.toList());
  }

  static void _emitCustomersUpdate() {
    final box = Hive.box<CustomerModel>(HiveConfig.customersBox);
    _customersController.add(box.values.toList());
  }

  static void _emitEnquiriesUpdate() {
    final box = Hive.box<EnquiryModel>(HiveConfig.enquiriesBox);
    _enquiriesController.add(box.values.toList());
  }

  static void _emitUpdatesUpdate() {
    final box = Hive.box<UpdateModel>(HiveConfig.updatesBox);
    _updatesController.add(box.values.toList());
  }

  // Initialize streams
  static void initializeStreams() {
    _emitUsersUpdate();
    _emitCustomersUpdate();
    _emitEnquiriesUpdate();
    _emitUpdatesUpdate();
    _emitUserNotificationsUpdate();
  }

  static Future<void> clearAllData() async {
    await Hive.box<UserModel>(HiveConfig.usersBox).clear();
    await Hive.box<CustomerModel>(HiveConfig.customersBox).clear();
    await Hive.box<EnquiryModel>(HiveConfig.enquiriesBox).clear();
    await Hive.box<UpdateModel>(HiveConfig.updatesBox).clear();
    await Hive.box<UserNotificationModel>(HiveConfig.userNotificationBox).clear();

    _emitUsersUpdate();
    _emitCustomersUpdate();
    _emitEnquiriesUpdate();
    _emitUpdatesUpdate();
    _emitUserNotificationsUpdate();
  }
}