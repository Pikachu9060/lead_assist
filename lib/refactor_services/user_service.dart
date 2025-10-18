import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../core/config.dart';
import '../shared/utils/error_utils.dart';
import '../shared/utils/firestore_utils.dart';

class UserService {
  static CollectionReference get _platformUsersCollection =>
      FirestoreUtils.platformUsersCollection;

  // Check if user exists
  static Future<bool> doesUserExist({String? mobileNumber, String? email}) async {
    try {
      Query query = _platformUsersCollection;

      if (mobileNumber != null) {
        query = query.where('mobileNumber', isEqualTo: FirestoreUtils.trimField(mobileNumber));
      } else if (email != null) {
        query = query.where('email', isEqualTo: FirestoreUtils.trimField(email));
      }

      final querySnapshot = await query.limit(1).get();
      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      throw ErrorUtils.handleFirestoreError('check user', e);
    }
  }

  // Add user
  static Future<String> addUser({
    required String organizationId,
    required String name,
    required String email,
    required String mobileNumber,
    required String role,
    String? region,
  }) async {
    try {
      // Check if user already exists
      final mobileExists = await doesUserExist(mobileNumber: mobileNumber);
      if (mobileExists) {
        throw 'User with mobile number $mobileNumber already exists';
      }

      final emailExists = await doesUserExist(email: email);
      if (emailExists) {
        throw 'User with email $email already exists';
      }

      final docRef = _platformUsersCollection.doc();

      Map<String, dynamic> userData = FirestoreUtils.addTimestamps({
        'organizationId': organizationId,
        'name': FirestoreUtils.trimField(name),
        'email': FirestoreUtils.trimField(email),
        'mobileNumber': FirestoreUtils.trimField(mobileNumber),
        'role': role,
        'isActive': true,
        'userId': docRef.id,
      });

      // Role-specific fields
      if (role == AppConfig.salesmanRole) {
        userData['region'] = region;
        userData['totalEnquiries'] = 0;
        userData['completedEnquiries'] = 0;
        userData['pendingEnquiries'] = 0;
      }

      await docRef.set(userData);

      // Send password reset email
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);

      return "User Created Successfully!";
    } catch (e) {
      throw ErrorUtils.handleGenericError('add user', e);
    }
  }

  // Get user by ID
  static Future<DocumentSnapshot> getUserById(String userId) async {
    return await _platformUsersCollection.doc(userId).get();
  }

  // Get user by email
  static Future<QueryDocumentSnapshot?> getUserByEmail(String email) async {
    try {
      final querySnapshot = await _platformUsersCollection
          .where('email', isEqualTo: FirestoreUtils.trimField(email))
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();
      return querySnapshot.docs.isNotEmpty ? querySnapshot.docs.first : null;
    } catch (e) {
      throw ErrorUtils.handleFirestoreError('get user by email', e);
    }
  }

  // Get users by organization and role
  static Future<List<QueryDocumentSnapshot>> getUsersByOrganizationAndRole(
      String organizationId,
      String role,
      ) async {
    try {
      final querySnapshot = await _platformUsersCollection
          .where('organizationId', isEqualTo: organizationId)
          .where('role', isEqualTo: role)
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .get();
      return querySnapshot.docs;
    } catch (e) {
      throw ErrorUtils.handleFirestoreError('load users', e);
    }
  }

  // Get users stream for organization
  static Stream<QuerySnapshot> getUsersStream(String organizationId) {
    return _platformUsersCollection
        .where('organizationId', isEqualTo: organizationId)
        .where('isActive', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // Update user status
  static Future<void> updateUserStatus(String userId, bool isActive) async {
    try {
      final updateData = FirestoreUtils.updateTimestamp({'isActive': isActive});
      await _platformUsersCollection.doc(userId).update(updateData);
    } catch (e) {
      throw ErrorUtils.handleFirestoreError('update user status', e);
    }
  }

  // Update user profile
  static Future<void> updateUser({
    required String userId,
    required String organizationId,
    required String name,
    required String mobileNumber,
    String? region,
  }) async {
    try {
      // Check if mobile number is unique
      final mobileQuery = await _platformUsersCollection
          .where('organizationId', isEqualTo: organizationId)
          .where('mobileNumber', isEqualTo: FirestoreUtils.trimField(mobileNumber))
          .where(FieldPath.documentId, isNotEqualTo: userId)
          .limit(1)
          .get();

      if (mobileQuery.docs.isNotEmpty) {
        throw 'Another user with mobile number $mobileNumber already exists';
      }

      Map<String, dynamic> updateData = FirestoreUtils.updateTimestamp({
        'name': FirestoreUtils.trimField(name),
        'mobileNumber': FirestoreUtils.trimField(mobileNumber),
      });

      if (region != null) {
        updateData['region'] = region;
      }

      await _platformUsersCollection.doc(userId).update(updateData);
    } catch (e) {
      throw ErrorUtils.handleGenericError('update user', e);
    }
  }

  // Update user enquiry counts
  static Future<void> updateUserEnquiryCount(
      {String? userId,
        int total = 0,
        int completed = 0,
        int pending = 0,
      }) async {
    try {
      await _platformUsersCollection.doc(userId).update(
        FirestoreUtils.updateTimestamp({
          'totalEnquiries': FieldValue.increment(total),
          'completedEnquiries': FieldValue.increment(completed),
          'pendingEnquiries': FieldValue.increment(pending),
        }),
      );
    } catch (e) {
      throw ErrorUtils.handleFirestoreError('update user counts', e);
    }
  }

  // Get salesmen by region
  static Future<List<QueryDocumentSnapshot>> getSalesmenByRegion(
      String organizationId,
      String region,
      ) async {
    try {
      final querySnapshot = await _platformUsersCollection
          .where('organizationId', isEqualTo: organizationId)
          .where('role', isEqualTo: AppConfig.salesmanRole)
          .where('region', isEqualTo: region)
          .where('isActive', isEqualTo: true)
          .get();
      return querySnapshot.docs;
    } catch (e) {
      throw ErrorUtils.handleFirestoreError('load salesmen by region', e);
    }
  }
}