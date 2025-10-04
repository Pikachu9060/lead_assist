
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:leadassist/pages/auth.dart';
import 'package:leadassist/pages/customer/customer_list_page.dart';
import 'package:leadassist/pages/enquiry/enquiry_page_list.dart';
import 'package:leadassist/utils/secure_storage_service.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  final SecureStorageService _storage = SecureStorageService();

  @override
  void initState() {
    super.initState();
    _decideNavigation();
  }

  Future<void> _decideNavigation() async {
    User? currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      // ❌ No logged-in user → go to Auth page
      _navigate(const Auth());
      return;
    }

    // ✅ User exists, check role from secure storage
    final session = await _storage.getUserSession();

    if (session == null || !session.containsKey(currentUser.uid)) {
      // No stored session → logout and go to Auth
      await FirebaseAuth.instance.signOut();
      await _storage.clearSession();
      _navigate(const Auth());
      return;
    }

    final role = session[currentUser.uid]["role"];

    if (role == "admin") {
      _navigate(const EnquiryPageList(role: "admin"));
    } else if (role == "salesman") {
      _navigate(const EnquiryPageList(role: "admin"));
    } else {
      // Unknown role → force logout
      await FirebaseAuth.instance.signOut();
      await _storage.clearSession();
      _navigate(const Auth());
    }
  }

  void _navigate(Widget page) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => page),
          (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
