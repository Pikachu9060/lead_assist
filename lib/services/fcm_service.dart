import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class FCMService {
  static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
  FlutterLocalNotificationsPlugin();

  // Initialize FCM and local notifications
  static Future<void> initialize() async {
    // Request notification permissions
    await _requestPermissions();

    // Initialize local notifications
    await _initializeLocalNotifications();

    // Configure FCM
    await _configureFCM();
  }

  static Future<void> _requestPermissions() async {
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('User granted notification permission');
    } else {
      print('User declined or has not accepted notification permissions');
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

  static Future<void> _configureFCM() async {
    // Get device token
    String? token = await _firebaseMessaging.getToken();
    print('FCM Token: $token');

    // Save token to Firestore (we'll implement this later)
    await _saveTokenToFirestore(token);

    // Subscribe to general topic
    await _firebaseMessaging.subscribeToTopic('all_users');

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle background messages
    FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundMessage);

    // Handle terminated app messages
    _handleTerminatedMessage();
  }

  static Future<void> _saveTokenToFirestore(String? token) async {
    if (token == null) return;

    // We'll implement this properly after we have user authentication context
    print('Save this token to user document: $token');
  }

  static Future<void> _handleForegroundMessage(RemoteMessage message) async {
    print('Received foreground message: ${message.notification?.title}');

    // Show local notification
    await _showLocalNotification(message);
  }

  static void _handleBackgroundMessage(RemoteMessage message) {
    print('Received background message: ${message.notification?.title}');
    // Navigate to specific screen based on message data
  }

  static void _handleTerminatedMessage() {
    // Handle when app is completely terminated
    FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        print('Received terminated message: ${message.notification?.title}');
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
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails();

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      message.notification?.title ?? 'New Notification',
      message.notification?.body ?? '',
      details,
    );
  }

  // Subscribe user to role-specific topics
  static Future<void> subscribeToUserTopics(String userId, String userRole) async {
    await _firebaseMessaging.subscribeToTopic('user_$userId');
    await _firebaseMessaging.subscribeToTopic('role_$userRole');

    if (userRole == 'salesman') {
      await _firebaseMessaging.subscribeToTopic('salesmen');
    } else if (userRole == 'admin') {
      await _firebaseMessaging.subscribeToTopic('admins');
    }
  }

  // Unsubscribe from topics (on logout)
  static Future<void> unsubscribeFromAllTopics() async {
    await _firebaseMessaging.unsubscribeFromTopic('all_users');
    await _firebaseMessaging.unsubscribeFromTopic('admins');
    await _firebaseMessaging.unsubscribeFromTopic('salesmen');
    // Note: We'll handle user-specific topics separately
  }

  // Get current FCM token
  static Future<String?> getToken() async {
    return await _firebaseMessaging.getToken();
  }
}