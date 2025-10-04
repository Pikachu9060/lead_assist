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
    required String password,
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

      // Create Firebase Auth user
      final UserCredential userCredential =
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      final userId = userCredential.user!.uid;

      // Add to admin collection
      await _adminCollection.doc(userId).set({
        'name': name.trim(),
        'email': email.trim(),
        'mobileNumber': mobileNumber.trim(),
        'role': AppConfig.adminRole,
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return userId;
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

  // Get all admins
  static Stream<QuerySnapshot> getAllAdmins() {
    return _adminCollection
        .where('isActive', isEqualTo: true)
        .snapshots();
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
}