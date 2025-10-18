import 'package:cloud_firestore/cloud_firestore.dart';
import '../shared/utils/error_utils.dart';
import '../shared/utils/firestore_utils.dart';

class UpdateService {
  static CollectionReference get updatesCollection => FirestoreUtils.updatesCollection;

  // Add update
  static Future<void> addUpdate(Map<String, dynamic> updateData) async {
    try {
      await updatesCollection.add(
          FirestoreUtils.addTimestamps({
            ...updateData,
            'isRead': false,
          })
      );
    } catch (e) {
      throw ErrorUtils.handleGenericError('add update', e);
    }
  }

  // Get updates for enquiry
  static Stream<QuerySnapshot> getUpdatesForEnquiry(String enquiryId) {
    return updatesCollection
        .where('enquiryId', isEqualTo: enquiryId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // Get unread updates for admin
  static Stream<QuerySnapshot> getUnreadUpdatesForAdmin() {
    return updatesCollection
        .where('isRead', isEqualTo: false)
        .where('type', isEqualTo: 'salesman_update')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // Mark update as read
  static Future<void> markUpdateAsRead(String updateId) async {
    try {
      await updatesCollection.doc(updateId).update(
          FirestoreUtils.updateTimestamp({
            'isRead': true,
            'readAt': FieldValue.serverTimestamp(),
          })
      );
    } catch (e) {
      throw ErrorUtils.handleGenericError('mark update as read', e);
    }
  }
}