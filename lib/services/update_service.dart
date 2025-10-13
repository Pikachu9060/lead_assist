import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:leadassist/core/config.dart';

class UpdateService {
  static final CollectionReference updatesCollection =
  FirebaseFirestore.instance.collection(AppConfig.updatesCollection);

  static Future<void> addUpdate(Map<String, dynamic> updateData) async {
    try {
      await updatesCollection.add({
        ...updateData,
        'createdAt': FieldValue.serverTimestamp(),
        'isRead': false,
      });
    } catch (e) {
      throw 'Failed to add update: $e';
    }
  }

  static Stream<QuerySnapshot> getUpdatesForEnquiry(String enquiryId) {
    return updatesCollection
        .where('enquiryId', isEqualTo: enquiryId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  static Stream<QuerySnapshot> getUnreadUpdatesForAdmin() {
    return updatesCollection
        .where('isRead', isEqualTo: false)
        .where('type', isEqualTo: 'salesman_update')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  static Future<void> markUpdateAsRead(String updateId) async {
    await updatesCollection.doc(updateId).update({
      'isRead': true,
      'readAt': FieldValue.serverTimestamp(),
    });
  }
}