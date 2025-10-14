import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/customer_service.dart';
import '../services/enquiry_service.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import '../shared/widgets/loading_indicator.dart';
import '../shared/widgets/empty_state.dart';
import '../shared/widgets/error_widget.dart';
import 'enquiry_detail_screen.dart';
import '../core/config.dart';

class SalesmanDashboard extends StatefulWidget {
  final String organizationId;

  const SalesmanDashboard({
    super.key,
    required this.organizationId
  });

  @override
  State<SalesmanDashboard> createState() => _SalesmanDashboardState();
}

class _SalesmanDashboardState extends State<SalesmanDashboard> {
  final List<String> _selectedStatuses = ['all'];
  bool _showFilters = true;

  Future<String?> _loadOrganizationName() async {
    final orgDoc = await FirebaseFirestore.instance
        .collection(AppConfig.organizationsCollection)
        .doc(widget.organizationId)
        .get();
    if (orgDoc.exists) {
      final orgData = orgDoc.data() as Map<String, dynamic>;
      return orgData["name"];
    }
    return null;
  }

  void _logout(BuildContext context) async {
    try {
      await AuthService.logout();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Logout failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final userId = user?.uid;

    return Scaffold(
      appBar: AppBar(
        title: FutureBuilder(
          future: _loadOrganizationName(),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return Text(
                snapshot.data ?? "Organization",
                style: const TextStyle(fontWeight: FontWeight.bold),
              );
            }
            return const Text("Organization");
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              setState(() {
                _showFilters = !_showFilters;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _logout(context),
            tooltip: 'Logout',
          ),
        ],
      ),
      body: userId == null
          ? const CustomErrorWidget(message: 'User not authenticated')
          : FutureBuilder<Map<String, dynamic>?>(
        future: UserService.getUser(userId),
        builder: (context, userSnapshot) {
          if (userSnapshot.connectionState == ConnectionState.waiting) {
            return const LoadingIndicator();
          }

          final userData = userSnapshot.data;
          final userName = userData?['name'] ?? 'Salesman';
          final userRegion = userData?['region'] ?? 'No region assigned';

          return Column(
            children: [
              Expanded(
                child: _DashboardContent(
                  organizationId: widget.organizationId,
                  salesmanId: userId,
                  userName: userName,
                  userEmail: user?.email,
                  userRegion: userRegion,
                  selectedStatuses: _selectedStatuses,
                  showFilters: _showFilters,
                  onStatusFilterChanged: (List<String> newStatuses) {
                    setState(() {
                      _selectedStatuses.clear();
                      _selectedStatuses.addAll(newStatuses);
                    });
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _DashboardContent extends StatelessWidget {
  final String organizationId;
  final String salesmanId;
  final String userName;
  final String? userEmail;
  final String userRegion;
  final List<String> selectedStatuses;
  final bool showFilters;
  final Function(List<String>) onStatusFilterChanged;

  const _DashboardContent({
    required this.organizationId,
    required this.salesmanId,
    required this.userName,
    this.userEmail,
    required this.userRegion,
    required this.selectedStatuses,
    required this.showFilters,
    required this.onStatusFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _WelcomeHeader(
            userName: userName,
            userEmail: userEmail,
            userRegion: userRegion,
          ),
          const SizedBox(height: 24),

          // Stats Section - Always shows all enquiries (no filtering)
          const Text(
            'My Performance',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          // Stats Cards - Always shows all enquiries
          _SalesmanStats(
            salesmanId: salesmanId,
            organizationId: organizationId,
          ),
          const SizedBox(height: 24),

          const Text(
            'My Assigned Enquiries',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          // Filter Section - Only status filter
          if (showFilters) _buildFilterSection(context),
          const SizedBox(height: 16),

          Expanded(
            child: _EnquiriesList(
              key: ValueKey('enquiries_${selectedStatuses.join('_')}'),
              salesmanId: salesmanId,
              organizationId: organizationId,
              selectedStatuses: selectedStatuses,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Status Filters - Clickable Text (Only filter option)
            Row(
              children: [
                GestureDetector(
                  onTap: () => _showStatusSelectionDialog(context),
                  child: const Row(
                    children: [
                      Text(
                        'Filter by Status',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(Icons.arrow_drop_down, size: 16, color: Colors.blue),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Show current selected statuses
                Text(
                  _getCurrentStatusText(),
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getCurrentStatusText() {
    if (selectedStatuses.contains('all') || selectedStatuses.length == 4) {
      return 'All Statuses';
    } else {
      return selectedStatuses.map((status) => status.replaceAll('_', ' ')).join(', ');
    }
  }

  void _showStatusSelectionDialog(BuildContext context) {
    List<String> tempSelectedStatuses = List.from(selectedStatuses);
    final List<String> allStatuses = ['all', 'pending', 'in_progress', 'completed', 'cancelled'];

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Select Statuses'),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: allStatuses.map((status) {
                    final isSelected = tempSelectedStatuses.contains(status);
                    return CheckboxListTile(
                      title: Text(
                        status == 'all'
                            ? 'All Statuses'
                            : status.replaceAll('_', ' ').toUpperCase(),
                      ),
                      value: isSelected,
                      onChanged: (bool? value) {
                        setStateDialog(() {
                          if (status == 'all') {
                            tempSelectedStatuses.clear();
                            if (value == true) {
                              tempSelectedStatuses.add('all');
                            }
                          } else {
                            tempSelectedStatuses.remove('all');
                            if (value == true) {
                              tempSelectedStatuses.add(status);
                            } else {
                              tempSelectedStatuses.remove(status);
                            }

                            if (tempSelectedStatuses.isEmpty) {
                              tempSelectedStatuses.add('all');
                            }
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    onStatusFilterChanged(tempSelectedStatuses);
                    Navigator.pop(context);
                  },
                  child: const Text('Apply'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _WelcomeHeader extends StatelessWidget {
  final String userName;
  final String? userEmail;
  final String userRegion;

  const _WelcomeHeader({
    required this.userName,
    this.userEmail,
    required this.userRegion,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.green.shade100,
              radius: 30,
              child: const Icon(Icons.person, color: Colors.green),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome, $userName',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    userEmail ?? 'Salesman User',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Region: $userRegion',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.blue.shade600,
                      fontWeight: FontWeight.w500,
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

class _SalesmanStats extends StatelessWidget {
  final String salesmanId;
  final String organizationId;

  const _SalesmanStats({
    required this.salesmanId,
    required this.organizationId,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: EnquiryService.getEnquiriesForSalesman(organizationId, salesmanId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingIndicator();
        }

        if (!snapshot.hasData) {
          return const SizedBox();
        }

        final enquiries = snapshot.data!.docs;
        final totalEnquiries = enquiries.length;
        final completedEnquiries = enquiries.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return data['status'] == 'completed';
        }).length;
        final pendingEnquiries = enquiries.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return data['status'] == 'pending' || data['status'] == 'in_progress';
        }).length;

        return Row(
          children: [
            Expanded(
              child: _buildStatCard(
                title: 'Total',
                count: totalEnquiries,
                color: Colors.blue,
                icon: Icons.assignment,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                title: 'Completed',
                count: completedEnquiries,
                color: Colors.green,
                icon: Icons.check_circle,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                title: 'Pending',
                count: pendingEnquiries,
                color: Colors.orange,
                icon: Icons.pending,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard({
    required String title,
    required int count,
    required Color color,
    required IconData icon,
  }) {
    return Card(
      elevation: 3,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withOpacity(0.1),
              color.withOpacity(0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 20, color: color),
              ),
              const SizedBox(height: 8),
              Text(
                count.toString(),
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EnquiriesList extends StatefulWidget {
  final String salesmanId;
  final String organizationId;
  final List<String> selectedStatuses;

  const _EnquiriesList({
    required this.salesmanId,
    required this.organizationId,
    required this.selectedStatuses,
    super.key,
  });

  @override
  State<_EnquiriesList> createState() => __EnquiriesListState();
}

class __EnquiriesListState extends State<_EnquiriesList> {
  late Stream<QuerySnapshot> _enquiriesStream;

  @override
  void initState() {
    super.initState();
    _updateStream();
  }

  @override
  void didUpdateWidget(_EnquiriesList oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Only update the stream if the status filter actually changed
    if (oldWidget.selectedStatuses.join() != widget.selectedStatuses.join()) {
      _updateStream();
    }
  }

  void _updateStream() {
    final effectiveStatuses = widget.selectedStatuses.contains('all')
        ? ['pending', 'in_progress', 'completed', 'cancelled']
        : widget.selectedStatuses;

    _enquiriesStream = EnquiryService.searchEnquiries(
      searchType: 'customer',
      query: '',
      statuses: effectiveStatuses,
      organizationId: widget.organizationId,
      salesmanId: widget.salesmanId,
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _enquiriesStream,
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
            message: 'No enquiries assigned to you yet',
            icon: Icons.assignment,
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
              onTap: () => _navigateToEnquiryDetail(context, enquiry.id, data, widget.organizationId),
            );
          },
        );
      },
    );
  }

  void _navigateToEnquiryDetail(BuildContext context, String enquiryId, Map<String, dynamic> data, String organizationId) async{
    final userData = await CustomerService.getCustomerById(organizationId, data["customerId"]);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EnquiryDetailScreen(
          userData: userData.data() as Map<String, dynamic>,
          enquiryId: enquiryId,
          enquiryData: data,
          organizationId: organizationId,
          isSalesman: true,
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
      elevation: 2,
      child: ListTile(
        leading: _buildStatusIcon(data['status']),
        title: Text(
          data['customerName'] ?? 'Unknown Customer',
          style: const TextStyle(fontWeight: FontWeight.bold),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              data['product'] ?? 'No product specified',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: _getStatusColor(data['status']).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _getStatusColor(data['status']).withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    _formatStatus(data['status']),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: _getStatusColor(data['status']),
                    ),
                  ),
                ),
                const Spacer(),
                if (data['createdAt'] != null)
                  Text(
                    _formatDate(data['createdAt']),
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 10,
                    ),
                  ),
              ],
            ),
          ],
        ),
        trailing: Icon(
          Icons.chevron_right,
          color: Colors.grey.shade400,
        ),
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }

  Widget _buildStatusIcon(String status) {
    IconData icon;
    Color color = _getStatusColor(status);

    switch (status) {
      case 'completed':
        icon = Icons.check_circle;
        break;
      case 'in_progress':
        icon = Icons.refresh;
        break;
      case 'cancelled':
        icon = Icons.cancel;
        break;
      default:
        icon = Icons.pending;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'completed':
        return Colors.green;
      case 'in_progress':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      case 'pending':
        return Colors.orange;
      default:
        return Colors.black;
    }
  }

  String _formatStatus(String status) {
    switch (status) {
      case 'in_progress':
        return 'In Progress';
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      default:
        return 'Pending';
    }
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