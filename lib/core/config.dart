class AppConfig {
  // Firestore Collections - SEPARATED
  static const String adminCollection = 'admins';
  static const String salesmenCollection = 'salesmen';
  static const String customersCollection = 'customers';
  static const String enquiriesCollection = 'enquiries';
  static const String updatesCollection = 'updates';

  // App Constants
  static const String appName = 'Lead Assist';
  static const String adminRole = 'admin';
  static const String salesmanRole = 'salesman';

  // Enquiry Status
  static const String pendingStatus = 'pending';
  static const String inProgressStatus = 'in_progress';
  static const String completedStatus = 'completed';
  static const String cancelledStatus = 'cancelled';

  // Regions List
  static const List<String> regions = [
    'North Region',
    'South Region',
    'East Region',
    'West Region',
    'Central Region',
    'Metro Region',
    'Rural Region',
    'International',
  ];
}