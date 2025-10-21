import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:leadassist/refactor_services/auth_service.dart';
import 'package:leadassist/shared/utils/firestore_utils.dart';

class UserNotificationService {
  static Stream<QuerySnapshot> getUserSpecificNotification() {
    final data = FirestoreUtils.getUserNotificationCollection()
        .where('userId', isEqualTo: AuthService.getUserId())
        .snapshots();
    return data;
  }

  static Future<void> markUserNotificationAsRead(String notificationId) async {
    await FirestoreUtils.getUserNotificationCollection()
        .doc(notificationId)
        .update({
      'isRead': true,
      'readAt': FieldValue.serverTimestamp(),
    });
  }

  // Add this method to delete notifications from Firestore
  static Future<void> deleteUserNotification(String notificationId) async {
    await FirestoreUtils.getUserNotificationCollection()
        .doc(notificationId)
        .delete();
  }
}