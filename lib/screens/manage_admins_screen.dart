import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../services/admin_service.dart';
import '../shared/widgets/loading_indicator.dart';
import '../shared/widgets/empty_state.dart';

class ManageAdminsScreen extends StatefulWidget {
  const ManageAdminsScreen({super.key});

  @override
  State<ManageAdminsScreen> createState() => _ManageAdminsScreenState();
}

class _ManageAdminsScreenState extends State<ManageAdminsScreen> {
  List<QueryDocumentSnapshot> _admins = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadAdmins();
  }

  Future<void> _loadAdmins() async {
    try {
      final admins = await AdminService.getAllAdmins();
      setState(() {
        _admins = admins;
        _loading = false;
      });
    } catch (e) {
      _showError('Failed to load admins: $e');
      setState(() => _loading = false);
    }
  }

  Future<void> _deleteAdmin(String adminId, String adminName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Admin'),
        content: Text('Are you sure you want to delete $adminName?'),
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
        await AdminService.deleteAdmin(adminId);
        _showSuccess('Admin deleted successfully');
        _loadAdmins(); // Refresh list
      } catch (e) {
        _showError('Failed to delete admin: $e');
      }
    }
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
      appBar: AppBar(title: const Text('Manage Admins')),
      body: _loading
          ? const LoadingIndicator()
          : _admins.isEmpty
          ? const EmptyStateWidget(message: 'No admins found')
          : ListView.builder(
        itemCount: _admins.length,
        itemBuilder: (context, index) {
          final admin = _admins[index];
          final data = admin.data() as Map<String, dynamic>;
          final isActive = data['isActive'] ?? true;

          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            color: isActive ? null : Colors.grey[200],
            child: ListTile(
              leading: Icon(
                Icons.admin_panel_settings,
                color: isActive ? Colors.blue : Colors.grey,
              ),
              title: Text(data['name'] ?? 'Unknown'),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(data['email'] ?? 'No email'),
                  Text(data['mobileNumber'] ?? 'No mobile'),
                  if (!isActive)
                    Text('Inactive', style: TextStyle(color: Colors.red)),
                ],
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isActive) ...[
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      onPressed: () => _editAdmin(admin.id, data),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _deleteAdmin(admin.id, data['name']),
                    ),
                  ] else ...[
                    IconButton(
                      icon: const Icon(Icons.restore, color: Colors.green),
                      onPressed: () => _reactivateAdmin(admin.id),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _editAdmin(String adminId, Map<String, dynamic> data) {
    // Implement edit admin functionality
    _showError('Edit functionality coming soon');
  }

  Future<void> _reactivateAdmin(String adminId) async {
    try {
      await AdminService.reactivateAdmin(adminId);
      _showSuccess('Admin reactivated successfully');
      _loadAdmins();
    } catch (e) {
      _showError('Failed to reactivate admin: $e');
    }
  }
}