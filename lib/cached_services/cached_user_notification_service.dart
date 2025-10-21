import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../hive/hive_data_manager.dart';
import '../models/user_notification.dart';
import '../refactor_services/user_notification_service.dart';

class CachedUserNotificationService {
  static StreamSubscription? _notificationSubscription;
  static bool _isInitialized = false;
  static Completer<void>? _initializationCompleter;

  // Initialize the notification stream
  static Future<void> initializeUserNotificationsStream() async {
    if (_isInitialized) return;

    if (_initializationCompleter != null) {
      return _initializationCompleter!.future;
    }

    _initializationCompleter = Completer<void>();

    try {
      final stream = UserNotificationService.getUserSpecificNotification();

      _notificationSubscription = stream.listen(
            (snapshot) async {
          print('Firestore snapshot received: ${snapshot.docs.length} documents');
          print('Snapshot changes: ${snapshot.docChanges.length} changes');

          // Handle document changes
          for (final change in snapshot.docChanges) {
            switch (change.type) {
              case DocumentChangeType.added:
                print('Document added: ${change.doc.id}');
                final notification = UserNotificationModel.fromFirestore(
                  change.doc.data() as Map<String, dynamic>,
                  change.doc.id,
                );
                await HiveDataManager.saveUserNotification(notification);
                break;

              case DocumentChangeType.modified:
                print('Document modified: ${change.doc.id}');
                final notification = UserNotificationModel.fromFirestore(
                  change.doc.data() as Map<String, dynamic>,
                  change.doc.id,
                );
                await HiveDataManager.saveUserNotification(notification);
                break;

              case DocumentChangeType.removed:
                print('Document removed: ${change.doc.id}');
                await HiveDataManager.deleteUserNotification(change.doc.id);
                break;
            }
          }
        },
        onError: (error) {
          print('Notification stream error: $error');
        },
      );

      _isInitialized = true;
      _initializationCompleter!.complete();
      print('User notification stream initialized successfully');
    } catch (e) {
      _initializationCompleter!.completeError(e);
      _initializationCompleter = null;
      print('Error initializing notification stream: $e');
      rethrow;
    }
  }

  // Watch user notifications from Hive
  static Stream<List<UserNotificationModel>> watchUserNotifications() {
    // Ensure stream is initialized
    if (!_isInitialized) {
      initializeUserNotificationsStream();
    }

    return HiveDataManager.watchUserNotifications();
  }

  // Watch unread notifications only
  static Stream<List<UserNotificationModel>> watchUnreadNotifications() {
    return watchUserNotifications().map((notifications) =>
        notifications.where((notification) => !notification.isRead).toList());
  }

  // Mark notification as read
  static Future<void> markAsRead(String notificationId) async {
    // Update in Firestore
    await UserNotificationService.markUserNotificationAsRead(notificationId);

    // Also update locally in Hive for immediate UI update
    final notification = await HiveDataManager.getUserNotification(notificationId);
    if (notification != null) {
      final updatedNotification = UserNotificationModel(
        id: notification.id,
        message: notification.message,
        isRead: true,
        timestamp: notification.timestamp,
        title: notification.title,
        userId: notification.userId,
        readAt: DateTime.now(),
        enquiryId: notification.enquiryId
      );
      await HiveDataManager.saveUserNotification(updatedNotification);
    }
  }

  // Delete notification locally and from Firestore
  static Future<void> deleteNotification(String notificationId) async {
    // Delete from Firestore
    await UserNotificationService.deleteUserNotification(notificationId);
    // Local deletion will be handled by the stream listener
  }

  // Mark all notifications as read
  static Future<void> markAllAsRead() async {
    final notifications = await HiveDataManager.getUserNotifications();
    final unreadNotifications = notifications.where((n) => !n.isRead).toList();

    for (final notification in unreadNotifications) {
      await markAsRead(notification.id);
    }
  }

  // Get unread count
  static Stream<int> watchUnreadCount() {
    final data = watchUserNotifications().map((notifications) {
      final unreadCount = notifications.where((notification) => !notification.isRead).length;
      print('Unread count calculated: $unreadCount');
      return unreadCount;
    });
    return data;
  }

  // Dispose
  static Future<void> dispose() async {
    await _notificationSubscription?.cancel();
    _notificationSubscription = null;
    _isInitialized = false;
    _initializationCompleter = null;
  }
}