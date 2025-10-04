import 'dart:async';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:leadassist/models/user_model.dart';
import 'package:leadassist/pages/enquiry/enquiry_page_list.dart';
import 'package:leadassist/utils/db_operations.dart';
import 'package:leadassist/utils/secure_storage_service.dart';

class Auth extends StatefulWidget {
  const Auth({super.key});

  @override
  State<Auth> createState() => _AuthState();
}

class _AuthState extends State<Auth> with SingleTickerProviderStateMixin {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final storage = SecureStorageService();

  bool loadingState = false;
  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  /// Logs in the user and navigates based on role
  Future<void> _logInUserAndNavigateAsPerRole() async {
    if(emailController.text.isEmpty || passwordController.text.isEmpty){
      return;
    }
    setState(() {
      loadingState = true;
    });
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) return;

    try {
      // Sign in with Firebase Auth
      UserCredential auth = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);

      final user = auth.user;
      if (user == null) throw Exception('User not found with email: $email');

      // Fetch user data from Firestore
      final userData = await getDocument('users', user.uid);
      if (userData == null) throw Exception('User is not registered');

      final dbUser = UserModel.fromJson(userData);

      // Navigate if admin
      if (mounted) {
        await storage.saveUserSession();
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => EnquiryPageList(role: dbUser.role,)),
              (Route<dynamic> route) => false,
        );
      }

      if(dbUser.role == 'salesman'){
        // TODO : navigate to salesman personal page where they can see assigned enquiry
        // Navigator.pushAndRemoveUntil(
        //   context,
        //   MaterialPageRoute(builder: (_) => const EnquiryPageList()),
        //       (Route<dynamic> route) => false,
        // );
      }
    } catch (e) {
      // You can also show a SnackBar or dialog here
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }finally{
      setState(() {
        loadingState = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo + Title
              CircleAvatar(
                radius: 50,
                backgroundColor: theme.primaryColor,
                child: const Text(
                  "LA",
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                "Welcome to LeadAssist",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 32),

              // Login Card
              AnimatedSize(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                child: Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Email Field
                        TextFormField(
                          controller: emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            labelText: "Email",
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Password Field
                        TextField(
                          controller: passwordController,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: "Password",
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Login Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: loadingState ? null : () =>
                                _logInUserAndNavigateAsPerRole(),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              backgroundColor: theme.primaryColor,
                            ),
                            child: loadingState ? CircularProgressIndicator() : const Text(
                              "Login",
                              style: TextStyle(fontSize: 16),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
