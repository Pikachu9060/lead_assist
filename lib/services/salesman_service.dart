import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../core/config.dart';

class SalesmanService {
  static final CollectionReference _salesmen =
  FirebaseFirestore.instance.collection(AppConfig.salesmenCollection);
  static final CollectionReference _users =
  FirebaseFirestore.instance.collection(AppConfig.usersCollection);

  static Future<String> addSalesman({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    try {
      // Create Firebase Auth user
      final UserCredential userCredential =
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      final userId = userCredential.user!.uid;

      // Add to users collection
      await _users.doc(userId).set({
        'name': name.trim(),
        'email': email.trim(),
        'role': AppConfig.salesmanRole,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Add to salesmen collection
      await _salesmen.doc(userId).set({
        'name': name.trim(),
        'email': email.trim(),
        'phone': phone.trim(),
        'userId': userId,
        'createdAt': FieldValue.serverTimestamp(),
        'isActive': true,
      });

      return userId;
    } on FirebaseAuthException catch (e) {
      throw 'Auth Error: ${e.message}';
    } catch (e) {
      throw 'Failed to add salesman: $e';
    }
  }

  static Future<List<QueryDocumentSnapshot>> getActiveSalesmen() async {
    try {
      final querySnapshot = await _salesmen
          .where('isActive', isEqualTo: true)
          .get();
      return querySnapshot.docs;
    } catch (e) {
      throw 'Failed to load salesmen: $e';
    }
  }

  static Stream<QuerySnapshot> getSalesmenStream() {
    return _salesmen
        .where('isActive', isEqualTo: true)
        .snapshots();
  }

  static Future<DocumentSnapshot> getSalesmanById(String salesmanId) async {
    return await _salesmen.doc(salesmanId).get();
  }

  static Future<void> updateSalesmanStatus(String salesmanId, bool isActive) async {
    try {
      await _salesmen.doc(salesmanId).update({
        'isActive': isActive,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw 'Failed to update salesman status: $e';
    }
  }
}