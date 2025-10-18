class HiveConfig {
  static const String boxNamePrefix = 'lead_assist';

  // Box names for different data types
  static const String usersBox = 'users';
  static const String customersBox = 'customers';
  static const String enquiriesBox = 'enquiries';
  static const String updatesBox = 'updates';
  static const String userPreferencesBox = 'user_prefs';

  // Type IDs for Hive adapters
  static const int userModelTypeId = 1;
  static const int customerModelTypeId = 2;
  static const int enquiryModelTypeId = 3;
  static const int updateModelTypeId = 4;
}