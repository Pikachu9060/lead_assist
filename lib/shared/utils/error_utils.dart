// utils/error_utils.dart
import 'package:firebase_auth/firebase_auth.dart';

class ErrorUtils {
  static String handleFirebaseAuthError(FirebaseAuthException e) {
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

  static String handleFirestoreError(String operation, dynamic error) {
    return 'Failed to $operation: $error';
  }

  static String handleGenericError(String operation, dynamic error) {
    return '$operation failed: $error';
  }
}