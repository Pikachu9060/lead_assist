import 'package:flutter/material.dart';
import '../services/customer_service.dart';
import '../shared/widgets/loading_indicator.dart';

class EditCustomerScreen extends StatefulWidget {
  final String customerId;

  final String organizationId;

  const EditCustomerScreen({super.key, required this.customerId, required  this.organizationId});

  @override
  State<EditCustomerScreen> createState() => _EditCustomerScreenState();
}

class _EditCustomerScreenState extends State<EditCustomerScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  bool _isLoading = false;
  bool _loadingData = true;
  Map<String, dynamic>? _customerData;

  @override
  void initState() {
    super.initState();
    _loadCustomerData();
  }

  Future<void> _loadCustomerData() async {
    try {
      final data = await CustomerService.getCustomer(widget.organizationId, widget.customerId);
      setState(() {
        _customerData = data;
        _nameController.text = data['name'] ?? '';
        _mobileController.text = data['mobileNumber'] ?? '';
        _addressController.text = data['address'] ?? '';
        _loadingData = false;
      });
    } catch (e) {
      _showError('Failed to load customer data: $e');
      setState(() => _loadingData = false);
    }
  }

  Future<void> _updateCustomer() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await CustomerService.updateCustomer(
        customerId: widget.customerId,
        name: _nameController.text.trim(),
        mobileNumber: _mobileController.text.trim(),
        address: _addressController.text.trim(), organizationId: widget.organizationId,
      );

      if (!mounted) return;

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Customer updated successfully')),
      );
    } catch (e) {
      _showError('Failed to update customer: $e');
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
        title: const Text('Edit Customer'),
        actions: [
          if (!_loadingData && _customerData != null)
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _updateCustomer,
            ),
        ],
      ),
      body: _loadingData
          ? const LoadingIndicator(message: 'Loading customer data...')
          : _isLoading
          ? const LoadingIndicator(message: 'Updating...')
          : _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_customerData == null) {
      return const Center(child: Text('Customer data not found'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            // Customer Information Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Customer Information',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _nameController,
                      label: 'Customer Name',
                      icon: Icons.person,
                      validator: (value) => value?.isEmpty ?? true
                          ? 'Please enter customer name'
                          : null,
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
                    _buildAddressField(),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Statistics Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Enquiry Statistics',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    _buildStatRow('Total Enquiries', _customerData!['totalEnquiries'] ?? 0),
                    _buildStatRow('Active Enquiries', _customerData!['activeEnquiries'] ?? 0),
                    _buildStatRow('Customer Since', _formatDate(_customerData!['createdAt'])),
                    if (_customerData!['updatedAt'] != null)
                      _buildStatRow('Last Updated', _formatDate(_customerData!['updatedAt'])),
                  ],
                ),
              ),
            ),

            // Recent Enquiries Section (Optional - you can expand this later)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Recent Activity',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    if ((_customerData!['activeEnquiries'] ?? 0) > 0)
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.orange[50],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.warning, color: Colors.orange[700], size: 16),
                            const SizedBox(width: 8),
                            Text(
                              '${_customerData!['activeEnquiries']} active enquiries',
                              style: TextStyle(
                                color: Colors.orange[700],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.green[50],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.check_circle, color: Colors.green[700], size: 16),
                            const SizedBox(width: 8),
                            const Text(
                              'No active enquiries',
                              style: TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Action Buttons
            Row(
              children: [
                // Cancel Button
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 16),
                // Update Button
                Expanded(
                  child: ElevatedButton(
                    onPressed: _updateCustomer,
                    child: const Text('Update Customer'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Delete Button (with confirmation)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _deleteCustomer,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                ),
                child: const Text('Delete Customer'),
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

  Widget _buildAddressField() {
    return TextFormField(
      controller: _addressController,
      decoration: const InputDecoration(
        labelText: 'Address',
        prefixIcon: Icon(Icons.location_on),
        border: OutlineInputBorder(),
        hintText: 'Enter complete address...',
      ),
      maxLines: 3,
      validator: (value) => value?.isEmpty ?? true
          ? 'Please enter address'
          : null,
    );
  }

  Widget _buildStatRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              value.toString(),
              style: TextStyle(
                color: label.contains('Active') && (value as int) > 0
                    ? Colors.orange
                    : Colors.black,
                fontWeight: label.contains('Active') ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteCustomer() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Customer'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to delete ${_nameController.text}?'),
            const SizedBox(height: 8),
            if ((_customerData!['activeEnquiries'] ?? 0) > 0)
              Text(
                'Warning: This customer has ${_customerData!['activeEnquiries']} active enquiries!',
                style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isLoading = true);

      try {
        await CustomerService.deleteCustomer(widget.organizationId, widget.customerId);

        if (!mounted) return;

        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Customer deleted successfully')),
        );
      } catch (e) {
        _showError('Failed to delete customer: $e');
        setState(() => _isLoading = false);
      }
    }
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
    _mobileController.dispose();
    _addressController.dispose();
    super.dispose();
  }
}