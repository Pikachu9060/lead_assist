// services/auth_service.dart
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

      // Get user data from platform_users collection
      final user = await _getPlatformUserByEmail(email);

      if (user == null) {
        await _auth.signOut();
        throw 'User not found in platform';
      }

      return credential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    } catch (e) {
      throw 'Login failed: $e';
    }
  }

  // Get platform user by email
  static Future<DocumentSnapshot?> _getPlatformUserByEmail(String email) async {
    try {
      final query = await _firestore
          .collection('platform_users')
          .where('email', isEqualTo: email.trim())
          .limit(1)
          .get();
      return query.docs.isNotEmpty ? query.docs.first : null;
    } catch (e) {
      throw 'Failed to get user data: $e';
    }
  }

  // Get user data with organization context
  static Future<Map<String, dynamic>?> getUserData(String userId) async {
    try {
      final userDoc = await _firestore.collection('platform_users').doc(userId).get();
      if (!userDoc.exists) return null;

      final userData = userDoc.data()!;
      return userData;
    } catch (e) {
      throw 'Failed to get user data: $e';
    }
  }

  static Future<void> logout() async {
    await _auth.signOut();
  }

  // Check if email exists in platform
  static Future<bool> doesEmailExist(String email) async {
    try {
      final query = await _firestore
          .collection('platform_users')
          .where('email', isEqualTo: email.trim())
          .limit(1)
          .get();
      return query.docs.isNotEmpty;
    } catch (e) {
      throw 'Failed to check email: $e';
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
  static User? get currentUser => _auth.currentUser;
}