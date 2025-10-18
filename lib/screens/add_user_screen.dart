// screens/add_user_screen.dart
import 'package:flutter/material.dart';
import '../services/user_service.dart';
import '../core/config.dart';
import '../shared/widgets/loading_indicator.dart';
import '../shared/widgets/custom_text_field.dart';

class AddUserScreen extends StatefulWidget {
  final String organizationId;
  final String userRole;

  const AddUserScreen({
    super.key,
    required this.organizationId,
    required this.userRole,
  });

  @override
  State<AddUserScreen> createState() => _AddUserScreenState();
}

class _AddUserScreenState extends State<AddUserScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();

  bool _isLoading = false;
  String? _selectedRegion;

  Future<void> _addUser() async {
    if (!_formKey.currentState!.validate()) return;

    if (widget.userRole == 'salesman' && _selectedRegion == null) {
      _showError('Please select a region');
      return;
    }

    setState(() => _isLoading = true);

    try {
      await UserService.addUser(
        organizationId: widget.organizationId,
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        mobileNumber: _mobileController.text.trim(),
        role: widget.userRole,
        region: _selectedRegion,
      );

      if (!mounted) return;

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${_getRoleDisplayName()} added successfully')),
      );
    } catch (e) {
      _showError('Failed to add ${_getRoleDisplayName().toLowerCase()}: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _getRoleDisplayName() {
    switch (widget.userRole) {
      case 'salesman':
        return 'Salesman';
      case 'manager':
        return 'Manager';
      default:
        return 'User';
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
        title: Text('Add ${_getRoleDisplayName()}'),
      ),
      body: _isLoading
          ? const LoadingIndicator(message: 'Adding user...')
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              CustomTextField(
                controller: _nameController,
                label: 'Full Name',
                icon: Icons.person,
                validator: (value) => value?.isEmpty ?? true
                    ? 'Please enter name'
                    : null,
              ),
              const SizedBox(height: 16),
              CustomTextField(
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
              CustomTextField(
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
              if (widget.userRole == 'salesman')
                _buildRegionDropdown(),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _addUser,
                  child: Text('Add ${_getRoleDisplayName()}'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRegionDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedRegion,
      decoration: const InputDecoration(
        labelText: 'Assign Region',
        prefixIcon: Icon(Icons.location_on),
        border: OutlineInputBorder(),
      ),
      items: AppConfig.regions.map((region) => DropdownMenuItem(
        value: region,
        child: Text(region),
      )).toList(),
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

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _mobileController.dispose();
    super.dispose();
  }
}