import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/config.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Future<UserCredential> login(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      return credential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    } catch (e) {
      throw 'Login failed: $e';
    }
  }

  static Future<void> logout() async {
    await _auth.signOut();
  }

  // Check if user exists in any role collection (admin or salesman)
  static Future<String?> getUserRole(String userId) async {
    try {
      // Check admin collection first
      final adminDoc = await _firestore
          .collection(AppConfig.adminCollection)
          .doc(userId)
          .get();

      if (adminDoc.exists) {
        return adminDoc['role'];
      }

      // Check salesman collection
      final salesmanDoc = await _firestore
          .collection(AppConfig.salesmenCollection)
          .doc(userId)
          .get();

      if (salesmanDoc.exists) {
        return salesmanDoc['role'];
      }

      return null; // User not found in any role collection
    } catch (e) {
      throw 'Failed to get user role: $e';
    }
  }

  // Get user data based on role
  static Future<Map<String, dynamic>?> getUserData(String userId) async {
    try {
      // Check admin collection first
      final adminDoc = await _firestore
          .collection(AppConfig.adminCollection)
          .doc(userId)
          .get();

      if (adminDoc.exists) {
        return adminDoc.data();
      }

      // Check salesman collection
      final salesmanDoc = await _firestore
          .collection(AppConfig.salesmenCollection)
          .doc(userId)
          .get();

      if (salesmanDoc.exists) {
        return salesmanDoc.data();
      }

      return null; // User not found
    } catch (e) {
      throw 'Failed to get user data: $e';
    }
  }

  // Create admin user (for initial setup)
  static Future<void> createAdminUser({
    required String email,
    required String password,
    required String name,
    required String mobileNumber,
  }) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      final userId = userCredential.user!.uid;

      // Add to admin collection
      await _firestore
          .collection(AppConfig.adminCollection)
          .doc(userId)
          .set({
        'email': email,
        'name': name,
        'mobileNumber': mobileNumber,
        'role': AppConfig.adminRole,
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    } catch (e) {
      throw 'Failed to create admin: $e';
    }
  }

  // Reset password
  static Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    } catch (e) {
      throw 'Failed to reset password: $e';
    }
  }

  // Update user profile
  static Future<void> updateProfile({
    required String userId,
    required String name,
    required String mobileNumber,
  }) async {
    try {
      // Determine which collection the user belongs to
      final role = await getUserRole(userId);

      if (role == AppConfig.adminRole) {
        await _firestore
            .collection(AppConfig.adminCollection)
            .doc(userId)
            .update({
          'name': name.trim(),
          'mobileNumber': mobileNumber.trim(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else if (role == AppConfig.salesmanRole) {
        await _firestore
            .collection(AppConfig.salesmenCollection)
            .doc(userId)
            .update({
          'name': name.trim(),
          'mobileNumber': mobileNumber.trim(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        throw 'User role not found';
      }
    } catch (e) {
      throw 'Failed to update profile: $e';
    }
  }

  // Check if email exists in any role
  static Future<bool> doesEmailExist(String email) async {
    try {
      // Check admin collection
      final adminQuery = await _firestore
          .collection(AppConfig.adminCollection)
          .where('email', isEqualTo: email.trim())
          .limit(1)
          .get();

      if (adminQuery.docs.isNotEmpty) {
        return true;
      }

      // Check salesman collection
      final salesmanQuery = await _firestore
          .collection(AppConfig.salesmenCollection)
          .where('email', isEqualTo: email.trim())
          .limit(1)
          .get();

      return salesmanQuery.docs.isNotEmpty;
    } catch (e) {
      throw 'Failed to check email: $e';
    }
  }

  static String _handleAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found with this email.';
      case 'wrong-password':
        return 'Wrong password provided.';
      case 'email-already-in-use':
        return 'Email already in use.';
      case 'weak-password':
        return 'Password is too weak.';
      case 'invalid-email':
        return 'Email is invalid.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'network-request-failed':
        return 'Network error. Please check your connection.';
      default:
        return 'Authentication failed: ${e.message}';
    }
  }

  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Get current user
  static User? get currentUser => _auth.currentUser;
}