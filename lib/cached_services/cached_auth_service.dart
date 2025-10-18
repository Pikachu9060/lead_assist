import 'package:firebase_auth/firebase_auth.dart';
import '../hive/hive_data_manager.dart';
import '../models/user_model.dart';
import '../refactor_services/auth_service.dart';

class CachedAuthService {
  static Future<UserCredential> login(String email, String password) async {
    final credential = await AuthService.login(email, password);

    // Cache user data after successful login
    if (credential.user != null) {
      final userData = await AuthService.getUserData(credential.user!.uid);
      if (userData != null) {
        final userModel = UserModel.fromFirestore(userData, credential.user!.uid);
        await HiveDataManager.saveUser(userModel);
      }
    }

    return credential;
  }

  static Future<void> logout() async {
    await AuthService.logout();
    await HiveDataManager.clearAllData();
  }

  static Future<Map<String, dynamic>?> getUserData(String userId) async {
    // Try to get from cache first
    final cachedUser = await HiveDataManager.getUser(userId);
    if (cachedUser != null) {
      return cachedUser.toFirestore();
    }

    // Fallback to network
    final userData = await AuthService.getUserData(userId);
    if (userData != null) {
      final userModel = UserModel.fromFirestore(userData, userId);
      await HiveDataManager.saveUser(userModel);
    }

    return userData;
  }

  // Other methods remain similar but with caching
  static Future<bool> doesEmailExist(String email) async {
    return await AuthService.doesEmailExist(email);
  }

  static Future<void> resetPassword(String email) async {
    return await AuthService.resetPassword(email);
  }

  static Stream<User?> get authStateChanges => AuthService.authStateChanges;
  static User? get currentUser => AuthService.currentUser;
}