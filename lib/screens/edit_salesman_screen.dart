import 'package:flutter/material.dart';
import '../services/salesman_service.dart';
import '../core/config.dart';
import '../shared/widgets/loading_indicator.dart';

class EditSalesmanScreen extends StatefulWidget {
  final String salesmanId;

  const EditSalesmanScreen({super.key, required this.salesmanId});

  @override
  State<EditSalesmanScreen> createState() => _EditSalesmanScreenState();
}

class _EditSalesmanScreenState extends State<EditSalesmanScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  String? _selectedRegion;
  bool _isLoading = false;
  bool _loadingData = true;
  Map<String, dynamic>? _salesmanData;

  @override
  void initState() {
    super.initState();
    _loadSalesmanData();
  }

  Future<void> _loadSalesmanData() async {
    try {
      final data = await SalesmanService.getSalesman(widget.salesmanId);
      setState(() {
        _salesmanData = data;
        _nameController.text = data['name'] ?? '';
        _emailController.text = data['email'] ?? '';
        _mobileController.text = data['mobileNumber'] ?? '';
        _selectedRegion = data['region'] ?? AppConfig.regions.first;
        _loadingData = false;
      });
    } catch (e) {
      _showError('Failed to load salesman data: $e');
      setState(() => _loadingData = false);
    }
  }

  Future<void> _updateSalesman() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedRegion == null) {
      _showError('Please select a region');
      return;
    }

    setState(() => _isLoading = true);

    try {
      await SalesmanService.updateSalesman(
        salesmanId: widget.salesmanId,
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        mobileNumber: _mobileController.text.trim(),
        region: _selectedRegion!,
      );

      if (!mounted) return;

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Salesman updated successfully')),
      );
    } catch (e) {
      _showError('Failed to update salesman: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _resetPassword() async {
    if (_passwordController.text.isEmpty) {
      _showError('Please enter a new password');
      return;
    }

    if (_passwordController.text.length < 6) {
      _showError('Password must be at least 6 characters');
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Password'),
        content: const Text('Are you sure you want to reset the password?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isLoading = true);

      try {
        // Update password in Firestore
        await SalesmanService.updateSalesmanPassword(
          salesmanId: widget.salesmanId,
          newPassword: _passwordController.text.trim(),
        );

        _passwordController.clear();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Password reset successfully')),
          );
        }
      } catch (e) {
        _showError('Failed to reset password: $e');
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
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
        title: const Text('Edit Salesman'),
        actions: [
          if (!_loadingData && _salesmanData != null)
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _updateSalesman,
            ),
        ],
      ),
      body: _loadingData
          ? const LoadingIndicator(message: 'Loading salesman data...')
          : _isLoading
          ? const LoadingIndicator(message: 'Updating...')
          : _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_salesmanData == null) {
      return const Center(child: Text('Salesman data not found'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            // Basic Information Card
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
                    _buildRegionDropdown(),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Password Reset Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Password Reset',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Enter new password to reset (optional)',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      decoration: const InputDecoration(
                        labelText: 'New Password',
                        prefixIcon: Icon(Icons.lock),
                        border: OutlineInputBorder(),
                        hintText: 'Leave empty to keep current password',
                      ),
                      obscureText: true,
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: _resetPassword,
                        child: const Text('Reset Password'),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Statistics Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Performance Statistics',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    _buildStatRow('Total Enquiries', _salesmanData!['totalEnquiries'] ?? 0),
                    _buildStatRow('Completed Enquiries', _salesmanData!['completedEnquiries'] ?? 0),
                    _buildStatRow('Pending Enquiries', _salesmanData!['pendingEnquiries'] ?? 0),
                    _buildStatRow('Status', (_salesmanData!['isActive'] ?? true) ? 'Active' : 'Inactive'),
                    _buildStatRow('Created', _formatDate(_salesmanData!['createdAt'])),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Update Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _updateSalesman,
                child: const Text('Update Salesman'),
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
    _passwordController.dispose();
    super.dispose();
  }
}