import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationChannels {
  static Future<void> createDefaultChannel() async {
    final AndroidFlutterLocalNotificationsPlugin? androidPlugin =
    FlutterLocalNotificationsPlugin()
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin == null) return;

    const AndroidNotificationChannel defaultChannel = AndroidNotificationChannel(
      'default', // Channel ID as 'default'
      'Lead Assist Notifications',
      description: 'Notifications for Lead Assist app',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    await androidPlugin.createNotificationChannel(defaultChannel);
    print('✅ Default notification channel created');
  }
}