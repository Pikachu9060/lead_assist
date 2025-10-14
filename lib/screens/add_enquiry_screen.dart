// screens/add_enquiry_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../services/enquiry_service.dart';
import '../services/customer_service.dart';
import '../services/user_service.dart';
import '../shared/widgets/loading_indicator.dart';
import '../shared/widgets/empty_state.dart';
import '../shared/widgets/error_widget.dart';
import 'add_customer_screen.dart';

class AddEnquiryScreen extends StatefulWidget {
  final String organizationId;

  const AddEnquiryScreen({super.key, required this.organizationId});

  @override
  State<AddEnquiryScreen> createState() => _AddEnquiryScreenState();
}

class _AddEnquiryScreenState extends State<AddEnquiryScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _customerNameController = TextEditingController();
  final TextEditingController _customerMobileController =
      TextEditingController();
  final TextEditingController _productController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  String? _selectedUserId;
  List<QueryDocumentSnapshot> _salesmen = [];
  bool _isLoading = false;
  bool _loadingSalesmen = true;
  String? _loadError;

  // Customer state
  String? _customerId;
  bool _searchingCustomer = false;
  bool _customerFound = false;

  @override
  void initState() {
    super.initState();
    _loadSalesmen();
  }

  Future<void> _loadSalesmen() async {
    try {
      final salesmen = await UserService.getUsersByOrganizationAndRole(
        widget.organizationId,
        'salesman',
      );
      setState(() {
        _salesmen = salesmen;
        _loadingSalesmen = false;
      });
    } catch (e) {
      setState(() {
        _loadError = e.toString();
        _loadingSalesmen = false;
      });
    }
  }

  Future<void> _searchCustomer() async {
    if (_customerMobileController.text.trim().isEmpty) {
      _showError('Please enter mobile number to search');
      return;
    }

    setState(() => _searchingCustomer = true);

    try {
      final customer = await CustomerService.getCustomerByMobile(
        widget.organizationId,
        _customerMobileController.text.trim(),
      );

      if (customer != null) {
        // Customer found - auto-fill details
        final customerData = customer.data() as Map<String, dynamic>;
        setState(() {
          _customerId = customer.id;
          _customerNameController.text = customerData['name'] ?? '';
          _customerFound = true;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Customer found! Details auto-filled.'),
            ),
          );
        }
      } else {
        // Customer not found - navigate to add customer screen
        final newMobile = await _navigateToAddCustomer();
        if (newMobile != null) {
          _customerMobileController.text = newMobile;
          // Retry search after adding customer
          _searchCustomer();
        }
      }
    } catch (e) {
      _showError('Failed to search customer: $e');
    } finally {
      if (mounted) {
        setState(() => _searchingCustomer = false);
      }
    }
  }

  Future<String?> _navigateToAddCustomer() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddCustomerScreen(
          initialMobileNumber: _customerMobileController.text.trim(),
          onCustomerCreated: (mobileNumber) {
            return mobileNumber;
          },
          organizationId: widget.organizationId,
        ),
      ),
    );

    return result;
  }

  Future<void> _submitEnquiry() async {
    if (!_formKey.currentState!.validate()) return;

    if (_customerId == null) {
      _showError('Please search and select a customer first');
      return;
    }

    if (_selectedUserId == null) {
      _showError('Please select a salesman');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final selectedUser = _salesmen.firstWhere(
        (doc) => doc.id == _selectedUserId,
      );

      await EnquiryService.addEnquiryWithCustomer(
        customerId: _customerId!,
        customerName: _customerNameController.text.trim(),
        customerMobile: _customerMobileController.text.trim(),
        product: _productController.text.trim(),
        description: _descriptionController.text.trim(),
        assignedSalesmanId: _selectedUserId!,
        assignedSalesmanName: selectedUser['name'],
        organizationId: widget.organizationId,
      );

      if (!mounted) return;

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enquiry added successfully')),
      );
    } catch (e) {
      _showError('Failed to add enquiry: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _clearCustomer() {
    setState(() {
      _customerId = null;
      _customerNameController.clear();
      _customerFound = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Enquiry')),
      body: _isLoading
          ? const LoadingIndicator(message: 'Adding enquiry...')
          : _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_loadingSalesmen) {
      return const LoadingIndicator(message: 'Loading salesmen...');
    }

    if (_loadError != null) {
      return CustomErrorWidget(message: _loadError!, onRetry: _loadSalesmen);
    }

    if (_salesmen.isEmpty) {
      return const EmptyStateWidget(
        message: 'No active salesmen available\nPlease add salesmen first',
        icon: Icons.people,
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            // Customer Search Section
            _buildCustomerSearchSection(),
            const SizedBox(height: 16),

            // Customer Details (shown when customer found)
            if (_customerFound) _buildCustomerDetailsSection(),

            const SizedBox(height: 16),
            _buildTextField(
              controller: _productController,
              label: 'Product *',
              validator: (value) =>
                  value?.isEmpty ?? true ? 'Please enter product' : null,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _descriptionController,
              label: 'Description *',
              maxLines: 4,
              validator: (value) =>
                  value?.isEmpty ?? true ? 'Please enter description' : null,
            ),
            const SizedBox(height: 16),
            _buildSalesmanDropdown(),
            const SizedBox(height: 24),
            _buildSubmitButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerSearchSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Customer Search',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _customerMobileController,
                    decoration: const InputDecoration(
                      labelText: 'Mobile Number *',
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
                const SizedBox(width: 8),
                _searchingCustomer
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                  style: ButtonStyle(
                    backgroundColor: WidgetStateProperty.all<Color>(Colors.purple),
                    foregroundColor: WidgetStateProperty.all<Color>(Colors.white),
                  ),
                  onPressed: _searchCustomer,
                  child: const Text('Search'),
                ),
              ],
            ),
            if (_customerFound)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  '✓ Customer verified',
                  style: TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerDetailsSection() {
    return Card(
      color: Colors.green[50],
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Customer Details',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: _clearCustomer,
                  tooltip: 'Clear customer',
                ),
              ],
            ),
            const SizedBox(height: 8),
            _buildTextField(
              controller: _customerNameController,
              label: 'Customer Name *',
              icon: Icons.person,
              validator: (value) =>
                  value?.isEmpty ?? true ? 'Please enter customer name' : null,
            ),
            const SizedBox(height: 8),
            Text(
              'Mobile: ${_customerMobileController.text}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    IconData? icon,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: icon != null ? Icon(icon) : null,
        border: const OutlineInputBorder(),
      ),
      maxLines: maxLines,
      validator: validator,
    );
  }

  Widget _buildSalesmanDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedUserId,
      decoration: const InputDecoration(
        labelText: 'Assign to Salesman *',
        border: OutlineInputBorder(),
      ),
      items: _salesmen.map((user) {
        final region = user['region'] ?? 'No Region';
        return DropdownMenuItem(
          value: user.id,
          child: RichText(
            text: TextSpan(
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black,
              ),
              children: [
                TextSpan(
                  text: user['name'],
                  style: const TextStyle(
                    fontWeight: FontWeight.w600, // Semi-bold instead of bold
                  ),
                ),
                const TextSpan(text: ' • '), // Using bullet instead of colon
                TextSpan(
                  text: region,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontStyle: FontStyle.italic,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
      onChanged: (value) {
        setState(() => _selectedUserId = value);
      },
      validator: (value) {
        if (value == null) return 'Please select a salesman';
        return null;
      },
      isExpanded: true,
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _submitEnquiry,
        child: const Text('Add Enquiry'),
      ),
    );
  }

  @override
  void dispose() {
    _customerNameController.dispose();
    _customerMobileController.dispose();
    _productController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}
