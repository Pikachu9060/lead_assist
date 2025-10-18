import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';
import '../shared/utils/firestore_utils.dart';

class FCMService {
  static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  static final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  static String? _currentUserId;
  static String? _currentUserRole;
  static String? _currentDeviceId;

  // Initialize FCM for user
  static Future<void> initializeForUser(String userId, String userRole) async {
    _currentUserId = userId;
    _currentUserRole = userRole;

    await _requestPermissions();
    await _initializeLocalNotifications();
    await _getDeviceIdentifier();
    await _configureFCM();
  }

  static Future<void> _getDeviceIdentifier() async {
    try {
      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        _currentDeviceId = _formatDeviceId(androidInfo.id);
      } else if (Platform.isIOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        _currentDeviceId = _formatDeviceId(iosInfo.identifierForVendor);
      } else {
        _currentDeviceId = 'unknown_device';
      }
    } catch (e) {
      _currentDeviceId = 'error_device';
    }
  }

  static Future<void> _configureFCM() async {
    if (_currentUserId == null || _currentDeviceId == null) return;

    // Get and save token
    String? token = await _firebaseMessaging.getToken();
    if (token != null) {
      await _saveTokenForCurrentUser(token);
    }

    // Subscribe to topics
    await _subscribeToUserTopics();

    // Set up message handlers
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundMessage);

    // Listen for token refresh
    _firebaseMessaging.onTokenRefresh.listen(_onTokenRefresh);
  }

  static Future<void> _saveTokenForCurrentUser(String token) async {
    if (_currentUserId == null || _currentDeviceId == null) return;

    try {
      await FirestoreUtils.platformUsersCollection
          .doc(_currentUserId!)
          .update(FirestoreUtils.updateTimestamp({
        'fcmTokens.$_currentDeviceId': token,
        'lastLoginAt': FieldValue.serverTimestamp(),
      }));
    } catch (e) {
      print('Error saving FCM token: $e');
    }
  }

  static Future<void> _subscribeToUserTopics() async {
    if (_currentUserId == null || _currentUserRole == null) return;

    try {
      await _firebaseMessaging.subscribeToTopic('all_users');
      await _firebaseMessaging.subscribeToTopic('user_$_currentUserId');
      await _firebaseMessaging.subscribeToTopic('role_$_currentUserRole');

      if (_currentUserRole == 'salesman') {
        await _firebaseMessaging.subscribeToTopic('salesmen');
      } else if (_currentUserRole == 'admin') {
        await _firebaseMessaging.subscribeToTopic('admins');
      }
    } catch (e) {
      print('Error subscribing to topics: $e');
    }
  }

  static Future<void> _onTokenRefresh(String newToken) async {
    if (_currentUserId != null && _currentDeviceId != null) {
      await _saveTokenForCurrentUser(newToken);
    }
  }

  static Future<void> removeCurrentDevice() async {
    if (_currentUserId == null || _currentDeviceId == null) return;

    try {
      await FirestoreUtils.platformUsersCollection
          .doc(_currentUserId!)
          .update(FirestoreUtils.updateTimestamp({
        'fcmTokens.$_currentDeviceId': FieldValue.delete(),
      }));

      await _unsubscribeFromAllTopics();

      _currentUserId = null;
      _currentUserRole = null;
      _currentDeviceId = null;
    } catch (e) {
      print('Error removing FCM token: $e');
    }
  }

  static Future<void> _unsubscribeFromAllTopics() async {
    try {
      await _firebaseMessaging.unsubscribeFromTopic('all_users');
      await _firebaseMessaging.unsubscribeFromTopic('admins');
      await _firebaseMessaging.unsubscribeFromTopic('salesmen');

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

  static Future<void> _requestPermissions() async {
    await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
  }

  static Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(initializationSettings);
  }

  static Future<void> _handleForegroundMessage(RemoteMessage message) async {
    await _showLocalNotification(message);
  }

  static void _handleBackgroundMessage(RemoteMessage message) {
    // Handle background message
  }

  static Future<void> _showLocalNotification(RemoteMessage message) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'lead_assist_channel',
      'Lead Assist Notifications',
      channelDescription: 'Notifications for lead management',
      importance: Importance.high,
      priority: Priority.high,
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

  static String? _formatDeviceId(String? deviceId) {
    return deviceId?.replaceAll('.', '-');
  }

  static Future<String?> getCurrentToken() async {
    return await _firebaseMessaging.getToken();
  }
}