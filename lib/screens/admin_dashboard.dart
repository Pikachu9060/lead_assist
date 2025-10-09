import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:leadassist/services/fcm_service.dart';
import '../services/enquiry_service.dart';
import '../services/auth_service.dart';
import '../shared/widgets/loading_indicator.dart';
import '../shared/widgets/empty_state.dart';
import '../shared/widgets/error_widget.dart';
import 'add_customer_screen.dart';
import 'add_enquiry_screen.dart';
import 'add_salesman_screen.dart';
import 'create_admin_screen.dart';
import 'enquiry_detail_screen.dart';
import 'manage_admins_screen.dart';
import 'manage_customers_screen.dart';
import 'manage_salesmen_screen.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  void _toggleExpansion() {
    setState(() {
      _isExpanded = !_isExpanded;
    });

    if (_isExpanded) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: // Add these to the AppBar actions or create a drawer:
      AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'manage_admins':
                  Navigator.push(context, MaterialPageRoute(
                      builder: (context) => const ManageAdminsScreen()));
                  break;
                case 'manage_salesmen':
                  Navigator.push(context, MaterialPageRoute(
                      builder: (context) => const ManageSalesmenScreen()));
                  break;
                case 'manage_customers':
                  Navigator.push(context, MaterialPageRoute(
                      builder: (context) => const ManageCustomersScreen()));
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'manage_admins', child: Text('Manage Admins')),
              const PopupMenuItem(value: 'manage_salesmen', child: Text('Manage Salesmen')),
              const PopupMenuItem(value: 'manage_customers', child: Text('Manage Customers')),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: const _DashboardContent(),
      floatingActionButton: _buildExpandableFab(),
    );
  }

  Widget _buildExpandableFab() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Add Enquiry
        ScaleTransition(
          scale: _animationController,
          child: FadeTransition(
            opacity: _animationController,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: _buildSubFab(
                icon: Icons.add_comment,
                label: 'Add Enquiry',
                onTap: () => _navigateToAddEnquiry(context),
              ),
            ),
          ),
        ),

        // Add Salesman
        ScaleTransition(
          scale: _animationController,
          child: FadeTransition(
            opacity: _animationController,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: _buildSubFab(
                icon: Icons.person_add_alt,
                label: 'Add Salesman',
                onTap: () => _navigateToAddSalesman(context),
              ),
            ),
          ),
        ),

        // Add Admin
        ScaleTransition(
          scale: _animationController,
          child: FadeTransition(
            opacity: _animationController,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: _buildSubFab(
                icon: Icons.admin_panel_settings,
                label: 'Add Admin',
                onTap: () => _navigateToCreateAdmin(context),
              ),
            ),
          ),
        ),

        // Add Customer
        ScaleTransition(
          scale: _animationController,
          child: FadeTransition(
            opacity: _animationController,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: _buildSubFab(
                icon: Icons.person_add,
                label: 'Add Customer',
                onTap: () => _navigateToAddCustomer(context),
              ),
            ),
          ),
        ),

        // Main FAB
        FloatingActionButton(
          heroTag: 'main_fab',
          onPressed: _toggleExpansion,
          child: AnimatedIcon(
            icon: AnimatedIcons.menu_close,
            progress: _animationController,
          ),
        ),
      ],
    );
  }

  Widget _buildSubFab({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      elevation: 4.0,
      borderRadius: BorderRadius.circular(25.0),
      child: InkWell(
        borderRadius: BorderRadius.circular(25.0),
        onTap: onTap, // This makes it clickable
        child: Container(
          height: 40.0,
          padding: const EdgeInsets.symmetric(horizontal: 12.0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18.0),
              const SizedBox(width: 8.0),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14.0,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static void _logout(BuildContext context) async {
    try {
      // await FCMService.debugDeviceIdIssue();
      await FCMService.removeCurrentDevice();
      await AuthService.logout();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Logout failed: $e')),
      );
    }
  }

  void _navigateToAddCustomer(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddCustomerScreen()),
    ).then((_) {
      _toggleExpansion(); // Close FAB after navigation
    });
  }

  void _navigateToCreateAdmin(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CreateAdminScreen()),
    ).then((_) {
      _toggleExpansion(); // Close FAB after navigation
    });
  }

  void _navigateToAddSalesman(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddSalesmanScreen()),
    ).then((_) {
      _toggleExpansion(); // Close FAB after navigation
    });
  }

  void _navigateToAddEnquiry(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddEnquiryScreen()),
    ).then((_) {
      _toggleExpansion(); // Close FAB after navigation
    });
  }
}

// Rest of the AdminDashboard content remains the same...
class _DashboardContent extends StatefulWidget {
  const _DashboardContent();

  @override
  State<_DashboardContent> createState() => _DashboardContentState();
}

class _DashboardContentState extends State<_DashboardContent> {
  final List<String> _selectedStatuses = [];
  final List<String> _allStatuses = [
    'pending',
    'in_progress',
    'completed',
    'cancelled',
  ];

  String _searchType = 'customer';
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _WelcomeHeader(),
          const SizedBox(height: 24),
          const Text(
            'Recent Enquiries',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),

          // ✅ --- Search Controls Row ---
          Row(
            children: [
              // Search Type Dropdown
              DropdownButton<String>(
                value: _searchType,
                items: const [
                  DropdownMenuItem(value: 'customer', child: Text('Customer Name')),
                  DropdownMenuItem(value: 'salesman', child: Text('Salesman Name')),
                  DropdownMenuItem(value: 'enquiry', child: Text('Enquiry / Product')),
                ],
                onChanged: (value) {
                  setState(() {
                    _searchType = value!;
                  });
                },
              ),
              const SizedBox(width: 8),
              // Search Field
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search),
                    hintText: 'Search...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // ✅ --- STATUS FILTER CHECKBOXES ---
          Wrap(
            spacing: 8,
            children: _allStatuses.map((status) {
              final selected = _selectedStatuses.contains(status);
              return FilterChip(
                label: Text(
                  status.replaceAll('_', ' ').toUpperCase(),
                  style: TextStyle(
                    color: selected ? Colors.white : Colors.black,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                selected: selected,
                selectedColor: Colors.blue,
                onSelected: (bool value) {
                  setState(() {
                    if (value) {
                      _selectedStatuses.add(status);
                    } else {
                      _selectedStatuses.remove(status);
                    }
                  });
                },
              );
            }).toList(),
          ),

          const SizedBox(height: 16),

          // ✅ --- ENQUIRY LIST ---
          Expanded(
            child: _EnquiriesList(
              selectedStatuses: _selectedStatuses,
              searchType: _searchType,
              searchQuery: _searchQuery,
            ),
          ),
        ],
      ),
    );
  }
}


class _WelcomeHeader extends StatelessWidget {
  const _WelcomeHeader();

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            const Icon(Icons.admin_panel_settings, size: 40),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome, Admin',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  Text(
                    user?.email ?? 'Admin User',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EnquiriesList extends StatelessWidget {
  final List<String> selectedStatuses;
  final String searchType;
  final String searchQuery;

  const _EnquiriesList({
    required this.selectedStatuses,
    required this.searchType,
    required this.searchQuery,
  });

  @override
  Widget build(BuildContext context) {
    final stream = EnquiryService.searchEnquiries(
      searchType: searchType,
      query: searchQuery,
      statuses: selectedStatuses,
    );

    return StreamBuilder<QuerySnapshot>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingIndicator();
        }
        if (snapshot.hasError) {
          return CustomErrorWidget(
            message: 'Failed to load enquiries: ${snapshot.error}',
            onRetry: () {},
          );
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const EmptyStateWidget(
            message: 'No enquiries found',
            icon: Icons.search_off,
          );
        }

        final enquiries = snapshot.data!.docs;

        return ListView.separated(
          itemCount: enquiries.length,
          separatorBuilder: (context, index) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final enquiry = enquiries[index];
            final data = enquiry.data() as Map<String, dynamic>;

            return _EnquiryCard(
              enquiryId: enquiry.id,
              data: data,
              onTap: () => _navigateToEnquiryDetail(context, enquiry.id, data),
            );
          },
        );
      },
    );
  }

  void _navigateToEnquiryDetail(
      BuildContext context,
      String enquiryId,
      Map<String, dynamic> data,
      ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EnquiryDetailScreen(
          enquiryId: enquiryId,
          enquiryData: data,
          isSalesman: false,
        ),
      ),
    );
  }
}


class _EnquiryCard extends StatelessWidget {
  final String enquiryId;
  final Map<String, dynamic> data;
  final VoidCallback onTap;

  const _EnquiryCard({
    required this.enquiryId,
    required this.data,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: _buildStatusIcon(data['status']),
        title: Text(
          data['customerName'] ?? 'Unknown Customer',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(data['product'] ?? 'No product specified'),
            if (data['assignedSalesmanName'] != null)
              Text('Assigned to: ${data['assignedSalesmanName']}'),
            if (data['createdAt'] != null)
              Text(
                _formatDate(data['createdAt']),
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }

  Widget _buildStatusIcon(String status) {
    IconData icon;
    Color color;

    switch (status) {
      case 'completed':
        icon = Icons.check_circle;
        color = Colors.green;
        break;
      case 'in_progress':
        icon = Icons.refresh;
        color = Colors.orange;
        break;
      case 'cancelled':
        icon = Icons.cancel;
        color = Colors.red;
        break;
      default:
        icon = Icons.pending;
        color = Colors.blue;
    }

    return Icon(icon, color: color);
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'Unknown date';

    try {
      final date = timestamp.toDate();
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return 'Invalid date';
    }
  }
}