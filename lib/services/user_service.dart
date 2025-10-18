import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../core/config.dart';
import '../shared/utils/firestore_utils.dart';
import '../shared/utils/service_utils.dart';

class UserService {
  static CollectionReference get _platformUsersCollection =>
      FirestoreUtils.platformUsersCollection;

  static Future<bool> doesUserExist({
    String? mobileNumber,
    String? email,
  }) async {
    return ServiceUtils.handleServiceOperation('check user', () async {
      Query query = _platformUsersCollection;

      if (mobileNumber != null) {
        query = query.where(
          'mobileNumber',
          isEqualTo: ServiceUtils.trimField(mobileNumber),
        );
      } else if (email != null) {
        query = query.where(
          'email',
          isEqualTo: ServiceUtils.trimField(email),
        );
      }

      final querySnapshot = await query.limit(1).get();
      return querySnapshot.docs.isNotEmpty;
    });
  }

  static Future<String> addUser({
    required String organizationId,
    required String name,
    required String email,
    required String mobileNumber,
    required String role,
    String? region,
  }) async {
    StreamSubscription? subscription;
    const int maxRetries = 3;

    try {
      final mobileExists = await doesUserExist(mobileNumber: mobileNumber);
      if (mobileExists) {
        throw 'User with mobile number $mobileNumber already exists';
      }

      final emailExists = await doesUserExist(email: email);
      if (emailExists) {
        throw 'User with email $email already exists';
      }

      final docRef = _platformUsersCollection.doc();
      final completer = Completer<String>();

      subscription = docRef.snapshots().listen((snapshot) async {
        if (snapshot.exists) {
          final data = snapshot.data() as Map<String, dynamic>;
          final status = data['status'] as String?;
          final resetEmailSent = data['resetEmailSent'] as bool? ?? false;

          if (status == 'active' && !resetEmailSent) {
            try {
              await _sendPasswordResetWithRetry(email, maxRetries);
              print('✅ Password reset email sent to: $email');

              await docRef.update(
                ServiceUtils.prepareUpdateData({
                  'resetEmailSent': true,
                  'resetEmailSentAt': FieldValue.serverTimestamp(),
                }),
              );

              if (!completer.isCompleted) {
                completer.complete(docRef.id);
              }
            } catch (e) {
              print('❌ Failed to send reset email after $maxRetries attempts: $e');
              await docRef.update({
                'resetEmailError': e.toString(),
                'status': 'active',
              });

              if (!completer.isCompleted) {
                completer.complete(docRef.id);
              }
            }
          } else if (status == 'failed') {
            if (!completer.isCompleted) {
              completer.completeError('User creation failed: ${data['error']}');
            }
          }
        }
      });

      Map<String, dynamic> userData = ServiceUtils.prepareCreateData({
        'organizationId': organizationId,
        'name': ServiceUtils.trimField(name),
        'email': ServiceUtils.trimField(email),
        'mobileNumber': ServiceUtils.trimField(mobileNumber),
        'role': role,
        'isActive': true,
        'userId': docRef.id,
        'status': 'creating',
        'resetEmailSent': false,
        'createdBy': FirebaseAuth.instance.currentUser?.uid,
      });

      if (role == AppConfig.salesmanRole) {
        userData['region'] = region;
        userData['totalEnquiries'] = 0;
        userData['completedEnquiries'] = 0;
        userData['pendingEnquiries'] = 0;
      }

      await docRef.set(userData);

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

  static Future<void> _sendPasswordResetWithRetry(
      String email,
      int maxRetries,
      ) async {
    for (int i = 0; i < maxRetries; i++) {
      try {
        await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
        return;
      } catch (e) {
        if (i == maxRetries - 1) {
          rethrow;
        }
        await Future.delayed(Duration(seconds: (i + 1) * 2));
      }
    }
  }

  static Future<DocumentSnapshot> getUserById(String userId) async {
    return ServiceUtils.handleServiceOperation('get user by id', () async {
      return await _platformUsersCollection.doc(userId).get();
    });
  }

  static Future<QueryDocumentSnapshot?> getUserByEmail(String email) async {
    return ServiceUtils.handleServiceOperation('get user by email', () async {
      final querySnapshot = await _platformUsersCollection
          .where('email', isEqualTo: ServiceUtils.trimField(email))
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();

      return querySnapshot.docs.isNotEmpty ? querySnapshot.docs.first : null;
    });
  }

  static Future<List<QueryDocumentSnapshot>> getUsersByOrganizationAndRole(
      String organizationId,
      String role,
      ) async {
    return ServiceUtils.handleServiceOperation('load users', () async {
      final querySnapshot = await _platformUsersCollection
          .where('organizationId', isEqualTo: organizationId)
          .where('role', isEqualTo: role)
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .get();
      return querySnapshot.docs;
    });
  }

  static Future<List<QueryDocumentSnapshot>> getActiveUsers(
      String organizationId,
      ) async {
    return ServiceUtils.handleServiceOperation('load users', () async {
      final querySnapshot = await _platformUsersCollection
          .where('organizationId', isEqualTo: organizationId)
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .get();
      return querySnapshot.docs;
    });
  }

  static Stream<QuerySnapshot> getUsersStream(String organizationId) {
    return _platformUsersCollection
        .where('organizationId', isEqualTo: organizationId)
        .where('isActive', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  static Future<void> updateUserStatus(String userId, bool isActive) async {
    return ServiceUtils.handleServiceOperation('update user status', () async {
      final updateData = ServiceUtils.prepareUpdateData({'isActive': isActive});

      if (!isActive) {
        updateData['deletedAt'] = FieldValue.serverTimestamp();
      }

      await _platformUsersCollection.doc(userId).update(updateData);
    });
  }

  static Future<void> updateUser({
    required String userId,
    required String organizationId,
    required String name,
    required String mobileNumber,
    String? region,
  }) async {
    return ServiceUtils.handleServiceOperation('update user', () async {
      final mobileExists = await ServiceUtils.checkDocumentExists(
        collection: _platformUsersCollection,
        field: 'mobileNumber',
        value: mobileNumber,
        excludeDocumentId: userId,
      );

      if (mobileExists) {
        throw 'Another user with mobile number $mobileNumber already exists in this organization';
      }

      Map<String, dynamic> updateData = ServiceUtils.prepareUpdateData({
        'name': ServiceUtils.trimField(name),
        'mobileNumber': ServiceUtils.trimField(mobileNumber),
      });

      if (region != null) {
        updateData['region'] = region;
      }

      await _platformUsersCollection.doc(userId).update(updateData);
    });
  }

  static Future<void> updateUserEnquiryCount(
      String userId, {
        int total = 0,
        int completed = 0,
        int pending = 0,
      }) async {
    return ServiceUtils.handleServiceOperation('update user counts', () async {
      await _platformUsersCollection.doc(userId).update(
        ServiceUtils.prepareUpdateData({
          'totalEnquiries': FieldValue.increment(total),
          'completedEnquiries': FieldValue.increment(completed),
          'pendingEnquiries': FieldValue.increment(pending),
        }),
      );
    });
  }

  static Future<List<QueryDocumentSnapshot>> getSalesmenByRegion(
      String organizationId,
      String region,
      ) async {
    return ServiceUtils.handleServiceOperation('load salesmen by region', () async {
      final querySnapshot = await _platformUsersCollection
          .where('organizationId', isEqualTo: organizationId)
          .where('role', isEqualTo: AppConfig.salesmanRole)
          .where('region', isEqualTo: region)
          .where('isActive', isEqualTo: true)
          .get();
      return querySnapshot.docs;
    });
  }

  static Future<Map<String, int>> getRegionStats(String organizationId) async {
    return ServiceUtils.handleServiceOperation('get region stats', () async {
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
    });
  }

  static Future<void> updateSalesmanRegion(String userId, String region) async {
    return ServiceUtils.handleServiceOperation('update salesman region', () async {
      await _platformUsersCollection
          .doc(userId)
          .update(ServiceUtils.prepareUpdateData({'region': region}));
    });
  }

  static Future<Map<String, dynamic>> getUser(String userId) async {
    return ServiceUtils.handleServiceOperation('get user', () async {
      final doc = await _platformUsersCollection.doc(userId).get();
      if (!doc.exists) throw 'User not found';
      return doc.data() as Map<String, dynamic>;
    });
  }

  static Future<List<QueryDocumentSnapshot>> getUsersByOrganization(
      String organizationId,
      ) async {
    return ServiceUtils.handleServiceOperation('load users', () async {
      final querySnapshot = await _platformUsersCollection
          .where('organizationId', isEqualTo: organizationId)
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .get();
      return querySnapshot.docs;
    });
  }

  static Future<Map<String, int>> getUserCountsByRole(
      String organizationId,
      ) async {
    return ServiceUtils.handleServiceOperation('get user counts', () async {
      final users = await getUsersByOrganization(organizationId);
      final Map<String, int> roleCounts = {};

      for (final user in users) {
        final role = user['role'] ?? 'unknown';
        roleCounts[role] = (roleCounts[role] ?? 0) + 1;
      }

      return roleCounts;
    });
  }

  static Future<List<QueryDocumentSnapshot>> searchUsers({
    required String organizationId,
    required String query,
    String? role,
  }) async {
    return ServiceUtils.handleServiceOperation('search users', () async {
      if (query.trim().isEmpty) {
        return await getUsersByOrganization(organizationId);
      }

      final searchTerm = query.toLowerCase();
      final users = await getUsersByOrganization(organizationId);

      return users.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final name = data['name']?.toString().toLowerCase() ?? '';
        final email = data['email']?.toString().toLowerCase() ?? '';
        final mobile = data['mobileNumber']?.toString().toLowerCase() ?? '';

        return name.contains(searchTerm) ||
            email.contains(searchTerm) ||
            mobile.contains(searchTerm) ||
            name.startsWith(searchTerm) ||
            email.startsWith(searchTerm);
      }).toList();
    });
  }

  static Future<void> reactivateUser(String userId) async {
    return ServiceUtils.handleServiceOperation('reactivate user', () async {
      await _platformUsersCollection
          .doc(userId)
          .update(ServiceUtils.prepareUpdateData({'isActive': true}));
    });
  }

  static Future<String> createOwnerUser({
    required String organizationId,
    required String name,
    required String email,
    required String mobileNumber,
  }) async {
    return ServiceUtils.handleServiceOperation('create owner', () async {
      final emailExists = await doesUserExist(email: email);
      if (emailExists) {
        throw 'User with email $email already exists';
      }

      final docRef = _platformUsersCollection.doc();

      Map<String, dynamic> userData = ServiceUtils.prepareCreateData({
        'organizationId': organizationId,
        'name': ServiceUtils.trimField(name),
        'email': ServiceUtils.trimField(email),
        'mobileNumber': ServiceUtils.trimField(mobileNumber),
        'role': 'owner',
        'isActive': true,
        'userId': docRef.id,
      });

      await docRef.set(userData);
      return docRef.id;
    });
  }
}