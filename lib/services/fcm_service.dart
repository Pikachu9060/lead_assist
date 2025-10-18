import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';
import '../shared/utils/firestore_utils.dart';
import '../shared/utils/service_utils.dart';

class FCMService {
  static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
  FlutterLocalNotificationsPlugin();
  static final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  static String? _currentUserId;
  static String? _currentUserRole;
  static String? _currentDeviceId;

  static Future<void> initializeForUser(String userId, String userRole) async {
    return ServiceUtils.handleServiceOperation('FCM initialization', () async {
      _currentUserId = userId;
      _currentUserRole = userRole;
      await _requestPermissions();
      await _initializeLocalNotifications();
      await _getDeviceIdentifier();
      await _configureFCM();
    });
  }

  static Future<void> _getDeviceIdentifier() async {
    try {
      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        _currentDeviceId = _formatDeviceId(androidInfo.id);
        print('Android Device ID: $_currentDeviceId');
      } else if (Platform.isIOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        _currentDeviceId = _formatDeviceId(iosInfo.identifierForVendor);
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

    String? token = await _firebaseMessaging.getToken();
    print('FCM Token for user $_currentUserId on device $_currentDeviceId: $token');

    if (token != null) {
      await _cleanupAndSaveToken(token);
    }

    await _subscribeToUserTopics();

    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundMessage);
    _handleTerminatedMessage();

    _firebaseMessaging.onTokenRefresh.listen(_onTokenRefresh);
  }

  static Future<void> _cleanupAndSaveToken(String newToken) async {
    if (_currentUserId == null || _currentDeviceId == null) return;

    try {
      await _removeDeviceFromAllUsers();
      await _saveTokenForCurrentUser(newToken);
    } catch (e) {
      print('Error in token cleanup/save: $e');
    }
  }

  static Future<void> _removeDeviceFromAllUsers() async {
    try {
      final batch = FirebaseFirestore.instance.batch();

      final salesmanSnapshot = await FirestoreUtils.platformUsersCollection
          .where('fcmTokens.$_currentDeviceId', isNull: false)
          .get();

      for (final doc in salesmanSnapshot.docs) {
        batch.update(doc.reference, ServiceUtils.prepareUpdateData({
          'fcmTokens.$_currentDeviceId': FieldValue.delete(),
        }));
      }

      await batch.commit();
      print('Cleaned up FCM tokens for device: $_currentDeviceId');
    } catch (e) {
      print('Error cleaning up FCM tokens: $e');
    }
  }

  static Future<void> _saveTokenForCurrentUser(String token) async {
    if (_currentUserId == null || _currentDeviceId == null) return;

    try {
      await FirestoreUtils.platformUsersCollection
          .doc(_currentUserId!)
          .update(ServiceUtils.prepareUpdateData({
        'fcmTokens.$_currentDeviceId': token,
        'lastLoginAt': FieldValue.serverTimestamp(),
      }));
      print('✅ Saved FCM token for user $_currentUserId');
    } catch (e) {
      print('Error saving FCM token: $e');
    }
  }

  static Future<void> _onTokenRefresh(String newToken) async {
    print('🔄 FCM Token refreshed: $newToken');
    if (_currentUserId != null && _currentDeviceId != null) {
      await _saveTokenForCurrentUser(newToken);
    }
  }

  static Future<void> _subscribeToUserTopics() async {
    if (_currentUserId == null || _currentUserRole == null) return;

    try {
      await _unsubscribeFromAllTopics();

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

  static Future<void> removeCurrentDevice() async {
    if (_currentUserId == null || _currentDeviceId == null) return;

    return ServiceUtils.handleServiceOperation('remove FCM device', () async {
      await FirestoreUtils.platformUsersCollection
          .doc(_currentUserId!)
          .update(ServiceUtils.prepareUpdateData({
        'fcmTokens.$_currentDeviceId': FieldValue.delete(),
      }));

      await _unsubscribeFromAllTopics();

      print('✅ Removed FCM token for device $_currentDeviceId');

      _currentUserId = null;
      _currentUserRole = null;
      _currentDeviceId = null;
    });
  }

  static Future<String?> getCurrentToken() async {
    return await _firebaseMessaging.getToken();
  }

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

  static String? _formatDeviceId(String? deviceId) {
    if (deviceId == null) return null;
    return deviceId.replaceAll('.', '-');
  }
}