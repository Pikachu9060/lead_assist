// screens/edit_user_screen.dart
import 'package:flutter/material.dart';
import '../services/user_service.dart';
import '../core/config.dart';
import '../shared/widgets/loading_indicator.dart';

class EditUserScreen extends StatefulWidget {
  final String userId;
  final String organizationId;

  const EditUserScreen({
    super.key,
    required this.userId,
    required this.organizationId,
  });

  @override
  State<EditUserScreen> createState() => _EditUserScreenState();
}

class _EditUserScreenState extends State<EditUserScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();

  String? _selectedRegion;
  bool _isLoading = false;
  bool _loadingData = true;
  Map<String, dynamic>? _userData;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final data = await UserService.getUser(widget.userId);
      setState(() {
        _userData = data;
        _nameController.text = data['name'] ?? '';
        _emailController.text = data['email'] ?? '';
        _mobileController.text = data['mobileNumber'] ?? '';
        _selectedRegion = data['region'] ?? AppConfig.regions.first;
        _loadingData = false;
      });
    } catch (e) {
      _showError('Failed to load user data: $e');
      setState(() => _loadingData = false);
    }
  }

  Future<void> _updateUser() async {
    if (!_formKey.currentState!.validate()) return;

    if (_userData?['role'] == 'salesman' && _selectedRegion == null) {
      _showError('Please select a region');
      return;
    }

    setState(() => _isLoading = true);

    try {
      await UserService.updateUser(
        userId: widget.userId,
        organizationId: widget.organizationId,
        name: _nameController.text.trim(),
        mobileNumber: _mobileController.text.trim(),
        region: _selectedRegion,
      );

      if (!mounted) return;

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User updated successfully')),
      );
    } catch (e) {
      _showError('Failed to update user: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit User'),
        actions: [
          if (!_loadingData && _userData != null)
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _updateUser,
            ),
        ],
      ),
      body: _loadingData
          ? const LoadingIndicator(message: 'Loading user data...')
          : _isLoading
          ? const LoadingIndicator(message: 'Updating...')
          : _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_userData == null) {
      return const Center(child: Text('User data not found'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Basic Information',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _nameController,
                      label: 'Full Name',
                      icon: Icons.person,
                      validator: (value) => value?.isEmpty ?? true
                          ? 'Please enter name'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _emailController,
                      label: 'Email',
                      icon: Icons.email,
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter email';
                        }
                        if (!value.contains('@')) {
                          return 'Please enter valid email';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _mobileController,
                      label: 'Mobile Number',
                      icon: Icons.phone,
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
                    const SizedBox(height: 16),
                    if (_userData!['role'] == 'salesman')
                      _buildRegionDropdown(),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'User Information',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    _buildStatRow('Role', _userData!['role'] ?? 'Unknown'),
                    _buildStatRow('Status', (_userData!['isActive'] ?? true) ? 'Active' : 'Inactive'),
                    _buildStatRow('Created', _formatDate(_userData!['createdAt'])),
                    if (_userData!['role'] == 'salesman') ...[
                      _buildStatRow('Total Enquiries', _userData!['totalEnquiries'] ?? 0),
                      _buildStatRow('Completed Enquiries', _userData!['completedEnquiries'] ?? 0),
                      _buildStatRow('Pending Enquiries', _userData!['pendingEnquiries'] ?? 0),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _updateUser,
                child: const Text('Update User'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(),
      ),
      keyboardType: keyboardType,
      validator: validator,
    );
  }

  Widget _buildRegionDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedRegion,
      decoration: const InputDecoration(
        labelText: 'Region',
        prefixIcon: Icon(Icons.location_on),
        border: OutlineInputBorder(),
      ),
      items: AppConfig.regions.map((region) {
        return DropdownMenuItem(
          value: region,
          child: Text(region),
        );
      }).toList(),
      onChanged: (value) {
        setState(() => _selectedRegion = value);
      },
      validator: (value) {
        if (value == null) {
          return 'Please select a region';
        }
        return null;
      },
    );
  }

  Widget _buildStatRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          SizedBox(
            width: 150,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Text(
            value.toString(),
            style: TextStyle(
              color: label.contains('Status') && value == 'Active'
                  ? Colors.green
                  : Colors.black,
              fontWeight: label.contains('Status') ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'Unknown';
    try {
      final date = timestamp.toDate();
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return 'Invalid date';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _mobileController.dispose();
    super.dispose();
  }
}