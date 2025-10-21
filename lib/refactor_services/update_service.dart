import 'package:cloud_firestore/cloud_firestore.dart';
import '../shared/utils/error_utils.dart';
import '../shared/utils/firestore_utils.dart';

class UpdateService {

  static CollectionReference _getEnquiriesUpdatesCollection(String organizationId, String enquiryId) {
    return FirestoreUtils.getUpdateCollection(organizationId, enquiryId);
  }


  // Add update
  static Future<void> addUpdate(String organizationId, String enquiryId, Map<String, dynamic> updateData) async {
    try {
      await _getEnquiriesUpdatesCollection(organizationId, enquiryId).add(
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
  static Stream<QuerySnapshot> getUpdatesForEnquiry(String organizationId, String enquiryId) {
    return _getEnquiriesUpdatesCollection(organizationId, enquiryId).snapshots();
  }

  // Get unread updates for admin
  // static Stream<QuerySnapshot> getUnreadUpdatesForAdmin() {
  //   return updatesCollection
  //       .where('isRead', isEqualTo: false)
  //       .where('type', isEqualTo: 'salesman_update')
  //       .orderBy('createdAt', descending: true)
  //       .snapshots();
  // }

  // Mark update as read
  // static Future<void> markUpdateAsRead(String updateId) async {
  //   try {
  //     await updatesCollection.doc(updateId).update(
  //         FirestoreUtils.updateTimestamp({
  //           'isRead': true,
  //           'readAt': FieldValue.serverTimestamp(),
  //         })
  //     );
  //   } catch (e) {
  //     throw ErrorUtils.handleGenericError('mark update as read', e);
  //   }
  // }
}