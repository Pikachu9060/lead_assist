import '../services/auth_service.dart';
import '../hive/hive_service.dart';
import '../hive/hive_data_manager.dart';
import 'cached_user_service.dart';
import 'cached_customer_service.dart';
import 'cached_enquiry_service.dart';

class CachedDataService {
  static String? _currentOrganizationId;
  static String? _currentUserRole;
  static String? _currentUserId;

  static Future<void> initializeForUser({
    required String userId,
    required String userRole,
    required String organizationId,
  }) async {
    await HiveService.initialize();
    HiveDataManager.initializeStreams();

    _currentOrganizationId = organizationId;
    _currentUserRole = userRole;
    _currentUserId = userId;

    // Initialize all stream subscriptions based on role
    await _initializeRoleBasedSubscriptions(organizationId, userRole, userId);
  }

  static Future<void> _initializeRoleBasedSubscriptions(
      String organizationId,
      String userRole,
      String userId,
      ) async {
    // Always subscribe to users stream
    await CachedUserService.initializeUserStream(organizationId);

    // Always subscribe to customers stream
    await CachedCustomerService.initializeCustomersStream(organizationId);


    // Subscribe to enquiries based on role
    if (userRole == 'admin' || userRole == 'owner') {
      // Admin/Owner can see all enquiries
      await CachedEnquiryService.initializeEnquiriesStream(organizationId);
    } else if (userRole == 'salesman') {
      // Salesman can only see assigned enquiries
      await CachedEnquiryService.initializeEnquiriesStream(organizationId);
    }
  }

  static Future<void> logout() async {
    await CachedUserService.dispose();
    await CachedCustomerService.dispose();
    await CachedEnquiryService.dispose();
    await HiveDataManager.clearAllData();

    await AuthService.logout();
    _currentOrganizationId = null;
    _currentUserRole = null;
    _currentUserId = null;
  }

  static Future<void> clearCache() async {
    await HiveDataManager.clearAllData();
  }

  // Getters for current context
  static String? get currentOrganizationId => _currentOrganizationId;
  static String? get currentUserRole => _currentUserRole;
  static String? get currentUserId => _currentUserId;
}