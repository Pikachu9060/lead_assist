import 'package:cloud_firestore/cloud_firestore.dart';

Future<Map<String, dynamic>?> getDocument(String collectionName, String docId)async{
  DocumentSnapshot doc = await FirebaseFirestore.instance.collection(collectionName).doc(docId).get();
  if (doc.exists) {
    return doc.data() as Map<String, dynamic>;  // return actual data
  } else {
    return null; // document does not exist
  }
}