import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../shared/utils/error_utils.dart';
import '../shared/utils/firestore_utils.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static Future<UserCredential> login(String email, String password) async {
    try {
      _auth.signOut();
      final credential = await _auth.signInWithEmailAndPassword(
        email: FirestoreUtils.trimField(email),
        password: FirestoreUtils.trimField(password),
      );

      // Get user data from platform_users collection
      final user = await _getPlatformUserByEmail(email);

      if (user == null) {
        await _auth.signOut();
        throw 'User not found in platform';
      }

      return credential;
    } on FirebaseAuthException catch (e) {
      print('❌ Auth Exception: ${e.code} - ${e.message}');
      throw ErrorUtils.handleFirebaseAuthError(e);
    } catch (e) {
      throw ErrorUtils.handleGenericError('Login', e);
    }
  }

  // Get platform user by email
  static Future<DocumentSnapshot?> _getPlatformUserByEmail(String email) async {
    return await FirestoreUtils.getDocumentByField(
      FirestoreUtils.platformUsersCollection,
      'email',
      email,
    );
  }

  // Get user data with organization context
  static Future<Map<String, dynamic>?> getUserData(String userId) async {
    try {
      final userDoc = await FirestoreUtils.platformUsersCollection.doc(userId).get();
      if (!userDoc.exists) return null;

      return userDoc.data()! as Map<String, dynamic>;
    } catch (e) {
      throw ErrorUtils.handleFirestoreError('get user data', e);
    }
  }

  static Future<void> logout() async {
    await _auth.signOut();
  }

  // Check if email exists in platform
  static Future<bool> doesEmailExist(String email) async {
    return await FirestoreUtils.doesDocumentExist(
      FirestoreUtils.platformUsersCollection,
      'email',
      email,
    );
  }

  // Reset password
  static Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: FirestoreUtils.trimField(email));
    } on FirebaseAuthException catch (e) {
      throw ErrorUtils.handleFirebaseAuthError(e);
    } catch (e) {
      throw ErrorUtils.handleGenericError('Reset password', e);
    }
  }

  static Stream<User?> get authStateChanges => _auth.authStateChanges();
  static User? get currentUser => _auth.currentUser;
}