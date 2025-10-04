import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/config.dart';
import '../services/auth_service.dart';
import '../services/fcm_service.dart';
import '../shared/widgets/loading_indicator.dart';
import 'admin_dashboard.dart';
import 'salesman_dashboard.dart';
import 'login_screen.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: LoadingIndicator(message: 'Checking authentication...'),
          );
        }

        if (snapshot.hasData && snapshot.data != null) {
          return UserRoleWrapper(user: snapshot.data!);
        }

        return const LoginScreen();
      },
    );
  }
}

class UserRoleWrapper extends StatefulWidget {
  final User user;

  const UserRoleWrapper({super.key, required this.user});

  @override
  State<UserRoleWrapper> createState() => _UserRoleWrapperState();
}

class _UserRoleWrapperState extends State<UserRoleWrapper> {
  String? _userRole;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _getUserRoleAndInitializeFCM();
  }

  Future<void> _getUserRoleAndInitializeFCM() async {
    try {
      final userId = widget.user.uid;

      // Check admin collection first
      final adminDoc = await FirebaseFirestore.instance
          .collection(AppConfig.adminCollection)
          .doc(userId)
          .get();

      if (adminDoc.exists) {
        setState(() {
          _userRole = adminDoc['role'];
          _loading = false;
        });
        // ✅ INITIALIZE FCM FOR USER
        await FCMService.initializeForUser(userId, adminDoc['role']);
        return;
      }

      // Check salesman collection
      final salesmanDoc = await FirebaseFirestore.instance
          .collection(AppConfig.salesmenCollection)
          .doc(userId)
          .get();

      if (salesmanDoc.exists) {
        setState(() {
          _userRole = salesmanDoc['role'];
          _loading = false;
        });
        // ✅ INITIALIZE FCM FOR USER
        await FCMService.initializeForUser(userId, salesmanDoc['role']);
        return;
      }

      _showError('User not found in system');
      await AuthService.logout();

    } catch (e) {
      _showError('Failed to load user data: $e');
      setState(() => _loading = false);
    }
  }

  void _showError(String message) {
    if(mounted){
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: LoadingIndicator(message: 'Loading user data...'),
      );
    }

    switch (_userRole) {
      case AppConfig.adminRole:
        return const AdminDashboard();
      case AppConfig.salesmanRole:
        return const SalesmanDashboard();
      default:
      // If no role found, show login screen
        return const LoginScreen();
    }
  }
}