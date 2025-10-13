// core/config.dart
class AppConfig {

  // App Name
  static const String appName = 'Lead Assist';

  // Updated collection names
  static const String usersCollection = 'platform_users';
  static const String customersCollection = 'customers';
  static const String enquiriesCollection = 'enquiries';
  static const String updatesCollection = 'updates';
  static const String organizationsCollection = 'organizations';

  // User roles
  static const String ownerRole = 'owner';
  static const String managerRole = 'manager';
  static const String salesmanRole = 'salesman';

  // Enquiry status
  static const String pendingStatus = 'pending';
  static const String completedStatus = 'completed';
  static const String cancelledStatus = 'cancelled';

  // Regions
  static const List<String> regions = ['Kolhapur', 'Sangli'];
}