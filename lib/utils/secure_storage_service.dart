import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SecureStorageService {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  static const _userSessionKey = "user_session";

  /// Save UID + Role in a JSON map format
  Future<void> saveUserSession() async {
    User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      throw Exception("No logged in user");
    }

    // Fetch role from Firestore
    DocumentSnapshot doc = await FirebaseFirestore.instance
        .collection("users")
        .doc(user.uid)
        .get();

    if (!doc.exists) {
      throw Exception("User document not found in Firestore");
    }

    String role = doc["role"] ?? "unknown";

    // Build user object
    Map<String, dynamic> userData = {
      "uid": user.uid,
      "role": role,
    };

    // Wrap it in outer map like uid: {...}
    Map<String, dynamic> sessionData = {
      user.uid: userData,
    };

    // Convert to JSON string
    String jsonString = jsonEncode(sessionData);

    // Store securely
    await _storage.write(key: _userSessionKey, value: jsonString);
  }

  /// Get stored session data
  Future<Map<String, dynamic>?> getUserSession() async {
    String? jsonString = await _storage.read(key: _userSessionKey);
    if (jsonString == null) return null;

    return jsonDecode(jsonString);
  }

  /// Clear session (logout)
  Future<void> clearSession() async {
    await _storage.delete(key: _userSessionKey);
  }
}
