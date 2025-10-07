import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ResetLinkService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  static const String _cloudFunctionUrl = 'https://your-region-your-project.cloudfunctions.net/getResetLink';

  /// Get reset link from Cloud Function and immediately delete it
  Future<ResetLinkResponse> getResetLink({
    required String userId,
    required UserType userType,
  }) async {
    try {
      // Get current user token for authentication
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User must be authenticated');
      }

      final token = await user.getIdToken();

      // Call Cloud Function
      final response = await http.post(
        Uri.parse(_cloudFunctionUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'userId': userId,
          'userType': userType.name,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return ResetLinkResponse.fromJson(data);
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error'] ?? 'Failed to get reset link');
      }
    } catch (e) {
      print('❌ Error getting reset link: $e');
      rethrow;
    }
  }

  /// Send email with reset link using your email service
  Future<void> sendPasswordEmail({
    required String email,
    required String resetLink,
    required String userName,
    required UserType userType,
  }) async {
    try {
      // Call your email service (Brevo, SendGrid, etc.)
      await _callEmailService(
        email: email,
        resetLink: resetLink,
        userName: userName,
        userType: userType,
      );

      print('✅ Password email sent to: $email');
    } catch (e) {
      print('❌ Error sending email: $e');
      rethrow;
    }
  }

  /// Mark reset link as used when password is set
  Future<void> markLinkAsUsed(String resetLinkId) async {
    try {
      await _firestore.collection('resetLinks').doc(resetLinkId).update({
        'status': 'used',
        'usedAt': FieldValue.serverTimestamp(),
      });
      print('✅ Reset link marked as used: $resetLinkId');
    } catch (e) {
      print('❌ Error marking link as used: $e');
    }
  }

  /// Monitor when user sets their password
  void monitorPasswordSetup(String userId, String resetLinkId) {
    // Listen for auth state changes (user signs in)
    _auth.authStateChanges().listen((User? user) {
      if (user != null && user.uid == userId) {
        _onPasswordSetSuccess(resetLinkId, userId);
      }
    });

    // Alternative: Listen for Firestore document changes
    _firestore.collection('salesmen').doc(userId).snapshots().listen((doc) {
      final data = doc.data();
      if (data?['status'] == 'active' || data?['passwordSet'] == true) {
        _onPasswordSetSuccess(resetLinkId, userId);
      }
    });
  }

  Future<void> _onPasswordSetSuccess(String resetLinkId, String userId) async {
    try {
      await markLinkAsUsed(resetLinkId);

      // Additional cleanup or notifications can go here
      print('🎉 Password set successfully for user: $userId');
    } catch (e) {
      print('Error in password set success handler: $e');
    }
  }

  /// Call your email service (implement based on your service)
  Future<void> _callEmailService({
    required String email,
    required String resetLink,
    required String userName,
    required UserType userType,
  }) async {
    // Example using a hypothetical email service
    final response = await http.post(
      Uri.parse('https://your-email-service.com/send'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'to': email,
        'subject': 'Set Your Password - ${userType.displayName}',
        'template': 'password_setup',
        'data': {
          'userName': userName,
          'resetLink': resetLink,
          'userType': userType.displayName,
          'appDownloadLink': 'https://yourapp.page.link/download',
        }
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to send email: ${response.body}');
    }
  }
}

class ResetLinkResponse {
  final bool success;
  final String resetLink;
  final String email;
  final String userName;
  final String userType;

  ResetLinkResponse({
    required this.success,
    required this.resetLink,
    required this.email,
    required this.userName,
    required this.userType,
  });

  factory ResetLinkResponse.fromJson(Map<String, dynamic> json) {
    return ResetLinkResponse(
      success: json['success'] ?? false,
      resetLink: json['resetLink'] ?? '',
      email: json['email'] ?? '',
      userName: json['userName'] ?? '',
      userType: json['userType'] ?? '',
    );
  }
}

enum UserType {
  salesman('salesman', 'Salesman'),
  admin('admin', 'Admin');

  final String name;
  final String displayName;

  const UserType(this.name, this.displayName);
}