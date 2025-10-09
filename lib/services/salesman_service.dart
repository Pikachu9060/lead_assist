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
    required String region,
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

      // Generate a unique ID for the salesman
      final docRef = _salesmenCollection.doc();

      // Add to salesmen collection only (no Firebase Auth user creation)
      await docRef.set({
        'createdBy': FirebaseAuth.instance.currentUser?.uid,
        'name': name.trim(),
        'email': email.trim(),
        'mobileNumber': mobileNumber.trim(),
        'region': region,
        'role': AppConfig.salesmanRole,
        'isActive': true,
        'salesmanId': docRef.id, // Store the document ID as salesmanId
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'totalEnquiries': 0,
        'completedEnquiries': 0,
        'pendingEnquiries': 0,
      });

      return docRef.id;
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

  // Get salesman by email (for login purposes)
  static Future<QueryDocumentSnapshot?> getSalesmanByEmail(String email) async {
    try {
      final querySnapshot = await _salesmenCollection
          .where('email', isEqualTo: email.trim())
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();

      return querySnapshot.docs.isNotEmpty ? querySnapshot.docs.first : null;
    } catch (e) {
      throw 'Failed to get salesman by email: $e';
    }
  }

  // Verify salesman credentials
  static Future<bool> verifySalesmanCredentials(String email, String password) async {
    try {
      final salesman = await getSalesmanByEmail(email);
      if (salesman != null) {
        final data = salesman.data() as Map<String, dynamic>;
        return data['password'] == password;
      }
      return false;
    } catch (e) {
      throw 'Failed to verify credentials: $e';
    }
  }

// Get all salesmen (including inactive)
  static Future<List<QueryDocumentSnapshot>> getAllSalesmen() async {
    try {
      final querySnapshot = await _salesmenCollection
          .orderBy('createdAt', descending: true)
          .get();
      return querySnapshot.docs;
    } catch (e) {
      throw 'Failed to load salesmen: $e';
    }
  }

// Delete salesman (soft delete - set isActive to false)
  static Future<void> deleteSalesman(String salesmanId) async {
    try {
      await _salesmenCollection.doc(salesmanId).update({
        'isActive': false,
        'updatedAt': FieldValue.serverTimestamp(),
        'deletedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw 'Failed to delete salesman: $e';
    }
  }

// Reactivate salesman
  static Future<void> reactivateSalesman(String salesmanId) async {
    try {
      await _salesmenCollection.doc(salesmanId).update({
        'isActive': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw 'Failed to reactivate salesman: $e';
    }
  }

// Update salesman profile
  static Future<void> updateSalesman({
    required String salesmanId,
    required String name,
    required String email,
    required String mobileNumber,
    required String region,
  }) async {
    try {
      // Check if another salesman with same mobile exists (excluding current salesman)
      final mobileQuery = await _salesmenCollection
          .where('mobileNumber', isEqualTo: mobileNumber.trim())
          .where(FieldPath.documentId, isNotEqualTo: salesmanId)
          .limit(1)
          .get();

      if (mobileQuery.docs.isNotEmpty) {
        throw 'Another salesman with mobile number $mobileNumber already exists';
      }

      // Check if another salesman with same email exists (excluding current salesman)
      final emailQuery = await _salesmenCollection
          .where('email', isEqualTo: email.trim())
          .where(FieldPath.documentId, isNotEqualTo: salesmanId)
          .limit(1)
          .get();

      if (emailQuery.docs.isNotEmpty) {
        throw 'Another salesman with email $email already exists';
      }

      await _salesmenCollection.doc(salesmanId).update({
        'name': name.trim(),
        'email': email.trim(),
        'mobileNumber': mobileNumber.trim(),
        'region': region,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw e.toString();
    }
  }
  static Future<Map<String, dynamic>> getSalesman(String salesmanId) async {
    try {
      final doc = await _salesmenCollection.doc(salesmanId).get();
      if (!doc.exists) {
        throw 'Salesman not found';
      }
      return doc.data() as Map<String, dynamic>;
    } catch (e) {
      throw 'Failed to get salesman: $e';
    }
  }

  // Update salesman password
  static Future<void> updateSalesmanPassword({
    required String salesmanId,
    required String newPassword,
  }) async {
    try {
      await _salesmenCollection.doc(salesmanId).update({
        'password': newPassword.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw 'Failed to update password: $e';
    }
  }
}