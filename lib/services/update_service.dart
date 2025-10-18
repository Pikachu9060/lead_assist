import 'package:cloud_firestore/cloud_firestore.dart';
import '../shared/utils/error_utils.dart';
import '../shared/utils/firestore_utils.dart';

class UpdateService {
  static CollectionReference get updatesCollection => FirestoreUtils.updatesCollection;

  static Future<void> addUpdate(Map<String, dynamic> updateData) async {
    try {
      await updatesCollection.add(
          FirestoreUtils.addTimestamps({
            ...updateData,
            'isRead': false,
          }, includeUpdated: false)
      );
    } catch (e) {
      throw ErrorUtils.handleGenericError('add update', e);
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
    await updatesCollection.doc(updateId).update(
        FirestoreUtils.updateTimestamp({
          'isRead': true,
          'readAt': FieldValue.serverTimestamp(),
        })
    );
  }
}