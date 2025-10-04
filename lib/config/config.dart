class Config {
  // Add these to your environment variables or use flutter --dart-define
  static const String notificationServerKey =
  String.fromEnvironment('NOTIFICATION_SERVER_KEY');

  // Firestore collections
  static const String enquiriesCollection = 'enquiries';
  static const String salesmenCollection = 'salesmen';
  static const String usersCollection = 'users';
  static const String updatesCollection = 'updates';
}