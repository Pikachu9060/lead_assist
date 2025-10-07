import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../core/config.dart';

class AdminService {
  static final CollectionReference _adminCollection =
  FirebaseFirestore.instance.collection(AppConfig.adminCollection);

  // Check if admin with mobile/email exists
  static Future<bool> doesAdminExist({String? mobileNumber, String? email}) async {
    try {
      Query query = _adminCollection;

      if (mobileNumber != null) {
        query = query.where('mobileNumber', isEqualTo: mobileNumber.trim());
      } else if (email != null) {
        query = query.where('email', isEqualTo: email.trim());
      }

      final querySnapshot = await query.limit(1).get();
      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      throw 'Failed to check admin: $e';
    }
  }

  // Create admin user
  static Future<String> createAdmin({
    required String name,
    required String email,
    required String mobileNumber,
  }) async {
    try {
      // Check if admin with same mobile already exists
      final mobileExists = await doesAdminExist(mobileNumber: mobileNumber);
      if (mobileExists) {
        throw 'Admin with mobile number $mobileNumber already exists';
      }

      // Check if admin with same email already exists
      final emailExists = await doesAdminExist(email: email);
      if (emailExists) {
        throw 'Admin with email $email already exists';
      }

      final docRef = _adminCollection.doc();
      // Add to admin collection
      await docRef.set({
        'name': name.trim(),
        'email': email.trim(),
        'mobileNumber': mobileNumber.trim(),
        'role': AppConfig.adminRole,
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return docRef.id;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    } catch (e) {
      throw e.toString();
    }
  }

  // Get admin by ID
  static Future<DocumentSnapshot> getAdminById(String adminId) async {
    return await _adminCollection.doc(adminId).get();
  }

  static String _handleAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'This email is already registered.';
      case 'invalid-email':
        return 'The email address is invalid.';
      case 'operation-not-allowed':
        return 'Email/password accounts are not enabled.';
      case 'weak-password':
        return 'The password is too weak.';
      default:
        return 'An error occurred: ${e.message}';
    }
  }

  static Future<List<QueryDocumentSnapshot>> getAllAdmins() async {
    try {
      final querySnapshot = await _adminCollection
          .orderBy('createdAt', descending: true)
          .get();
      return querySnapshot.docs;
    } catch (e) {
      throw 'Failed to load admins: $e';
    }
  }

  // Delete admin (soft delete - set isActive to false)
  static Future<void> deleteAdmin(String adminId) async {
    try {
      // Don't allow deleting yourself
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser?.uid == adminId) {
        throw 'You cannot delete your own account';
      }

      await _adminCollection.doc(adminId).update({
        'isActive': false,
        'updatedAt': FieldValue.serverTimestamp(),
        'deletedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw 'Failed to delete admin: $e';
    }
  }

  // Reactivate admin
  static Future<void> reactivateAdmin(String adminId) async {
    try {
      await _adminCollection.doc(adminId).update({
        'isActive': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw 'Failed to reactivate admin: $e';
    }
  }

  // Update admin profile
  static Future<void> updateAdmin({
    required String adminId,
    required String name,
    required String mobileNumber,
  }) async {
    try {
      await _adminCollection.doc(adminId).update({
        'name': name.trim(),
        'mobileNumber': mobileNumber.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw 'Failed to update admin: $e';
    }
  }

}