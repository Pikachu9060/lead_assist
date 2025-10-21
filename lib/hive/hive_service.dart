import 'package:hive/hive.dart';
import 'package:leadassist/models/user_notification.dart';
import 'package:path_provider/path_provider.dart';

import '../models/customer_model.dart';
import '../models/enquiry_model.dart';
import '../models/update_model.dart';
import '../models/user_model.dart';
import 'hive_config.dart';

class HiveService {
  static bool _isInitialized = false;

  static Future<void> initialize() async {
    if (_isInitialized) return;

    final appDocumentDirectory = await getApplicationDocumentsDirectory();
    Hive.init(appDocumentDirectory.path);

    // Register adapters
    Hive.registerAdapter(UserModelAdapter());
    Hive.registerAdapter(CustomerModelAdapter());
    Hive.registerAdapter(EnquiryModelAdapter());
    Hive.registerAdapter(UpdateModelAdapter());
    Hive.registerAdapter(UserNotificationModelAdapter());

    // Open boxes
    await Hive.openBox<UserModel>(HiveConfig.usersBox);
    await Hive.openBox<CustomerModel>(HiveConfig.customersBox);
    await Hive.openBox<EnquiryModel>(HiveConfig.enquiriesBox);
    await Hive.openBox<UpdateModel>(HiveConfig.updatesBox);
    await Hive.openBox(HiveConfig.userPreferencesBox);
    await Hive.openBox<UserNotificationModel>(HiveConfig.userNotificationBox);

    _isInitialized = true;
  }

  static Future<void> clearAllData() async {
    await Hive.box<UserModel>(HiveConfig.usersBox).clear();
    await Hive.box<CustomerModel>(HiveConfig.customersBox).clear();
    await Hive.box<EnquiryModel>(HiveConfig.enquiriesBox).clear();
    await Hive.box<UpdateModel>(HiveConfig.updatesBox).clear();
    await Hive.box<UpdateModel>(HiveConfig.userNotificationBox).clear();
  }

  static Future<void> close() async {
    await Hive.close();
    _isInitialized = false;
  }
}