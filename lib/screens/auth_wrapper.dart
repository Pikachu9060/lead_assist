import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/config.dart';
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
    _getUserRole();
  }

  Future<void> _getUserRole() async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection(AppConfig.usersCollection)
          .doc(widget.user.uid)
          .get();

      if (userDoc.exists) {
        setState(() {
          _userRole = userDoc['role'];
          _loading = false;
        });
      } else {
        // Create user document if it doesn't exist
        await _createUserDocument();
      }
    } catch (e) {
      _showError('Failed to load user data');
      setState(() => _loading = false);
    }
  }

  Future<void> _createUserDocument() async {
    try {
      await FirebaseFirestore.instance
          .collection(AppConfig.usersCollection)
          .doc(widget.user.uid)
          .set({
        'email': widget.user.email,
        'name': widget.user.displayName ?? 'User',
        'role': AppConfig.salesmanRole, // Default role
        'createdAt': FieldValue.serverTimestamp(),
      });

      setState(() {
        _userRole = AppConfig.salesmanRole;
        _loading = false;
      });
    } catch (e) {
      _showError('Failed to create user profile');
      setState(() => _loading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
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
        return const LoginScreen();
    }
  }
}