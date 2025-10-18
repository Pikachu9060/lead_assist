import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:leadassist/services/fcm_service.dart';
import '../shared/utils/error_utils.dart';
import '../shared/utils/firestore_utils.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static Future<UserCredential> login(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: FirestoreUtils.trimField(email),
        password: FirestoreUtils.trimField(password),
      );

      // Verify user exists in platform
      final userDoc = await FirestoreUtils.platformUsersCollection
          .doc(credential.user!.uid)
          .get();

      final userData = userDoc.data() as Map<String, dynamic>;

      if (!userDoc.exists || ( userData['isActive'] != true)) {
        await _auth.signOut();
        throw 'User not found or inactive in platform';
      }

      return credential;
    } on FirebaseAuthException catch (e) {
      throw ErrorUtils.handleFirebaseAuthError(e);
    } catch (e) {
      throw ErrorUtils.handleGenericError('Login', e);
    }
  }

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
    await FCMService.removeCurrentDevice();
    await _auth.signOut();
  }

  static Future<bool> doesEmailExist(String email) async {
    try {
      final querySnapshot = await FirestoreUtils.platformUsersCollection
          .where('email', isEqualTo: FirestoreUtils.trimField(email))
          .limit(1)
          .get();
      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      throw ErrorUtils.handleFirestoreError('check email exists', e);
    }
  }

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