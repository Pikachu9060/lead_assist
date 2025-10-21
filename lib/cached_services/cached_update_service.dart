import 'dart:async';

import '../hive/hive_data_manager.dart';
import '../models/update_model.dart';
import '../refactor_services/update_service.dart';

class CachedUpdateService {
  static final Map<String, StreamSubscription> _subscriptions = {};

  // Initialize updates stream for enquiry
  static Future<void> initializeUpdatesStream(String organisationId, String enquiryId) async {
    final key = '$organisationId-$enquiryId';
    if (_subscriptions.containsKey(key)) return;

    final stream = UpdateService.getUpdatesForEnquiry(organisationId, enquiryId);

    _subscriptions[key] = stream.listen((snapshot) async {
      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;

        final updateData = {
          ...data,
          'enquiryId': enquiryId,
          'organizationId': organisationId,
        };

        final updateModel = UpdateModel.fromFirestore(
          updateData,
          doc.id,
        );
        await HiveDataManager.saveUpdate(updateModel);
      }
    });
  }

  static Stream<List<UpdateModel>> watchUpdatesForEnquiry(String organizationId, String enquiryId) {
    final key = '$organizationId-$enquiryId';

    print('👀 Watching updates for: $key');

    // Ensure stream is initialized
    if (!_subscriptions.containsKey(key)) {
      initializeUpdatesStream(organizationId, enquiryId);
    }

    return HiveDataManager.watchUpdatesByEnquiry(enquiryId, organizationId);
  }

  static void disposeStream(String organizationId, String enquiryId) {
    final key = '$organizationId-$enquiryId';
    _subscriptions[key]?.cancel();
    _subscriptions.remove(key);
  }

  static Future<void> dispose() async {
    for (final subscription in _subscriptions.values) {
      await subscription.cancel();
    }
    _subscriptions.clear();
  }
}
