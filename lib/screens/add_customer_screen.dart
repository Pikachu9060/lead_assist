import 'package:flutter/material.dart';
import '../services/customer_service.dart';
import '../shared/widgets/loading_indicator.dart';

class AddCustomerScreen extends StatefulWidget {
  final String? initialMobileNumber;
  final Function(String)? onCustomerCreated;

  final String organizationId;

  const AddCustomerScreen({
    super.key,
    this.initialMobileNumber,
    this.onCustomerCreated, required this.organizationId,
  });

  @override
  State<AddCustomerScreen> createState() => _AddCustomerScreenState();
}

class _AddCustomerScreenState extends State<AddCustomerScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Pre-fill mobile number if provided
    if (widget.initialMobileNumber != null) {
      _mobileController.text = widget.initialMobileNumber!;
    }
  }

  Future<void> _addCustomer() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await CustomerService.addCustomer(
        name: _nameController.text.trim(),
        mobileNumber: _mobileController.text.trim(),
        address: _addressController.text.trim(), organizationId: widget.organizationId,
      );

      if (!mounted) return;

      // Notify parent about customer creation
      if (widget.onCustomerCreated != null) {
        widget.onCustomerCreated!(_mobileController.text.trim());
      }

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Customer added successfully')),
      );
    } catch (e) {
      _showError('Failed to add customer: $e');
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
        title: const Text('Add Customer'),
      ),
      body: _isLoading
          ? const LoadingIndicator(message: 'Adding customer...')
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildTextField(
                controller: _nameController,
                label: 'Customer Name *',
                icon: Icons.person,
                validator: (value) => value?.isEmpty ?? true
                    ? 'Please enter customer name'
                    : null,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _mobileController,
                label: 'Mobile Number *',
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
              _buildTextField(
                controller: _addressController,
                label: 'Address *',
                icon: Icons.location_on,
                maxLines: 3,
                validator: (value) => value?.isEmpty ?? true
                    ? 'Please enter address'
                    : null,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _addCustomer,
                  child: const Text('Add Customer'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
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
      maxLines: maxLines,
      validator: validator,
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _mobileController.dispose();
    _addressController.dispose();
    super.dispose();
  }
}