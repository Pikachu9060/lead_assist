import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../services/salesman_service.dart';
import '../shared/widgets/loading_indicator.dart';
import '../shared/widgets/empty_state.dart';
import 'edit_salesman_screen.dart';

class ManageSalesmenScreen extends StatefulWidget {
  const ManageSalesmenScreen({super.key});

  @override
  State<ManageSalesmenScreen> createState() => _ManageSalesmenScreenState();
}

class _ManageSalesmenScreenState extends State<ManageSalesmenScreen> {
  List<QueryDocumentSnapshot> _salesmen = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSalesmen();
  }

  Future<void> _loadSalesmen() async {
    try {
      final salesmen = await SalesmanService.getAllSalesmen();
      setState(() {
        _salesmen = salesmen;
        _loading = false;
      });
    } catch (e) {
      _showError('Failed to load salesmen: $e');
      setState(() => _loading = false);
    }
  }

  Future<void> _deleteSalesman(String salesmanId, String salesmanName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Salesman'),
        content: Text('Are you sure you want to delete $salesmanName?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await SalesmanService.deleteSalesman(salesmanId);
        _showSuccess('Salesman deleted successfully');
        _loadSalesmen(); // Refresh list
      } catch (e) {
        _showError('Failed to delete salesman: $e');
      }
    }
  }

  Future<void> _reactivateSalesman(String salesmanId) async {
    try {
      await SalesmanService.reactivateSalesman(salesmanId);
      _showSuccess('Salesman reactivated successfully');
      _loadSalesmen();
    } catch (e) {
      _showError('Failed to reactivate salesman: $e');
    }
  }

  void _showSalesmanStats(QueryDocumentSnapshot salesman) {
    final data = salesman.data() as Map<String, dynamic>;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${data['name']} - Performance'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Total Enquiries: ${data['totalEnquiries'] ?? 0}'),
            Text('Completed: ${data['completedEnquiries'] ?? 0}'),
            Text('Pending: ${data['pendingEnquiries'] ?? 0}'),
            const SizedBox(height: 16),
            Text('Region: ${data['region'] ?? 'Not assigned'}'),
            Text('Status: ${(data['isActive'] ?? true) ? 'Active' : 'Inactive'}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
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
        title: const Text('Manage Salesmen'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadSalesmen,
          ),
        ],
      ),
      body: _loading
          ? const LoadingIndicator()
          : _salesmen.isEmpty
          ? const EmptyStateWidget(message: 'No salesmen found')
          : ListView.builder(
        itemCount: _salesmen.length,
        itemBuilder: (context, index) {
          final salesman = _salesmen[index];
          final data = salesman.data() as Map<String, dynamic>;
          final isActive = data['isActive'] ?? true;

          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            color: isActive ? null : Colors.grey[200],
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  // Leading Icon
                  Icon(
                    Icons.person,
                    color: isActive ? Colors.blue : Colors.grey,
                    size: 40,
                  ),
                  const SizedBox(width: 12),

                  // Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          data['name'] ?? 'Unknown Salesman',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Email: ${data['email'] ?? 'No email'}',
                          style: const TextStyle(fontSize: 12),
                        ),
                        Text(
                          'Mobile: ${data['mobileNumber'] ?? 'No mobile'}',
                          style: const TextStyle(fontSize: 12),
                        ),
                        Text(
                          'Region: ${data['region'] ?? 'Not assigned'}',
                          style: const TextStyle(fontSize: 12),
                        ),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.blue[50],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'Total: ${data['totalEnquiries'] ?? 0}',
                                style: const TextStyle(fontSize: 10),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.green[50],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'Completed: ${data['completedEnquiries'] ?? 0}',
                                style: const TextStyle(fontSize: 10),
                              ),
                            ),
                          ],
                        ),
                        if (!isActive)
                          Text(
                            'Inactive',
                            style: TextStyle(color: Colors.red, fontSize: 12),
                          ),
                      ],
                    ),
                  ),

                  // Actions - Using PopupMenuButton to avoid overflow
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, size: 20),
                    onSelected: (value) {
                      switch (value) {
                        case 'stats':
                          _showSalesmanStats(salesman);
                          break;
                        case 'edit':
                          _editSalesman(salesman.id, data);
                          break;
                        case 'delete':
                          _deleteSalesman(salesman.id, data['name']);
                          break;
                        case 'reactivate':
                          _reactivateSalesman(salesman.id);
                          break;
                      }
                    },
                    itemBuilder: (context) => isActive
                        ? [
                      const PopupMenuItem(
                        value: 'stats',
                        child: Row(
                          children: [
                            Icon(Icons.analytics, size: 18),
                            SizedBox(width: 8),
                            Text('View Stats'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 18),
                            SizedBox(width: 8),
                            Text('Edit'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 18, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Delete', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ]
                        : [
                      const PopupMenuItem(
                        value: 'stats',
                        child: Row(
                          children: [
                            Icon(Icons.analytics, size: 18),
                            SizedBox(width: 8),
                            Text('View Stats'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'reactivate',
                        child: Row(
                          children: [
                            Icon(Icons.restore, size: 18, color: Colors.green),
                            SizedBox(width: 8),
                            Text('Reactivate', style: TextStyle(color: Colors.green)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _editSalesman(String salesmanId, Map<String, dynamic> data) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditSalesmanScreen(salesmanId: salesmanId),
      ),
    ).then((_) {
      // Refresh the list after returning from edit screen
      _loadSalesmen();
    });
  }
}