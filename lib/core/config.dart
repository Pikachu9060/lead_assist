class AppConfig {
  // Firestore Collections
  static const String usersCollection = 'users';
  static const String enquiriesCollection = 'enquiries';
  static const String salesmenCollection = 'salesmen';
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
}