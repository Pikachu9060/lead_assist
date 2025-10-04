import 'package:flutter/material.dart';
import '../services/enquiry_service.dart';
import '../services/salesman_service.dart';
import '../widgets/base_screen.dart';
import '../widgets/loading_indicator.dart';

class AddEnquiryScreen extends StatefulWidget {
  const AddEnquiryScreen({super.key});

  @override
  State<AddEnquiryScreen> createState() => _AddEnquiryScreenState();
}

class _AddEnquiryScreenState extends State<AddEnquiryScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _customerNameController = TextEditingController();
  final TextEditingController _productController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  String? _selectedSalesman;
  List<QueryDocumentSnapshot> _salesmen = [];
  bool _isLoading = false;
  bool _loadingSalesmen = true;

  @override
  void initState() {
    super.initState();
    _loadSalesmen();
  }

  Future<void> _loadSalesmen() async {
    try {
      final salesmen = await SalesmanService.getSalesmen();
      setState(() {
        _salesmen = salesmen;
        _loadingSalesmen = false;
      });
    } catch (e) {
      _showError('Failed to load salesmen: $e');
      setState(() => _loadingSalesmen = false);
    }
  }

  Future<void> _submitEnquiry() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedSalesman == null) {
      _showError('Please select a salesman');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final selectedSalesman = _salesmen.firstWhere(
            (doc) => doc.id == _selectedSalesman,
      );

      await EnquiryService.addEnquiry({
        'customerName': _customerNameController.text.trim(),
        'product': _productController.text.trim(),
        'description': _descriptionController.text.trim(),
        'assignedSalesmanId': _selectedSalesman,
        'assignedSalesmanName': selectedSalesman['name'],
        'status': 'pending',
      });

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
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BaseScreen(
      title: 'Add Enquiry',
      body: _isLoading
          ? const LoadingIndicator(message: 'Adding enquiry...')
          : _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_loadingSalesmen) {
      return const LoadingIndicator(message: 'Loading salesmen...');
    }

    return SingleChildScrollView(
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            _buildTextField(
              controller: _customerNameController,
              label: 'Customer Name',
              validator: (value) => value?.isEmpty ?? true
                  ? 'Please enter customer name'
                  : null,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _productController,
              label: 'Product',
              validator: (value) =>
              value?.isEmpty ?? true ? 'Please enter product' : null,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _descriptionController,
              label: 'Description',
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      maxLines: maxLines,
      validator: validator,
    );
  }

  Widget _buildSalesmanDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedSalesman,
      decoration: const InputDecoration(
        labelText: 'Assign to Salesman',
        border: OutlineInputBorder(),
      ),
      items: _salesmen.map((salesman) {
        return DropdownMenuItem(
          value: salesman.id,
          child: Text(salesman['name']),
        );
      }).toList(),
      onChanged: (value) {
        setState(() => _selectedSalesman = value);
      },
      validator: (value) {
        if (value == null) return 'Please select a salesman';
        return null;
      },
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
    _productController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}