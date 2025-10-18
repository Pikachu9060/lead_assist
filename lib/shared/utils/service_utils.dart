import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'error_utils.dart';
import 'firestore_utils.dart';

class ServiceUtils {
  // Common error handling for service operations
  static Future<T> handleServiceOperation<T>(
      String operationName,
      Future<T> Function() operation,
      ) async {
    try {
      return await operation();
    } on FirebaseAuthException catch (e) {
      throw ErrorUtils.handleFirebaseAuthError(e);
    } on FirebaseException catch (e) {
      throw ErrorUtils.handleFirestoreError(operationName, e);
    } catch (e) {
      throw ErrorUtils.handleGenericError(operationName, e);
    }
  }

  // Common transaction wrapper
  static Future<T> runTransaction<T>(
      Future<T> Function(Transaction transaction) transactionOperation,
      ) async {
    return await FirebaseFirestore.instance.runTransaction(transactionOperation);
  }

  // Common document existence check
  static Future<bool> checkDocumentExists({
    required CollectionReference collection,
    required String field,
    required String value,
    String? excludeDocumentId,
  }) async {
    Query query = collection.where(field, isEqualTo: FirestoreUtils.trimField(value));

    if (excludeDocumentId != null) {
      query = query.where(FieldPath.documentId, isNotEqualTo: excludeDocumentId);
    }

    final snapshot = await query.limit(1).get();
    return snapshot.docs.isNotEmpty;
  }

  // Common document fetch by field
  static Future<DocumentSnapshot?> getDocumentByField({
    required CollectionReference collection,
    required String field,
    required String value,
  }) async {
    final snapshot = await collection
        .where(field, isEqualTo: FirestoreUtils.trimField(value))
        .limit(1)
        .get();

    return snapshot.docs.isNotEmpty ? snapshot.docs.first : null;
  }

  // Prepare data with timestamps for creation
  static Map<String, dynamic> prepareCreateData(Map<String, dynamic> data) {
    return FirestoreUtils.addTimestamps(data);
  }

  // Prepare data with timestamps for update
  static Map<String, dynamic> prepareUpdateData(Map<String, dynamic> data) {
    return FirestoreUtils.updateTimestamp(data);
  }

  // Trim field values consistently
  static String trimField(String value) {
    return FirestoreUtils.trimField(value);
  }
}