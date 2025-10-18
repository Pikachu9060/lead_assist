import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/update_service.dart';
import '../hive/hive_data_manager.dart';
import '../models/update_model.dart';

class CachedUpdateService {
  static final Map<String, StreamSubscription> _subscriptions = {};

  // Initialize updates stream for enquiry
  static Future<void> initializeUpdatesStream(String organisationId, String enquiryId) async {
    final key = '$organisationId-$enquiryId';
    if (_subscriptions.containsKey(key)) return;

    final stream = UpdateService.getUpdatesForEnquiry(enquiryId);
    _subscriptions[key] = stream.listen((snapshot) async {
      for (final doc in snapshot.docs) {
        final updateModel = UpdateModel.fromFirestore(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
        await HiveDataManager.saveUpdate(updateModel);
      }
    });
  }

  static Stream<List<UpdateModel>> watchUpdatesForEnquiry(String enquiryId) {
    return HiveDataManager.watchUpdatesByEnquiry(enquiryId);
  }

  static Future<void> dispose() async {
    for (final subscription in _subscriptions.values) {
      await subscription.cancel();
    }
    _subscriptions.clear();
  }
}