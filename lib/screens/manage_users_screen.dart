import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:leadassist/core/config.dart';
import 'package:leadassist/screens/add_user_screen.dart';
import 'package:leadassist/screens/manage_enquiries_screen.dart';
import '../services/user_service.dart';
import '../shared/widgets/loading_indicator.dart';
import '../shared/widgets/empty_state.dart';
import 'edit_user_screen.dart';

class ManageUsersScreen extends StatefulWidget {
  final String organizationId;
  final String userRole;

  const ManageUsersScreen({
    super.key,
    required this.organizationId,
    required this.userRole,
  });

  @override
  State<ManageUsersScreen> createState() => _ManageUsersScreenState();
}

class _ManageUsersScreenState extends State<ManageUsersScreen> {
  List<QueryDocumentSnapshot> _users = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    try {
      final users = await UserService.getUsersByOrganizationAndRole(
        widget.organizationId,
        widget.userRole,
      );
      setState(() {
        _users = users;
        _loading = false;
      });
    } catch (e) {
      _showError('Failed to load users: $e');
      setState(() => _loading = false);
    }
  }

  Future<void> _deleteUser(String userId, String userName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete User'),
        content: Text('Are you sure you want to delete $userName?'),
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
        await UserService.updateUserStatus(userId, false);
        _showSuccess('User deleted successfully');
        _loadUsers();
      } catch (e) {
        _showError('Failed to delete user: $e');
      }
    }
  }

  Future<void> _reactivateUser(String userId) async {
    try {
      await UserService.reactivateUser(userId);
      _showSuccess('User reactivated successfully');
      _loadUsers();
    } catch (e) {
      _showError('Failed to reactivate user: $e');
    }
  }

  void _showUserStats(QueryDocumentSnapshot user) {
    final data = user.data() as Map<String, dynamic>;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${data['name']} - Performance'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.userRole == 'salesman') ...[
              Text('Total Enquiries: ${data['totalEnquiries'] ?? 0}'),
              Text('Completed: ${data['completedEnquiries'] ?? 0}'),
              Text('Pending: ${data['pendingEnquiries'] ?? 0}'),
              const SizedBox(height: 8),
            ],
            Text('Region: ${data['region'] ?? 'Not assigned'}'),
            Text(
              'Status: ${(data['isActive'] ?? true) ? 'Active' : 'Inactive'}',
            ),
            Text('Role: ${data['role'] ?? 'Unknown'}'),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Manage ${_getRoleDisplayName()}s'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadUsers),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddUserScreen(
                organizationId: widget.organizationId,
                userRole: widget.userRole,
              ),
            ),
          );
        },
        icon: Icon(Icons.add),
        label: Text("Add ${widget.userRole}"),
      ),
      body: _loading
          ? const LoadingIndicator()
          : _users.isEmpty
          ? EmptyStateWidget(
              message: 'No ${_getRoleDisplayName().toLowerCase()}s found',
            )
          : ListView.builder(
              itemCount: _users.length,
              itemBuilder: (context, index) {
                final user = _users[index];
                final data = user.data() as Map<String, dynamic>;
                final isActive = data['isActive'] ?? true;

                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  color: isActive ? null : Colors.grey[200],
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      children: [
                        Icon(
                          widget.userRole == 'admin'
                              ? Icons.admin_panel_settings
                              : Icons.person,
                          color: isActive ? Colors.blue : Colors.grey,
                          size: 40,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                data['name'] ?? 'Unknown User',
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
                              if (widget.userRole == 'salesman')
                                Text(
                                  'Region: ${data['region'] ?? 'Not assigned'}',
                                  style: const TextStyle(fontSize: 12),
                                ),
                              const SizedBox(height: 4),
                              if (widget.userRole == 'salesman')
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 4,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
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
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
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
                                  style: TextStyle(
                                    color: Colors.red,
                                    fontSize: 12,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert, size: 20),
                          onSelected: (value) {
                            switch (value) {
                              case 'enquiries':
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ManageEnquiriesScreen(organizationId: widget.organizationId,salesmanId: _users[index].id,),
                                  ),
                                );
                                break;
                              case 'stats':
                                _showUserStats(user);
                                break;
                              case 'edit':
                                _editUser(user.id, data);
                                break;
                              case 'delete':
                                _deleteUser(user.id, data['name']);
                                break;
                              case 'reactivate':
                                _reactivateUser(user.id);
                                break;
                            }
                          },
                          itemBuilder: (context) => isActive
                              ? [
                                  if(widget.userRole == AppConfig.salesmanRole)
                                    const PopupMenuItem(
                                      value: 'enquiries',
                                      child: Row(
                                        children: [
                                          Icon(Icons.analytics, size: 18),
                                          SizedBox(width: 8),
                                          Text('View Enquiries'),
                                        ],
                                      ),
                                    ),
                                  if (widget.userRole == AppConfig.salesmanRole)
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
                                        Icon(
                                          Icons.delete,
                                          size: 18,
                                          color: Colors.red,
                                        ),
                                        SizedBox(width: 8),
                                        Text(
                                          'Delete',
                                          style: TextStyle(color: Colors.red),
                                        ),
                                      ],
                                    ),
                                  ),
                                ]
                              : [
                                  if (widget.userRole == AppConfig.salesmanRole)
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
                                        Icon(
                                          Icons.restore,
                                          size: 18,
                                          color: Colors.green,
                                        ),
                                        SizedBox(width: 8),
                                        Text(
                                          'Reactivate',
                                          style: TextStyle(color: Colors.green),
                                        ),
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

  void _editUser(String userId, Map<String, dynamic> data) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditUserScreen(
          userId: userId,
          organizationId: widget.organizationId,
        ),
      ),
    ).then((_) {
      _loadUsers();
    });
  }
}
