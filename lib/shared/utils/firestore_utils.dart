// utils/firestore_utils.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreUtils {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Common collection references
  static CollectionReference get platformUsersCollection =>
      _firestore.collection('platform_users');

  static CollectionReference get organizationsCollection =>
      _firestore.collection('organizations');

  static CollectionReference get updatesCollection =>
      _firestore.collection('updates');

  // Common query methods
  static CollectionReference getOrganizationCollection(String organizationId, String subcollection) {
    return organizationsCollection.doc(organizationId).collection(subcollection);
  }

  static CollectionReference getCustomersCollection(String organizationId) {
    return getOrganizationCollection(organizationId, 'customers');
  }

  static CollectionReference getEnquiriesCollection(String organizationId) {
    return getOrganizationCollection(organizationId, 'enquiries');
  }

  // Common field operations
  static Map<String, dynamic> addTimestamps(Map<String, dynamic> data, {bool includeUpdated = true}) {
    final result = {
      ...data,
      'createdAt': FieldValue.serverTimestamp(),
    };

    if (includeUpdated) {
      result['updatedAt'] = FieldValue.serverTimestamp();
    }

    return result;
  }

  static Map<String, dynamic> updateTimestamp(Map<String, dynamic> data) {
    return {
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  // Common query operations
  static Future<DocumentSnapshot?> getDocumentByField(
      CollectionReference collection,
      String field,
      String value
      ) async {
    try {
      final query = await collection
          .where(field, isEqualTo: value.trim())
          .limit(1)
          .get();
      return query.docs.isNotEmpty ? query.docs.first : null;
    } catch (e) {
      throw 'Failed to get document by $field: $e';
    }
  }

  static Future<bool> doesDocumentExist(
      CollectionReference collection,
      String field,
      String value
      ) async {
    try {
      final query = await collection
          .where(field, isEqualTo: value.trim())
          .limit(1)
          .get();
      return query.docs.isNotEmpty;
    } catch (e) {
      throw 'Failed to check document existence: $e';
    }
  }

  static String trimField(String value) {
    return value.trim();
  }
}