import 'package:cloud_firestore/cloud_firestore.dart';

import '../shared/utils/firestore_utils.dart';
import '../shared/utils/service_utils.dart';

class UpdateService {
  static CollectionReference get updatesCollection => FirestoreUtils.updatesCollection;

  static Future<void> addUpdate(Map<String, dynamic> updateData) async {
    return ServiceUtils.handleServiceOperation('add update', () async {
      await updatesCollection.add(
          ServiceUtils.prepareCreateData({
            ...updateData,
            'isRead': false,
          })
      );
    });
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
    return ServiceUtils.handleServiceOperation('mark update as read', () async {
      await updatesCollection.doc(updateId).update(
          ServiceUtils.prepareUpdateData({
            'isRead': true,
            'readAt': FieldValue.serverTimestamp(),
          })
      );
    });
  }
}