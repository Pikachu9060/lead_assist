import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:leadassist/services/fcm_service.dart';
import '../services/enquiry_service.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import '../services/customer_service.dart';
import '../core/config.dart';
import '../shared/widgets/loading_indicator.dart';
import '../shared/widgets/stat_card.dart';
import 'add_customer_screen.dart';
import 'add_enquiry_screen.dart';
import 'add_user_screen.dart';
import 'manage_users_screen.dart';
import 'manage_customers_screen.dart';
import 'manage_enquiries_screen.dart';

class AdminDashboard extends StatefulWidget {
  final String organizationId;

  const AdminDashboard({super.key, required this.organizationId});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> with SingleTickerProviderStateMixin {
  Map<String, dynamic>? _currentUserData;
  String? _organizationName;
  bool _isExpanded = false;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _loadCurrentUserData();
    _loadOrganizationName();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadOrganizationName() async {
    try {
      final orgDoc = await FirebaseFirestore.instance
          .collection(AppConfig.organizationsCollection)
          .doc(widget.organizationId)
          .get();

      if (orgDoc.exists) {
        final orgData = orgDoc.data() as Map<String, dynamic>;
        setState(() {
          _organizationName = orgData["name"];
        });
      } else {
        setState(() {
          _organizationName = "Organization";
        });
      }
    } catch (e) {
      print('Error loading organization name: $e');
      setState(() {
        _organizationName = "Organization";
      });
    }
  }

  Future<void> _loadCurrentUserData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userData = await UserService.getUser(user.uid);
        setState(() {
          _currentUserData = userData;
        });
      }
    } catch (e) {
      print('Error loading user data: $e');
    }
  }

  void _logout(BuildContext context) async {
    bool? shouldLogout = await _showLogoutConfirmationDialog(context);

    if (shouldLogout == true) {
      _showLogoutLoadingDialog(context);

      try {
        await FCMService.removeCurrentDevice();
        await AuthService.logout();

        // Close the loading dialog
        if (mounted) {
          Navigator.of(context, rootNavigator: true).pop();
        }
      } catch (e) {
        // Close the loading dialog
        if (mounted) {
          Navigator.of(context, rootNavigator: true).pop();
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Logout failed: $e')),
          );
        }
      }
    }
  }

  Future<bool?> _showLogoutConfirmationDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            ),
            TextButton(
              child: const Text('Logout'),
              onPressed: () {
                Navigator.of(context).pop(true);
              },
            ),
          ],
        );
      },
    );
  }

  void _showLogoutLoadingDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return PopScope(
          canPop: false,
          child: Dialog(
            backgroundColor: Colors.transparent,
            elevation: 0,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  LoadingIndicator(),
                  SizedBox(height: 16),
                  Text(
                    'Logging out...',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
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

  void _navigate(BuildContext context, Widget screen) {
    _toggleExpansion();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => screen,
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            _organizationName ?? "Organization",
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () => _logout(context),
            ),
          ],
        ),
        drawer: _buildDrawer(),
        body: _DashboardContent(
          organizationId: widget.organizationId,
          userData: _currentUserData ?? {},
        ),
        floatingActionButton: _buildExpandableFab(),
      ),
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
              child: GestureDetector(
                onTap: () => _navigate(context, AddEnquiryScreen(organizationId: widget.organizationId)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        'Add Enquiry',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.purple.shade700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FloatingActionButton.small(
                      heroTag: 'enquiry_fab',
                      onPressed: () => _navigate(context, AddEnquiryScreen(organizationId: widget.organizationId)),
                      backgroundColor: Colors.purple,
                      child: const Icon(Icons.add_comment, size: 18, color: Colors.white),
                    ),
                  ],
                ),
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
              child: GestureDetector(
                onTap: () => _navigate(context, AddUserScreen(organizationId: widget.organizationId, userRole: AppConfig.salesmanRole)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        'Add Salesman',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.green.shade700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FloatingActionButton.small(
                      heroTag: 'salesman_fab',
                      onPressed: () => _navigate(context, AddUserScreen(organizationId: widget.organizationId, userRole: AppConfig.salesmanRole)),
                      backgroundColor: Colors.green,
                      child: const Icon(Icons.person_add_alt, size: 18, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        // Add Admin/Manager
        if (_currentUserData != null && _currentUserData!["role"] == AppConfig.ownerRole)
          ScaleTransition(
            scale: _animationController,
            child: FadeTransition(
              opacity: _animationController,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: GestureDetector(
                  onTap: () => _navigate(context, AddUserScreen(organizationId: widget.organizationId, userRole: AppConfig.managerRole)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          'Add Manager',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      FloatingActionButton.small(
                        heroTag: 'admin_fab',
                        onPressed: () => _navigate(context, AddUserScreen(organizationId: widget.organizationId, userRole: AppConfig.managerRole)),
                        backgroundColor: Colors.blue,
                        child: const Icon(Icons.admin_panel_settings, size: 18, color: Colors.white),
                      ),
                    ],
                  ),
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
              child: GestureDetector(
                onTap: () => _navigate(context, AddCustomerScreen(organizationId: widget.organizationId)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        'Add Customer',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.orange.shade700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FloatingActionButton.small(
                      heroTag: 'customer_fab',
                      onPressed: () => _navigate(context, AddCustomerScreen(organizationId: widget.organizationId)),
                      backgroundColor: Colors.orange,
                      child: const Icon(Icons.person_add, size: 18, color: Colors.white),
                    ),
                  ],
                ),
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

  Widget _buildDrawer() {
    return Drawer(
      width: 280,
      child: Column(
        children: [
          // User Profile Section
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade300),
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.blue.shade100,
                  radius: 25,
                  child: Icon(
                    Icons.person,
                    color: Colors.blue.shade700,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _currentUserData?['name'] ?? 'Admin User',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        FirebaseAuth.instance.currentUser?.email ?? 'No email',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Navigation Sections
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                const Divider(height: 1),
                // Quick Actions Section
                _buildDrawerItem(
                  icon: Icons.analytics,
                  title: 'Statistics',
                  onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Statistics feature coming soon!')),
                    );
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.settings,
                  title: 'Settings',
                  onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Settings feature coming soon!')),
                    );
                  },
                ),
                const Divider(height: 1),
              ],
            ),
          ),
          // Logout Section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: Colors.grey.shade300),
              ),
            ),
            child: ListTile(
              leading: Icon(
                Icons.logout,
                color: Colors.red.shade600,
              ),
              title: Text(
                'Logout',
                style: TextStyle(
                  color: Colors.red.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              onTap: () => _logout(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        size: 20,
        color: Colors.grey.shade700,
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 13,
        ),
      ),
      dense: true,
      visualDensity: const VisualDensity(vertical: -3),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      onTap: onTap,
    );
  }
}

// Rest of your code remains the same (_DashboardContent, _WelcomeHeader classes)
class _DashboardContent extends StatefulWidget {
  final String organizationId;
  final Map<String, dynamic> userData;

  const _DashboardContent({required this.organizationId, required this.userData});

  @override
  State<_DashboardContent> createState() => _DashboardContentState();
}

class _DashboardContentState extends State<_DashboardContent> {
  Map<String, dynamic>? _dashboardStats;
  bool _isLoadingStats = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardStats();
  }

  Future<void> _loadDashboardStats() async {
    try {
      final userCounts = await UserService.getUserCountsByRole(widget.organizationId);
      final adminCount = userCounts[AppConfig.managerRole] ?? 0;
      final salesmanCount = userCounts[AppConfig.salesmanRole] ?? 0;

      // Get customer count
      final customers = await CustomerService.getAllCustomers(widget.organizationId);
      final customerCount = customers.length;

      // Get enquiry count
      final enquiries = await EnquiryService.getAllEnquiries(widget.organizationId).first;
      final enquiryCount = enquiries.docs.length;

      setState(() {
        _dashboardStats = {
          'adminCount': adminCount,
          'salesmanCount': salesmanCount,
          'customerCount': customerCount,
          'enquiryCount': enquiryCount,
        };
        _isLoadingStats = false;
      });
    } catch (e) {
      print('Error loading stats: $e');
      setState(() {
        _dashboardStats = {};
        _isLoadingStats = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _WelcomeHeader(organizationId: widget.organizationId),
          const SizedBox(height: 24),

          // Stats Section
          const Text(
            'Business Overview',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          // Stats Grid
          Expanded(
            child: _isLoadingStats
                ? const LoadingIndicator()
                : _buildStatsGrid(),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    final adminCount = _dashboardStats?['adminCount'] ?? 0;
    final salesmanCount = _dashboardStats?['salesmanCount'] ?? 0;
    final customerCount = _dashboardStats?['customerCount'] ?? 0;
    final enquiryCount = _dashboardStats?['enquiryCount'] ?? 0;

    List<Widget> statCards = [
      StatCard(
          title: 'Sales Team',
          count: salesmanCount,
          subtitle: 'Field Executives',
          color: Colors.green,
          icon: Icons.people_alt,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => ManageUsersScreen(organizationId: widget.organizationId, userRole: AppConfig.salesmanRole)),
            );
          }
      ),
      StatCard(
          title: 'Customers',
          count: customerCount,
          subtitle: 'Total Clients',
          color: Colors.orange,
          icon: Icons.person,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => ManageCustomersScreen(organizationId: widget.organizationId)),
            );
          }
      ),
      StatCard(
          title: 'Enquiries',
          count: enquiryCount,
          subtitle: 'Active Leads',
          color: Colors.purple,
          icon: Icons.inbox,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => ManageEnquiriesScreen(organizationId: widget.organizationId)),
            );
          }
      ),
    ];

    // Add Managers card only for owners
    if (widget.userData["role"] == AppConfig.ownerRole) {
      statCards.insert(0, StatCard(
          title: 'Managers',
          count: adminCount,
          subtitle: 'Team Leaders',
          color: Colors.blue,
          icon: Icons.admin_panel_settings,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => ManageUsersScreen(organizationId: widget.organizationId, userRole: AppConfig.managerRole)),
            );
          }
      ));
    }

    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.3,
      children: statCards,
    );
  }
}

class _WelcomeHeader extends StatelessWidget {
  final String organizationId;

  const _WelcomeHeader({required this.organizationId});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.blue.shade100,
              radius: 30,
              child: const Icon(Icons.admin_panel_settings, color: Colors.blue),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome, ${user!.displayName}',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if(user.email != null)Text(
                    user.email ?? 'Admin User',
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