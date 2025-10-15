// services/user_service.dart
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../core/config.dart';
import '../shared/utils/error_utils.dart';
import '../shared/utils/firestore_utils.dart';

class UserService {
  // Using FirestoreUtils for collection reference
  static CollectionReference get _platformUsersCollection =>
      FirestoreUtils.platformUsersCollection;

  // Check if user exists by mobile/email
  static Future<bool> doesUserExist({
    String? mobileNumber,
    String? email,
  }) async {
    try {
      Query query = _platformUsersCollection;

      if (mobileNumber != null) {
        query = query.where(
          'mobileNumber',
          isEqualTo: FirestoreUtils.trimField(mobileNumber),
        );
      } else if (email != null) {
        query = query.where(
          'email',
          isEqualTo: FirestoreUtils.trimField(email),
        );
      }

      final querySnapshot = await query.limit(1).get();
      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      throw ErrorUtils.handleFirestoreError('check user', e);
    }
  }

  // user_service.dart - Fixed user creation with retry mechanism
  static Future<String> addUser({
    required String organizationId,
    required String name,
    required String email,
    required String mobileNumber,
    required String role,
    String? region,
  }) async {
    StreamSubscription? subscription;
    int retryCount = 0;
    const int maxRetries = 3;

    try {
      // Check if user with same mobile already exists
      final mobileExists = await doesUserExist(mobileNumber: mobileNumber);
      if (mobileExists) {
        throw 'User with mobile number $mobileNumber already exists';
      }

      // Check if user with same email already exists
      final emailExists = await doesUserExist(email: email);
      if (emailExists) {
        throw 'User with email $email already exists';
      }

      final docRef = _platformUsersCollection.doc();
      final completer = Completer<String>();

      // Listen for Firestore document updates with retry logic
      subscription = docRef.snapshots().listen((snapshot) async {
        if (snapshot.exists) {
          final data = snapshot.data() as Map<String, dynamic>;
          final status = data['status'] as String?;
          final resetEmailSent = data['resetEmailSent'] as bool? ?? false;

          if (status == 'active' && !resetEmailSent) {
            try {
              // Send password reset email with retry
              await _sendPasswordResetWithRetry(email, maxRetries);
              print('✅ Password reset email sent to: $email');

              // Update Firestore document to mark email as sent
              await docRef.update(
                FirestoreUtils.updateTimestamp({
                  'resetEmailSent': true,
                  'resetEmailSentAt': FieldValue.serverTimestamp(),
                }),
              );

              if (!completer.isCompleted) {
                completer.complete(docRef.id);
              }
            } catch (e) {
              print(
                '❌ Failed to send reset email after $maxRetries attempts: $e',
              );
              await docRef.update({
                'resetEmailError': e.toString(),
                'status': 'active', // Mark as active even if email fails
              });

              if (!completer.isCompleted) {
                completer.complete(docRef.id); // Still complete but log error
              }
            }
          } else if (status == 'failed') {
            if (!completer.isCompleted) {
              completer.completeError('User creation failed: ${data['error']}');
            }
          }
        }
      });

      // Add user to Firestore using FirestoreUtils for timestamps
      Map<String, dynamic> userData = FirestoreUtils.addTimestamps({
        'organizationId': organizationId,
        'name': FirestoreUtils.trimField(name),
        'email': FirestoreUtils.trimField(email),
        'mobileNumber': FirestoreUtils.trimField(mobileNumber),
        'role': role,
        'isActive': true,
        'userId': docRef.id,
        'status': 'creating',
        'resetEmailSent': false,
        'createdBy': FirebaseAuth.instance.currentUser?.uid,
      });

      // Role-specific fields
      if (role == AppConfig.salesmanRole) {
        userData['region'] = region;
        userData['totalEnquiries'] = 0;
        userData['completedEnquiries'] = 0;
        userData['pendingEnquiries'] = 0;
      }

      await docRef.set(userData);

      // Wait for the process to complete or timeout
      await completer.future.timeout(
        const Duration(seconds: 30),
        onTimeout: () =>
            throw 'User creation timeout - cloud function took too long',
      );
      return "User Created Successfully !";
    } catch (e) {
      print(e.toString());
    } finally {
      subscription?.cancel();
      return '';
    }
  }

  // Helper method for retry logic
  static Future<void> _sendPasswordResetWithRetry(
    String email,
    int maxRetries,
  ) async {
    for (int i = 0; i < maxRetries; i++) {
      try {
        await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
        return; // Success, exit retry loop
      } catch (e) {
        if (i == maxRetries - 1) {
          rethrow; // Last attempt failed
        }
        await Future.delayed(
          Duration(seconds: (i + 1) * 2),
        ); // Exponential backoff
      }
    }
  }

  // Get user by ID
  static Future<DocumentSnapshot> getUserById(String userId) async {
    return await _platformUsersCollection.doc(userId).get();
  }

  // Get user by email (for login)
  static Future<QueryDocumentSnapshot?> getUserByEmail(String email) async {
    try {
      final querySnapshot = await _platformUsersCollection
          .where('email', isEqualTo: FirestoreUtils.trimField(email))
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();

      return querySnapshot.docs.isNotEmpty ? querySnapshot.docs.first : null;
    } catch (e) {
      throw ErrorUtils.handleFirestoreError('get user by email', e);
    }
  }

  // Get users by organization and role
  static Future<List<QueryDocumentSnapshot>> getUsersByOrganizationAndRole(
    String organizationId,
    String role,
  ) async {
    try {
      final querySnapshot = await _platformUsersCollection
          .where('organizationId', isEqualTo: organizationId)
          .where('role', isEqualTo: role)
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .get();
      return querySnapshot.docs;
    } catch (e) {
      throw ErrorUtils.handleFirestoreError('load users', e);
    }
  }

  // Get all active users in organization
  static Future<List<QueryDocumentSnapshot>> getActiveUsers(
    String organizationId,
  ) async {
    try {
      final querySnapshot = await _platformUsersCollection
          .where('organizationId', isEqualTo: organizationId)
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .get();
      return querySnapshot.docs;
    } catch (e) {
      throw ErrorUtils.handleFirestoreError('load users', e);
    }
  }

  // Get users stream for organization
  static Stream<QuerySnapshot> getUsersStream(String organizationId) {
    return _platformUsersCollection
        .where('organizationId', isEqualTo: organizationId)
        .where('isActive', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // Update user status
  static Future<void> updateUserStatus(String userId, bool isActive) async {
    try {
      final updateData = FirestoreUtils.updateTimestamp({'isActive': isActive});

      if (!isActive) {
        updateData['deletedAt'] = FieldValue.serverTimestamp();
      }

      await _platformUsersCollection.doc(userId).update(updateData);
    } catch (e) {
      throw ErrorUtils.handleFirestoreError('update user status', e);
    }
  }

  // Update user profile
  static Future<void> updateUser({
    required String userId,
    required String organizationId,
    required String name,
    required String mobileNumber,
    String? region,
  }) async {
    try {
      // Check if another user with same mobile exists in same organization
      final mobileQuery = await _platformUsersCollection
          .where('organizationId', isEqualTo: organizationId)
          .where(
            'mobileNumber',
            isEqualTo: FirestoreUtils.trimField(mobileNumber),
          )
          .where(FieldPath.documentId, isNotEqualTo: userId)
          .limit(1)
          .get();

      if (mobileQuery.docs.isNotEmpty) {
        throw 'Another user with mobile number $mobileNumber already exists in this organization';
      }

      Map<String, dynamic> updateData = FirestoreUtils.updateTimestamp({
        'name': FirestoreUtils.trimField(name),
        'mobileNumber': FirestoreUtils.trimField(mobileNumber),
      });

      if (region != null) {
        updateData['region'] = region;
      }

      await _platformUsersCollection.doc(userId).update(updateData);
    } catch (e) {
      throw e.toString();
    }
  }

  // Update salesman enquiry counts
  static Future<void> updateUserEnquiryCount(
    String userId, {
    int total = 0,
    int completed = 0,
    int pending = 0,
  }) async {
    try {
      await _platformUsersCollection
          .doc(userId)
          .update(
            FirestoreUtils.updateTimestamp({
              'totalEnquiries': FieldValue.increment(total),
              'completedEnquiries': FieldValue.increment(completed),
              'pendingEnquiries': FieldValue.increment(pending),
            }),
          );
    } catch (e) {
      throw ErrorUtils.handleFirestoreError('update user counts', e);
    }
  }

  // Get salesmen by region in organization
  static Future<List<QueryDocumentSnapshot>> getSalesmenByRegion(
    String organizationId,
    String region,
  ) async {
    try {
      final querySnapshot = await _platformUsersCollection
          .where('organizationId', isEqualTo: organizationId)
          .where('role', isEqualTo: AppConfig.salesmanRole)
          .where('region', isEqualTo: region)
          .where('isActive', isEqualTo: true)
          .get();
      return querySnapshot.docs;
    } catch (e) {
      throw ErrorUtils.handleFirestoreError('load salesmen by region', e);
    }
  }

  // Get region stats for organization
  static Future<Map<String, int>> getRegionStats(String organizationId) async {
    try {
      final salesmen = await getUsersByOrganizationAndRole(
        organizationId,
        AppConfig.salesmanRole,
      );
      final Map<String, int> regionStats = {};

      for (final salesman in salesmen) {
        final region = salesman['region'] ?? 'Unassigned';
        regionStats[region] = (regionStats[region] ?? 0) + 1;
      }

      return regionStats;
    } catch (e) {
      throw ErrorUtils.handleGenericError('get region stats', e);
    }
  }

  // Update salesman region
  static Future<void> updateSalesmanRegion(String userId, String region) async {
    try {
      await _platformUsersCollection
          .doc(userId)
          .update(FirestoreUtils.updateTimestamp({'region': region}));
    } catch (e) {
      throw ErrorUtils.handleFirestoreError('update salesman region', e);
    }
  }

  // Get user data with error handling
  static Future<Map<String, dynamic>> getUser(String userId) async {
    try {
      final doc = await _platformUsersCollection.doc(userId).get();
      if (!doc.exists) {
        throw 'User not found';
      }
      return doc.data() as Map<String, dynamic>;
    } catch (e) {
      throw ErrorUtils.handleFirestoreError('get user', e);
    }
  }

  // Get users by organization
  static Future<List<QueryDocumentSnapshot>> getUsersByOrganization(
    String organizationId,
  ) async {
    try {
      final querySnapshot = await _platformUsersCollection
          .where('organizationId', isEqualTo: organizationId)
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .get();
      return querySnapshot.docs;
    } catch (e) {
      throw ErrorUtils.handleFirestoreError('load users', e);
    }
  }

  // Get user counts by role for organization
  static Future<Map<String, int>> getUserCountsByRole(
    String organizationId,
  ) async {
    try {
      final users = await getUsersByOrganization(organizationId);
      final Map<String, int> roleCounts = {};

      for (final user in users) {
        final role = user['role'] ?? 'unknown';
        roleCounts[role] = (roleCounts[role] ?? 0) + 1;
      }

      return roleCounts;
    } catch (e) {
      throw ErrorUtils.handleGenericError('get user counts', e);
    }
  }

  // Search users in organization
  // user_service.dart - Improved search with better Firestore queries
  static Future<List<QueryDocumentSnapshot>> searchUsers({
    required String organizationId,
    required String query,
    String? role,
  }) async {
    try {
      if (query.trim().isEmpty) {
        // Return all users if query is empty
        return await getUsersByOrganization(organizationId);
      }

      final searchTerm = query.toLowerCase();
      final users = await getUsersByOrganization(organizationId);

      // Client-side filtering for better search experience
      return users.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final name = data['name']?.toString().toLowerCase() ?? '';
        final email = data['email']?.toString().toLowerCase() ?? '';
        final mobile = data['mobileNumber']?.toString().toLowerCase() ?? '';

        // More flexible matching
        return name.contains(searchTerm) ||
            email.contains(searchTerm) ||
            mobile.contains(searchTerm) ||
            name.startsWith(searchTerm) ||
            email.startsWith(searchTerm);
      }).toList();
    } catch (e) {
      throw ErrorUtils.handleFirestoreError('search users', e);
    }
  }

  // Reactivate user
  static Future<void> reactivateUser(String userId) async {
    try {
      await _platformUsersCollection
          .doc(userId)
          .update(FirestoreUtils.updateTimestamp({'isActive': true}));
    } catch (e) {
      throw ErrorUtils.handleFirestoreError('reactivate user', e);
    }
  }

  static Future<String> createOwnerUser({
    required String organizationId,
    required String name,
    required String email,
    required String mobileNumber,
  }) async {
    try {
      // Check if user with same email already exists
      final emailExists = await doesUserExist(email: email);
      if (emailExists) {
        throw 'User with email $email already exists';
      }

      final docRef = _platformUsersCollection.doc();

      // Create owner user directly (no cloud function needed for owner)
      Map<String, dynamic> userData = FirestoreUtils.addTimestamps({
        'organizationId': organizationId,
        'name': FirestoreUtils.trimField(name),
        'email': FirestoreUtils.trimField(email),
        'mobileNumber': FirestoreUtils.trimField(mobileNumber),
        'role': 'owner',
        'isActive': true,
        'userId': docRef.id,
      });

      await docRef.set(userData);
      return docRef.id;
    } catch (e) {
      throw ErrorUtils.handleGenericError('create owner', e);
    }
  }
}
