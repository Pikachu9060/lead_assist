import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../services/customer_service.dart';
import '../shared/widgets/empty_state.dart';
import '../shared/widgets/loading_indicator.dart';
import '../shared/utils/date_utils.dart';
import 'edit_customer_screen.dart';

class ManageCustomersScreen extends StatefulWidget {
  final String organizationId;
  const ManageCustomersScreen({super.key, required this.organizationId});

  @override
  State<ManageCustomersScreen> createState() => _ManageCustomersScreenState();
}

class _ManageCustomersScreenState extends State<ManageCustomersScreen> {
  List<QueryDocumentSnapshot> _customers = [];
  bool _loading = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadCustomers();
  }

  Future<void> _loadCustomers() async {
    try {
      final customers = await CustomerService.getAllCustomers(widget.organizationId);
      setState(() {
        _customers = customers;
        _loading = false;
      });
    } catch (e) {
      _showError('Failed to load customers: $e');
      setState(() => _loading = false);
    }
  }

  Future<void> _deleteCustomer(String customerId, String customerName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Customer'),
        content: Text('Are you sure you want to delete $customerName? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await CustomerService.deleteCustomer(widget.organizationId, customerId);
        _showSuccess('Customer deleted successfully');
        _loadCustomers(); // Refresh list
      } catch (e) {
        _showError('Failed to delete customer: $e');
      }
    }
  }

  void _viewCustomerDetails(QueryDocumentSnapshot customer) {
    final data = customer.data() as Map<String, dynamic>;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(data['name'] ?? 'Customer Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Mobile', data['mobileNumber'] ?? 'Not provided'),
              _buildDetailRow('Address', data['address'] ?? 'Not provided'),
              const SizedBox(height: 16),
              const Text('Enquiry Statistics:', style: TextStyle(fontWeight: FontWeight.bold)),
              _buildDetailRow('Total Enquiries', '${data['totalEnquiries'] ?? 0}'),
              _buildDetailRow('Active Enquiries', '${data['activeEnquiries'] ?? 0}'),
              const SizedBox(height: 16),
              _buildDetailRow('Created', DateUtilHelper.formatDateTime(data['createdAt'])),
              if (data['updatedAt'] != null)
                _buildDetailRow('Last Updated', DateUtilHelper.formatDateTime(data['updatedAt'])),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _editCustomer(customer.id, data);
            },
            child: const Text('Edit'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  void _searchCustomers(String query) {
    // Implement search functionality
    // For now, we'll just filter the existing list
    _loadCustomers(); // Reload all and filter locally or implement server-side search
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Customers'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadCustomers,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by name or mobile...',
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    _loadCustomers();
                  },
                ),
              ),
              onChanged: _searchCustomers,
            ),
          ),
          Expanded(
            child: _loading
                ? const LoadingIndicator()
                : _customers.isEmpty
                ? const EmptyStateWidget(message: 'No customers found')
                : ListView.builder(
              itemCount: _customers.length,
              itemBuilder: (context, index) {
                final customer = _customers[index];
                final data = customer.data() as Map<String, dynamic>;

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: ListTile(
                    leading: const Icon(Icons.person, color: Colors.green),
                    title: Text(data['name'] ?? 'Unknown Customer'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Mobile: ${data['mobileNumber'] ?? 'No mobile'}'),
                        Text(
                          'Address: ${data['address'] ?? 'No address'}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Row(
                          children: [
                            Chip(
                              label: Text(
                                'Total: ${data['totalEnquiries'] ?? 0}',
                                style: const TextStyle(fontSize: 12),
                              ),
                              backgroundColor: Colors.blue[50],
                            ),
                            const SizedBox(width: 4),
                            Chip(
                              label: Text(
                                'Active: ${data['activeEnquiries'] ?? 0}',
                                style: const TextStyle(fontSize: 12),
                              ),
                              backgroundColor: Colors.orange[50],
                            ),
                          ],
                        ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.visibility, color: Colors.blue),
                          onPressed: () => _viewCustomerDetails(customer),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.orange),
                          onPressed: () => _editCustomer(customer.id, data),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteCustomer(customer.id, data['name']),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _editCustomer(String customerId, Map<String, dynamic> data) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditCustomerScreen(organizationId: widget.organizationId,customerId: customerId),
      ),
    ).then((_) {
      // Refresh the list after returning from edit screen
      _loadCustomers();
    });
  }
}