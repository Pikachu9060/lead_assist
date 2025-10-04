import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../config/config.dart';

class SalesmanService {
  static final CollectionReference salesmenCollection =
  FirebaseFirestore.instance.collection(Config.salesmenCollection);

  static Future<String> addSalesman(
      Map<String, dynamic> salesmanData, String password) async {
    try {
      // Create Firebase Auth user
      final UserCredential userCredential =
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: salesmanData['email'],
        password: password,
      );

      // Add to Firestore
      await salesmenCollection.doc(userCredential.user!.uid).set({
        ...salesmanData,
        'userId': userCredential.user!.uid,
        'createdAt': FieldValue.serverTimestamp(),
        'role': 'salesman',
      });

      return userCredential.user!.uid;
    } catch (e) {
      throw 'Failed to add salesman: $e';
    }
  }

  static Future<List<QueryDocumentSnapshot>> getSalesmen() async {
    try {
      final querySnapshot = await salesmenCollection.get();
      return querySnapshot.docs;
    } catch (e) {
      throw 'Failed to load salesmen: $e';
    }
  }

  static Stream<QuerySnapshot> getSalesmenStream() {
    return salesmenCollection.snapshots();
  }

  static Future<DocumentSnapshot> getSalesmanById(String salesmanId) async {
    return await salesmenCollection.doc(salesmanId).get();
  }
}