import 'dart:async';

import '../hive/hive_data_manager.dart';
import '../models/user_model.dart';
import '../refactor_services/user_service.dart';

class CachedUserService {
  static final Map<String, StreamSubscription> _subscriptions = {};

  static Future<void> initializeUserStream(String organizationId) async {
    if (_subscriptions.containsKey(organizationId)) return;

    final stream = UserService.getUsersStream(organizationId);
    _subscriptions[organizationId] = stream.listen((snapshot) async {
      for (final doc in snapshot.docs) {
        final userModel = UserModel.fromFirestore(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
        await HiveDataManager.saveUser(userModel);
      }
    });
  }

  static Future<void> dispose() async {
    for (final subscription in _subscriptions.values) {
      await subscription.cancel();
    }
    _subscriptions.clear();
  }

  // CRUD Operations
  static Future<String> addUser({
    required String organizationId,
    required String name,
    required String email,
    required String mobileNumber,
    required String role,
    String? region,
  }) async {
    return await UserService.addUser(
      organizationId: organizationId,
      name: name,
      email: email,
      mobileNumber: mobileNumber,
      role: role,
      region: region,
    );
  }

  static Future<void> updateUser({
    required String userId,
    required String organizationId,
    required String name,
    required String mobileNumber,
    String? region,
  }) async {
    await UserService.updateUser(
      userId: userId,
      organizationId: organizationId,
      name: name,
      mobileNumber: mobileNumber,
      region: region,
    );

    // Update cache
    final cachedUser = await HiveDataManager.getUser(userId);
    if (cachedUser != null) {
      final updatedUser = UserModel(
        userId: cachedUser.userId,
        organizationId: cachedUser.organizationId,
        name: name,
        email: cachedUser.email,
        mobileNumber: mobileNumber,
        role: cachedUser.role,
        region: region ?? cachedUser.region,
        isActive: cachedUser.isActive,
        createdAt: cachedUser.createdAt,
        updatedAt: DateTime.now(),
        totalEnquiries: cachedUser.totalEnquiries,
        completedEnquiries: cachedUser.completedEnquiries,
        pendingEnquiries: cachedUser.pendingEnquiries,
        fcmTokens: cachedUser.fcmTokens,
      );
      await HiveDataManager.saveUser(updatedUser);
    }
  }

  static Future<void> updateUserStatus(String userId, bool isActive) async {
    await UserService.updateUserStatus(userId, isActive);

    // Update cache
    final cachedUser = await HiveDataManager.getUser(userId);
    if (cachedUser != null) {
      final updatedUser = UserModel(
        userId: cachedUser.userId,
        organizationId: cachedUser.organizationId,
        name: cachedUser.name,
        email: cachedUser.email,
        mobileNumber: cachedUser.mobileNumber,
        role: cachedUser.role,
        region: cachedUser.region,
        isActive: isActive,
        createdAt: cachedUser.createdAt,
        updatedAt: DateTime.now(),
        totalEnquiries: cachedUser.totalEnquiries,
        completedEnquiries: cachedUser.completedEnquiries,
        pendingEnquiries: cachedUser.pendingEnquiries,
        fcmTokens: cachedUser.fcmTokens,
      );
      await HiveDataManager.saveUser(updatedUser);
    }
  }

  static Future<void> updateUserEnquiryCount(
      String userId, {
        int total = 0,
        int completed = 0,
        int pending = 0,
      }) async {
    await UserService.updateUserEnquiryCount(
      userId: userId,
      total: total,
      completed: completed,
      pending: pending,
    );

    // Update cache
    final cachedUser = await HiveDataManager.getUser(userId);
    if (cachedUser != null) {
      final updatedUser = UserModel(
        userId: cachedUser.userId,
        organizationId: cachedUser.organizationId,
        name: cachedUser.name,
        email: cachedUser.email,
        mobileNumber: cachedUser.mobileNumber,
        role: cachedUser.role,
        region: cachedUser.region,
        isActive: cachedUser.isActive,
        createdAt: cachedUser.createdAt,
        updatedAt: DateTime.now(),
        totalEnquiries: cachedUser.totalEnquiries + total,
        completedEnquiries: cachedUser.completedEnquiries + completed,
        pendingEnquiries: cachedUser.pendingEnquiries + pending,
        fcmTokens: cachedUser.fcmTokens,
      );
      await HiveDataManager.saveUser(updatedUser);
    }
  }

  // Stream Getters

  static Stream<List<UserModel>> watchUsers(String organizationId) {
    return HiveDataManager.watchUsersByOrganization(organizationId);
  }

  static Stream<List<UserModel>> watchUsersByRole(String organizationId, String role) {
    return HiveDataManager.watchUsersByRole(organizationId, role);
  }

  static Stream<List<UserModel>> watchSearchUsers({
    required String organizationId,
    required String query,
    String? role,
  }) {
    return HiveDataManager.watchUsersByOrganization(organizationId)
        .map((users) {
      var filteredUsers = users;

      if (role != null) {
        filteredUsers = filteredUsers.where((user) => user.role == role).toList();
      }

      if (query.isNotEmpty) {
        filteredUsers = filteredUsers.where((user) =>
        user.name.toLowerCase().contains(query.toLowerCase()) ||
            user.email.toLowerCase().contains(query.toLowerCase()) ||
            user.mobileNumber.contains(query)).toList();
      }

      return filteredUsers;
    });
  }

  // Direct Getters
  static Future<UserModel?> getUserById(String userId) async {
    final cachedUser = await HiveDataManager.getUser(userId);
    if (cachedUser != null) return cachedUser;

    // Fallback to network
    final userDoc = await UserService.getUserById(userId);
    if (userDoc.exists) {
      final userModel = UserModel.fromFirestore(
        userDoc.data() as Map<String, dynamic>,
        userId,
      );
      await HiveDataManager.saveUser(userModel);
      return userModel;
    }
    return null;
  }

  static Future<Map<String, dynamic>?> getDashboardUserData(String userId) async {
    final cachedUser = await HiveDataManager.getUser(userId);
    if (cachedUser != null) {
      return {
        'name': cachedUser.name,
        'email': cachedUser.email,
        'region': cachedUser.region,
        'role': cachedUser.role,
        'isActive': cachedUser.isActive,
      };
    }

    // Fallback to network
    final userDoc = await UserService.getUserById(userId);
    if (userDoc.exists) {
      final userData = userDoc.data() as Map<String, dynamic>?;
      if (userData != null) {
        final userModel = UserModel.fromFirestore(userData, userId);
        await HiveDataManager.saveUser(userModel);
        return userData;
      }
    }
    return null;
  }


  static Future<UserModel?> getUserByEmail(String email) async {
    final users = await HiveDataManager.watchUsersByOrganization('').first;
    final cachedUser = users.firstWhere(
          (user) => user.email == email,
      orElse: () => null as UserModel,
    );

    if (cachedUser != null) return cachedUser;

    // Fallback to network
    final userDoc = await UserService.getUserByEmail(email);
    if (userDoc != null) {
      final userModel = UserModel.fromFirestore(
        userDoc.data() as Map<String, dynamic>,
        userDoc.id,
      );
      await HiveDataManager.saveUser(userModel);
      return userModel;
    }
    return null;
  }

  // Other methods
  static Future<bool> doesUserExist({String? mobileNumber, String? email}) async {
    if (mobileNumber != null) {
      final users = await HiveDataManager.watchUsersByOrganization('').first;
      return users.any((user) => user.mobileNumber == mobileNumber);
    }
    if (email != null) {
      final users = await HiveDataManager.watchUsersByOrganization('').first;
      return users.any((user) => user.email == email);
    }
    return false;
  }

  static Future<Map<String, int>> getUserCountsByRole(String organizationId) async {
    final users = await HiveDataManager.watchUsersByOrganization(organizationId).first;
    final Map<String, int> roleCounts = {};

    for (final user in users) {
      final role = user.role;
      roleCounts[role] = (roleCounts[role] ?? 0) + 1;
    }

    return roleCounts;
  }

  static Future<Map<String, int>> getRegionStats(String organizationId) async {
    final salesmen = await HiveDataManager.watchUsersByRole(organizationId, 'salesman').first;
    final Map<String, int> regionStats = {};

    for (final salesman in salesmen) {
      final region = salesman.region ?? 'Unassigned';
      regionStats[region] = (regionStats[region] ?? 0) + 1;
    }

    return regionStats;
  }
}