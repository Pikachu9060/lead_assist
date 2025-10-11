import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import '../core/config.dart';

class AdminService {
  static final CollectionReference _adminCollection =
  FirebaseFirestore.instance.collection(AppConfig.adminCollection);

  // Check if admin with mobile/email exists
  static Future<bool> doesAdminExist({String? mobileNumber, String? email}) async {
    try {
      Query query = _adminCollection;

      if (mobileNumber != null) {
        query = query.where('mobileNumber', isEqualTo: mobileNumber.trim());
      } else if (email != null) {
        query = query.where('email', isEqualTo: email.trim());
      }

      final querySnapshot = await query.limit(1).get();
      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      throw 'Failed to check admin: $e';
    }
  }

  static Future<String> createAdmin({
    required String name,
    required String email,
    required String mobileNumber,
  }) async {
    StreamSubscription? subscription;

    try {
      // Check if admin with same mobile already exists
      final mobileExists = await doesAdminExist(mobileNumber: mobileNumber);
      if (mobileExists) {
        throw 'Admin with mobile number $mobileNumber already exists';
      }

      // Check if admin with same email already exists
      final emailExists = await doesAdminExist(email: email);
      if (emailExists) {
        throw 'Admin with email $email already exists';
      }

      final docRef = _adminCollection.doc();
      final completer = Completer<String>();

      // Listen for when Firebase Auth user is created (authUid is set)
      subscription = docRef.snapshots().listen((snapshot) async {
        if (snapshot.exists) {
          final data = snapshot.data() as Map<String, dynamic>;
          final status = data['isUserCreated'] as bool?;

          // When cloud function creates the Firebase Auth user
          if (status == true) {
            try {
              // Send password reset email from Flutter
              await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
              print('✅ Password reset email sent to: $email');

              // Update document to mark email as sent
              await docRef.update({
                'resetEmailSent': true,
                'resetEmailSentAt': FieldValue.serverTimestamp(),
                'status': 'active',
              });

              // Complete the completer with success
              if (!completer.isCompleted) {
                completer.complete(docRef.id);
              }

            } catch (e) {
              print('❌ Failed to send reset email: $e');
              // Mark error but still complete since user was created
              await docRef.update({
                'resetEmailError': e.toString(),
                'status': 'active', // User is still created in Auth
              });

              if (!completer.isCompleted) {
                completer.complete(docRef.id);
              }
            }
          }

          // If cloud function failed
          else if (status == 'failed') {
            if (!completer.isCompleted) {
              completer.completeError('Admin creation failed: ${data['error']}');
            }
          }
        }
      });

      // Add to admin collection (this triggers cloud function)
      await docRef.set({
        'createdBy': FirebaseAuth.instance.currentUser?.uid,
        'name': name.trim(),
        'email': email.trim(),
        'mobileNumber': mobileNumber.trim(),
        'role': AppConfig.adminRole,
        'isActive': true,
        'status': 'creating', // Initial status
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Wait for cloud function to create Firebase Auth user
      return await completer.future.timeout(
        Duration(seconds: 30),
        onTimeout: () => throw 'Admin creation timeout - cloud function took too long',
      );

    } catch (e) {
      throw e.toString();
    } finally {
      subscription?.cancel();
    }
  }

  // Get admin by ID
  static Future<DocumentSnapshot> getAdminById(String adminId) async {
    return await _adminCollection.doc(adminId).get();
  }

  static String _handleAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'This email is already registered.';
      case 'invalid-email':
        return 'The email address is invalid.';
      case 'operation-not-allowed':
        return 'Email/password accounts are not enabled.';
      case 'weak-password':
        return 'The password is too weak.';
      default:
        return 'An error occurred: ${e.message}';
    }
  }

  static Future<List<QueryDocumentSnapshot>> getAllAdmins() async {
    try {
      final querySnapshot = await _adminCollection
          .orderBy('createdAt', descending: true)
          .get();
      return querySnapshot.docs;
    } catch (e) {
      throw 'Failed to load admins: $e';
    }
  }

  // Delete admin (soft delete - set isActive to false)
  static Future<void> deleteAdmin(String adminId) async {
    try {
      // Don't allow deleting yourself
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser?.uid == adminId) {
        throw 'You cannot delete your own account';
      }

      await _adminCollection.doc(adminId).update({
        'isActive': false,
        'updatedAt': FieldValue.serverTimestamp(),
        'deletedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw 'Failed to delete admin: $e';
    }
  }

  // Reactivate admin
  static Future<void> reactivateAdmin(String adminId) async {
    try {
      await _adminCollection.doc(adminId).update({
        'isActive': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw 'Failed to reactivate admin: $e';
    }
  }

  // Update admin profile
  static Future<void> updateAdmin({
    required String adminId,
    required String name,
    required String mobileNumber,
  }) async {
    try {
      await _adminCollection.doc(adminId).update({
        'name': name.trim(),
        'mobileNumber': mobileNumber.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw 'Failed to update admin: $e';
    }
  }

}