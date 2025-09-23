import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'customer/customer_list_page.dart';

class MobileAuth extends StatefulWidget {
  const MobileAuth({super.key});

  @override
  State<MobileAuth> createState() => _MobileAuthState();
}

class _MobileAuthState extends State<MobileAuth>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;


  // Admin login (OTP)
  final _mobileController = TextEditingController();
  final _otpController = TextEditingController();
  bool _otpSent = false;
  bool _isVerifying = false;
  bool _isResendAvailable = false;
  int _resendSeconds = 60;
  Timer? _timer;
  final RegExp mobileRegex = RegExp(r'^[6-9]\d{9}$');
  String? setVerificationId;

  // Salesman login (ID + Password)
  final _salesmanIdController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {}); // Refresh for AnimatedSize when tab changes
    });
  }

  @override
  void dispose() {
    _mobileController.dispose();
    _otpController.dispose();
    _salesmanIdController.dispose();
    _passwordController.dispose();
    _timer?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  // ---------------- OTP LOGIC ----------------
  void _startResendTimer() {
    _resendSeconds = 60;
    _isResendAvailable = false;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_resendSeconds > 0) {
          _resendSeconds--;
        } else {
          _isResendAvailable = true;
          timer.cancel();
        }
      });
    });
  }

  void _sendOtp() async{
    if (!mobileRegex.hasMatch(_mobileController.text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Enter a valid Indian mobile number")),
      );
      return;
    }
    print("Mobile Number: ${_mobileController.text}");
    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: "+91${_mobileController.text}",
      verificationCompleted: (PhoneAuthCredential credential) async {
        // Auto-login on some devices
        await FirebaseAuth.instance.signInWithCredential(credential);
        // Navigator.pushReplacement(
        //   context,
        //   MaterialPageRoute(
        //     builder: (_) => const CustomerListPage(showMenu: true),
        //   ),
        // );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("OTP verified successfully!")),
        );
      },
      verificationFailed: (FirebaseAuthException e) {
        print('Error: ${e.message}');
      },
      codeSent: (String verificationId, int? resendToken) {
        // Save verificationId for OTP verification step
        setVerificationId = verificationId;
        setState(() {
          _otpSent = true;
        });
        print('OTP sent! Verification ID: $verificationId');
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        // Optional: handle timeout
      },
    );
    _startResendTimer();
  }

  void _verifyOtp() async {
    setState(() => _isVerifying = true);

    PhoneAuthCredential credential = PhoneAuthProvider.credential(
      verificationId: setVerificationId ?? "",
      smsCode: _otpController.text,
    );

    try {
      UserCredential userCredential =
      await FirebaseAuth.instance.signInWithCredential(credential);

      if (userCredential.user != null) {
        print('Admin logged in!');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => CustomerListPage(),
          ),
        );
        setState(() => _isVerifying = false);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("OTP verified successfully!")),
        );
      }
    } catch (e) {
      print('OTP verification failed: $e');
    }
  }

  void _resendOtp() {
    _otpController.clear();
    _sendOtp();
  }

  // ---------------- SALESMAN LOGIN ----------------
  void _loginSalesman() {
    String id = _salesmanIdController.text.trim();
    String password = _passwordController.text.trim();

    if (id.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Enter ID and password")),
      );
      return;
    }

    // TODO: Firebase Auth / custom validation
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => CustomerListPage(),
      ),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Welcome Salesman $id")),
    );
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
                      color: Colors.white),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                "Welcome to LeadAssist",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 32),

              // Dynamic Card
              AnimatedSize(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                child: Card(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  elevation: 4,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TabBar(
                        controller: _tabController,
                        labelColor: theme.primaryColor,
                        unselectedLabelColor: Colors.grey,
                        indicatorColor: theme.primaryColor,
                        tabs: const [
                          Tab(text: "Admin Login"),
                          Tab(text: "Salesman Login"),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: _tabController.index == 0
                            ? Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Admin Login
                            TextFormField(
                              controller: _mobileController,
                              enabled: !_otpSent,
                              keyboardType: TextInputType.phone,
                              decoration: const InputDecoration(
                                labelText: "Mobile Number",
                                prefixText: "+91 ",
                                border: OutlineInputBorder(),
                              ),
                              maxLength: 10,
                            ),
                            const SizedBox(height: 20),
                            if (_otpSent)
                              TextField(
                                controller: _otpController,
                                keyboardType: TextInputType.number,
                                maxLength: 6,
                                decoration: const InputDecoration(
                                  labelText: "Enter OTP",
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            if (_otpSent) const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _isVerifying
                                    ? null
                                    : _otpSent
                                    ? _verifyOtp
                                    : _sendOtp,
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 16),
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                      BorderRadius.circular(12)),
                                  backgroundColor: theme.primaryColor,
                                ),
                                child: Text(
                                  _otpSent
                                      ? (_isVerifying
                                      ? "Verifying..."
                                      : "Verify OTP")
                                      : "Send OTP",
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ),
                            ),
                            if (_otpSent)
                              TextButton(
                                onPressed: _isResendAvailable
                                    ? _resendOtp
                                    : null,
                                child: Text(_isResendAvailable
                                    ? "Resend OTP"
                                    : "Resend OTP in $_resendSeconds sec"),
                              ),
                          ],
                        )
                            : Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Salesman Login
                            TextField(
                              controller: _salesmanIdController,
                              decoration: const InputDecoration(
                                labelText: "Salesman ID",
                                border: OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextField(
                              controller: _passwordController,
                              obscureText: true,
                              decoration: const InputDecoration(
                                labelText: "Password",
                                border: OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: 24),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _loginSalesman,
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 16),
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                      BorderRadius.circular(12)),
                                  backgroundColor: theme.primaryColor,
                                ),
                                child: const Text(
                                  "Login",
                                  style: TextStyle(fontSize: 16),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
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
