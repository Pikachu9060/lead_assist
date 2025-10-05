import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';
import '../core/config.dart';

class FCMService {
  static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
  FlutterLocalNotificationsPlugin();
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  static String? _currentUserId;
  static String? _currentUserRole;
  static String? _currentDeviceId;

  // Initialize FCM for current user
  static Future<void> initializeForUser(String userId, String userRole) async {
    _currentUserId = userId;
    _currentUserRole = userRole;

    await _requestPermissions();
    await _initializeLocalNotifications();
    await _getDeviceIdentifier(); // Get real device ID
    await _configureFCM();
  }

  // ✅ GET REAL DEVICE IDENTIFIER
  static Future<void> _getDeviceIdentifier() async {
    try {
      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        _currentDeviceId = androidInfo.id.replaceAll('.', '-'); // ANDROID_ID
        print('Android Device ID: $_currentDeviceId');
      } else if (Platform.isIOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        _currentDeviceId = iosInfo.identifierForVendor?.replaceAll('.', '-');
        print('iOS Device ID: $_currentDeviceId');
      } else {
        _currentDeviceId = 'unknown_device';
      }
    } catch (e) {
      print('Error getting device ID: $e');
      _currentDeviceId = 'error_device';
    }
  }

  static Future<void> _configureFCM() async {
    if (_currentUserId == null || _currentDeviceId == null) {
      print('User or device not ready, skipping FCM configuration');
      return;
    }

    // Get FCM token
    String? token = await _firebaseMessaging.getToken();
    print('FCM Token for user $_currentUserId on device $_currentDeviceId: $token');

    if (token != null) {
      // ✅ Clean up previous user's tokens and save new token
      await _cleanupAndSaveToken(token);
    }

    // Subscribe to topics based on user role
    await _subscribeToUserTopics();

    // Set up message handlers
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundMessage);
    _handleTerminatedMessage();

    // Listen for token refresh
    _firebaseMessaging.onTokenRefresh.listen(_onTokenRefresh);
  }

  // ✅ CLEAN UP PREVIOUS TOKENS AND SAVE NEW ONE
  static Future<void> _cleanupAndSaveToken(String newToken) async {
    if (_currentUserId == null || _currentDeviceId == null) return;

    try {
      // Remove this device's token from ALL users (cleanup when switching users)
      await _removeDeviceFromAllUsers();

      // Then save the new token for current user
      await _saveTokenForCurrentUser(newToken);

    } catch (e) {
      print('Error in token cleanup/save: $e');
    }
  }

  // ✅ REMOVE DEVICE FROM ALL USERS (Cleanup when new user logs in)
  static Future<void> _removeDeviceFromAllUsers() async {
    try {
      final batch = _firestore.batch();

      // Remove from all admin documents
      final adminSnapshot = await _firestore
          .collection(AppConfig.adminCollection)
          .where('fcmTokens.$_currentDeviceId', isNull: false)
          .get();

      for (final doc in adminSnapshot.docs) {
        batch.update(doc.reference, {
          'fcmTokens.$_currentDeviceId': FieldValue.delete(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      // Remove from all salesman documents
      final salesmanSnapshot = await _firestore
          .collection(AppConfig.salesmenCollection)
          .where('fcmTokens.$_currentDeviceId', isNull: false)
          .get();

      for (final doc in salesmanSnapshot.docs) {
        batch.update(doc.reference, {
          'fcmTokens.$_currentDeviceId': FieldValue.delete(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();
      print('Cleaned up FCM tokens for device: $_currentDeviceId');
    } catch (e) {
      print('Error cleaning up FCM tokens: $e');
    }
  }

  // ✅ SAVE TOKEN FOR CURRENT USER WITH DEVICE ID
  static Future<void> _saveTokenForCurrentUser(String token) async {
    if (_currentUserId == null || _currentUserRole == null || _currentDeviceId == null) return;

    final collection = _currentUserRole == AppConfig.adminRole
        ? AppConfig.adminCollection
        : AppConfig.salesmenCollection;

    try {
      await _firestore
          .collection(collection)
          .doc(_currentUserId!)
          .update({
        'fcmTokens.$_currentDeviceId': token, // Map structure: {deviceId: token}
        'lastLoginAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print('✅ Saved FCM token for user $_currentUserId on device: $_currentDeviceId');
    } catch (e) {
      print('Error saving FCM token: $e');
      // If document doesn't exist, create it (shouldn't happen in production)
      await _firestore
          .collection(collection)
          .doc(_currentUserId!)
          .set({
        'fcmTokens': {_currentDeviceId: token},
        'lastLoginAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
  }

  // ✅ HANDLE TOKEN REFRESH
  static Future<void> _onTokenRefresh(String newToken) async {
    print('🔄 FCM Token refreshed: $newToken');
    if (_currentUserId != null && _currentDeviceId != null) {
      await _saveTokenForCurrentUser(newToken);
    }
  }

  // ✅ SUBSCRIBE TO USER TOPICS
  static Future<void> _subscribeToUserTopics() async {
    if (_currentUserId == null || _currentUserRole == null) return;

    try {
      // Unsubscribe from all first (cleanup)
      await _unsubscribeFromAllTopics();

      // Subscribe to relevant topics
      await _firebaseMessaging.subscribeToTopic('all_users');
      await _firebaseMessaging.subscribeToTopic('user_$_currentUserId');
      await _firebaseMessaging.subscribeToTopic('role_$_currentUserRole');

      if (_currentUserRole == 'salesman') {
        await _firebaseMessaging.subscribeToTopic('salesmen');
      } else if (_currentUserRole == 'admin') {
        await _firebaseMessaging.subscribeToTopic('admins');
      }

      print('✅ Subscribed to topics for user $_currentUserId');
    } catch (e) {
      print('Error subscribing to topics: $e');
    }
  }

  // ✅ UNSUBSCRIBE FROM ALL TOPICS (Cleanup)
  static Future<void> _unsubscribeFromAllTopics() async {
    try {
      // Get all topics and unsubscribe (this is a simplified approach)
      // In production, you might want to track subscribed topics
      await _firebaseMessaging.unsubscribeFromTopic('all_users');
      await _firebaseMessaging.unsubscribeFromTopic('admins');
      await _firebaseMessaging.unsubscribeFromTopic('salesmen');

      // Unsubscribe from any user-specific topics
      if (_currentUserId != null) {
        await _firebaseMessaging.unsubscribeFromTopic('user_$_currentUserId');
      }
      if (_currentUserRole != null) {
        await _firebaseMessaging.unsubscribeFromTopic('role_$_currentUserRole');
      }
    } catch (e) {
      print('Error unsubscribing from topics: $e');
    }
  }

  // ✅ REMOVE CURRENT DEVICE ON LOGOUT
  static Future<void> removeCurrentDevice() async {
    if (_currentUserId == null || _currentDeviceId == null) return;

    try {
      // Remove from admin collection
      await _firestore
          .collection(AppConfig.adminCollection)
          .doc(_currentUserId!)
          .update({
        'fcmTokens.$_currentDeviceId': FieldValue.delete(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Remove from salesman collection
      await _firestore
          .collection(AppConfig.salesmenCollection)
          .doc(_currentUserId!)
          .update({
        'fcmTokens.$_currentDeviceId': FieldValue.delete(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Unsubscribe from topics
      await _unsubscribeFromAllTopics();

      print('✅ Removed FCM token for device $_currentDeviceId');

      // Clear current session
      _currentUserId = null;
      _currentUserRole = null;
      _currentDeviceId = null;
    } catch (e) {
      print('Error removing FCM token: $e');
    }
  }

  // ✅ GET CURRENT TOKEN (for debugging)
  static Future<String?> getCurrentToken() async {
    return await _firebaseMessaging.getToken();
  }

  // ... Rest of your existing methods (_requestPermissions, _initializeLocalNotifications, etc.)
  static Future<void> _requestPermissions() async {
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('✅ User granted notification permission');
    } else {
      print('❌ User declined notification permissions');
    }
  }

  static Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings androidSettings =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings =
    DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings =
    InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(initializationSettings);
  }

  static Future<void> _handleForegroundMessage(RemoteMessage message) async {
    print('📱 Received foreground message: ${message.notification?.title}');
    await _showLocalNotification(message);
  }

  static void _handleBackgroundMessage(RemoteMessage message) {
    print('📱 Received background message: ${message.notification?.title}');
  }

  static void _handleTerminatedMessage() {
    FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        print('📱 Received terminated message: ${message.notification?.title}');
      }
    });
  }

  static Future<void> _showLocalNotification(RemoteMessage message) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'lead_assist_channel',
      'Lead Assist Notifications',
      channelDescription: 'Notifications for lead management',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails();

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      message.notification?.title ?? 'Lead Assist',
      message.notification?.body ?? '',
      details,
    );
  }
}