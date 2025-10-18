import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:leadassist/services/fcm_service.dart';
import '../shared/utils/firestore_utils.dart';
import '../shared/utils/service_utils.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static Future<UserCredential> login(String email, String password) async {
    return ServiceUtils.handleServiceOperation('Login', () async {
      final credential = await _auth.signInWithEmailAndPassword(
        email: ServiceUtils.trimField(email),
        password: ServiceUtils.trimField(password),
      );

      final user = await ServiceUtils.runTransaction((transaction) async {
        return await _getPlatformUserByEmail(email);
      });

      if (user == null) {
        await _auth.signOut();
        throw 'User not found in platform';
      }

      return credential;
    });
  }

  static Future<DocumentSnapshot?> _getPlatformUserByEmail(String email) async {
    return ServiceUtils.getDocumentByField(
      collection: FirestoreUtils.platformUsersCollection,
      field: 'email',
      value: email,
    );
  }

  static Future<Map<String, dynamic>?> getUserData(String userId) async {
    return ServiceUtils.handleServiceOperation('get user data', () async {
      final userDoc = await FirestoreUtils.platformUsersCollection.doc(userId).get();
      return userDoc.exists ? userDoc.data() as Map<String, dynamic> : null;
    });
  }

  static Future<void> logout() async {
    await FCMService.removeCurrentDevice();
    await _auth.signOut();
  }

  static Future<bool> doesEmailExist(String email) async {
    return ServiceUtils.checkDocumentExists(
      collection: FirestoreUtils.platformUsersCollection,
      field: 'email',
      value: email,
    );
  }

  static Future<void> resetPassword(String email) async {
    return ServiceUtils.handleServiceOperation('Reset password', () async {
      await _auth.sendPasswordResetEmail(email: ServiceUtils.trimField(email));
    });
  }

  static Stream<User?> get authStateChanges => _auth.authStateChanges();
  static User? get currentUser => _auth.currentUser;
}