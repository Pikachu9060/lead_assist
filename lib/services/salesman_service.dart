import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../core/config.dart';

class SalesmanService {
  static final CollectionReference _salesmenCollection =
  FirebaseFirestore.instance.collection(AppConfig.salesmenCollection);

  // Check if salesman with mobile/email exists
  static Future<bool> doesSalesmanExist({String? mobileNumber, String? email}) async {
    try {
      Query query = _salesmenCollection;

      if (mobileNumber != null) {
        query = query.where('mobileNumber', isEqualTo: mobileNumber.trim());
      } else if (email != null) {
        query = query.where('email', isEqualTo: email.trim());
      }

      final querySnapshot = await query.limit(1).get();
      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      throw 'Failed to check salesman: $e';
    }
  }

  static Future<String> addSalesman({
    required String name,
    required String email,
    required String mobileNumber,
    required String password,
    required String region, // ✅ ADDED REGION PARAMETER
  }) async {
    try {
      // Check if salesman with same mobile already exists
      final mobileExists = await doesSalesmanExist(mobileNumber: mobileNumber);
      if (mobileExists) {
        throw 'Salesman with mobile number $mobileNumber already exists';
      }

      // Check if salesman with same email already exists
      final emailExists = await doesSalesmanExist(email: email);
      if (emailExists) {
        throw 'Salesman with email $email already exists';
      }

      // Create Firebase Auth user
      final UserCredential userCredential =
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      final userId = userCredential.user!.uid;

      // Add to salesmen collection
      await _salesmenCollection.doc(userId).set({
        'name': name.trim(),
        'email': email.trim(),
        'mobileNumber': mobileNumber.trim(),
        'region': region, // ✅ ADDED REGION FIELD
        'role': AppConfig.salesmanRole,
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'totalEnquiries': 0,
        'completedEnquiries': 0,
        'pendingEnquiries': 0,
      });

      return userId;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    } catch (e) {
      throw e.toString();
    }
  }

  // Get salesmen by region
  static Future<List<QueryDocumentSnapshot>> getSalesmenByRegion(String region) async {
    try {
      final querySnapshot = await _salesmenCollection
          .where('region', isEqualTo: region)
          .where('isActive', isEqualTo: true)
          .get();
      return querySnapshot.docs;
    } catch (e) {
      throw 'Failed to load salesmen by region: $e';
    }
  }

  // Get all regions with salesman count
  static Future<Map<String, int>> getRegionStats() async {
    try {
      final salesmen = await getActiveSalesmen();
      final Map<String, int> regionStats = {};

      for (final salesman in salesmen) {
        final region = salesman['region'] ?? 'Unassigned';
        regionStats[region] = (regionStats[region] ?? 0) + 1;
      }

      return regionStats;
    } catch (e) {
      throw 'Failed to get region stats: $e';
    }
  }

  // Update salesman region
  static Future<void> updateSalesmanRegion(String salesmanId, String region) async {
    try {
      await _salesmenCollection.doc(salesmanId).update({
        'region': region,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw 'Failed to update salesman region: $e';
    }
  }

  // ... rest of the existing methods remain the same
  static Future<List<QueryDocumentSnapshot>> getActiveSalesmen() async {
    try {
      final querySnapshot = await _salesmenCollection
          .where('isActive', isEqualTo: true)
          .get();
      return querySnapshot.docs;
    } catch (e) {
      throw 'Failed to load salesmen: $e';
    }
  }

  static Stream<QuerySnapshot> getSalesmenStream() {
    return _salesmenCollection
        .where('isActive', isEqualTo: true)
        .snapshots();
  }

  static Future<DocumentSnapshot> getSalesmanById(String salesmanId) async {
    return await _salesmenCollection.doc(salesmanId).get();
  }

  static Future<void> updateSalesmanStatus(String salesmanId, bool isActive) async {
    try {
      await _salesmenCollection.doc(salesmanId).update({
        'isActive': isActive,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw 'Failed to update salesman status: $e';
    }
  }

  static Future<void> updateSalesmanEnquiryCount(String salesmanId, {
    int total = 0,
    int completed = 0,
    int pending = 0,
  }) async {
    try {
      await _salesmenCollection.doc(salesmanId).update({
        'totalEnquiries': FieldValue.increment(total),
        'completedEnquiries': FieldValue.increment(completed),
        'pendingEnquiries': FieldValue.increment(pending),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw 'Failed to update salesman counts: $e';
    }
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
}