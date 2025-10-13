// screens/login_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:leadassist/core/config.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import '../shared/widgets/loading_indicator.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _isSignUp = false;

  // Organization signup fields
  final TextEditingController _orgNameController = TextEditingController();
  final TextEditingController _ownerNameController = TextEditingController();
  final TextEditingController _ownerMobileController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await AuthService.login(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );
      // Navigation handled by AuthWrapper
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;

    if (_passwordController.text != _confirmPasswordController.text) {
      _showError('Passwords do not match');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Create organization first
      final orgId = await _createOrganization();

      // Create owner user
      await UserService.addUser(
        organizationId: orgId,
        name: _ownerNameController.text.trim(),
        email: _emailController.text.trim(),
        mobileNumber: _ownerMobileController.text.trim(),
        role: 'owner',
      );

      if (!mounted) return;

      // Show success message and switch to login
      setState(() {
        _isSignUp = false;
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Organization registered successfully! Check your email for password setup.'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 5),
        ),
      );

      // Clear form
      _orgNameController.clear();
      _ownerNameController.clear();
      _ownerMobileController.clear();
      _confirmPasswordController.clear();

    } catch (e) {
      _showError('Failed to register organization: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<String> _createOrganization() async {
    try {
      final organizationsRef = FirebaseFirestore.instance.collection('organizations');
      final orgDoc = organizationsRef.doc();

      await orgDoc.set({
        'name': _orgNameController.text.trim(),
        'ownerEmail': _emailController.text.trim(),
        'status': 'active',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'regions': AppConfig.regions, // Default regions
      });

      return orgDoc.id;
    } catch (e) {
      throw 'Failed to create organization: $e';
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _toggleSignUp() {
    setState(() {
      _isSignUp = !_isSignUp;
      // Clear form when switching
      if (!_isSignUp) {
        _orgNameController.clear();
        _ownerNameController.clear();
        _ownerMobileController.clear();
        _confirmPasswordController.clear();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: LoadingIndicator(message: 'Processing...'))
          : Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const FlutterLogo(size: 80),
                const SizedBox(height: 32),
                Text(
                  'Lead Assist',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  _isSignUp ? 'Organization Registration' : 'Admin & Salesman Portal',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                if (_isSignUp) ...[
                  // Organization Name
                  SizedBox(
                    width: 400,
                    child: TextFormField(
                      controller: _orgNameController,
                      decoration: const InputDecoration(
                        labelText: 'Organization Name',
                        prefixIcon: Icon(Icons.business),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter organization name';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Owner Name
                  SizedBox(
                    width: 400,
                    child: TextFormField(
                      controller: _ownerNameController,
                      decoration: const InputDecoration(
                        labelText: 'Owner Name',
                        prefixIcon: Icon(Icons.person),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter owner name';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Email Field
                SizedBox(
                  width: 400,
                  child: TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email),
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter your email';
                      }
                      if (!value.contains('@')) {
                        return 'Please enter a valid email';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 16),

                if (_isSignUp) ...[
                  // Owner Mobile
                  SizedBox(
                    width: 400,
                    child: TextFormField(
                      controller: _ownerMobileController,
                      decoration: const InputDecoration(
                        labelText: 'Mobile Number',
                        prefixIcon: Icon(Icons.phone),
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter mobile number';
                        }
                        if (value.trim().length < 10) {
                          return 'Please enter valid mobile number';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Password Field
                SizedBox(
                  width: 400,
                  child: TextFormField(
                    controller: _passwordController,
                    decoration: InputDecoration(
                      labelText: _isSignUp ? 'Password' : 'Password',
                      prefixIcon: const Icon(Icons.lock),
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() => _obscurePassword = !_obscurePassword);
                        },
                      ),
                    ),
                    obscureText: _obscurePassword,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your password';
                      }
                      if (value.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 16),

                if (_isSignUp) ...[
                  // Confirm Password
                  SizedBox(
                    width: 400,
                    child: TextFormField(
                      controller: _confirmPasswordController,
                      decoration: const InputDecoration(
                        labelText: 'Confirm Password',
                        prefixIcon: Icon(Icons.lock_outline),
                        border: OutlineInputBorder(),
                      ),
                      obscureText: _obscurePassword,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please confirm your password';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                const SizedBox(height: 24),
                SizedBox(
                  width: 400,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isSignUp ? _signUp : _login,
                    child: Text(_isSignUp ? 'Register Organization' : 'Login'),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: 400,
                  child: TextButton(
                    onPressed: _toggleSignUp,
                    child: Text(
                      _isSignUp
                          ? 'Already have an account? Login'
                          : 'Need an organization? Sign up',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                if (!_isSignUp) ...[
                  const SizedBox(height: 16),
                  SizedBox(
                    width: 400,
                    child: TextButton(
                      onPressed: () {
                        // Forgot password functionality
                        if (_emailController.text.isEmpty) {
                          _showError('Please enter your email first');
                          return;
                        }
                        _resetPassword();
                      },
                      child: const Text('Forgot Password?'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _resetPassword() async {
    try {
      await AuthService.resetPassword(_emailController.text.trim());
      _showError('Password reset email sent to ${_emailController.text}');
    } catch (e) {
      _showError('Failed to send reset email: $e');
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _orgNameController.dispose();
    _ownerNameController.dispose();
    _ownerMobileController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}