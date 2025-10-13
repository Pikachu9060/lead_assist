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
import 'add_customer_screen.dart';
import 'add_enquiry_screen.dart';
import 'manage_users_screen.dart';
import 'manage_customers_screen.dart';
import 'manage_enquiries_screen.dart';

class AdminDashboard extends StatefulWidget {
  final String organizationId;

  const AdminDashboard({super.key, required this.organizationId});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  Map<String, dynamic>? _currentUserData;

  @override
  void initState() {
    super.initState();
    _loadCurrentUserData();
  }

  Future<String?> _loadOrganizationName()async{
    final orgDoc = await FirebaseFirestore.instance.collection(AppConfig.organizationsCollection).doc(widget.organizationId).get();
      if(orgDoc.exists){
        final orgData = orgDoc.data() as Map<String, dynamic>;
        return orgData["name"];
      }
      return null;
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
    try {
      await FCMService.removeCurrentDevice();
      await AuthService.logout();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Logout failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: FutureBuilder(future: _loadOrganizationName(), builder: (context, snapshot){
          if(snapshot.hasData){
            return Text(snapshot.data ?? "Organization", style: TextStyle(fontWeight: FontWeight.bold),);
          }
          return Text("Organization");
        }),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _logout(context),
          ),
        ],
      ),
      drawer: _buildDrawer(),
      body: _DashboardContent(organizationId: widget.organizationId, userData: _currentUserData ?? {}),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      width: 280, // Fixed width for consistency
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.blue.shade50,
              Colors.grey.shade50,
            ],
          ),
        ),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            // Enhanced Header
            Container(
              height: 180,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.blue.shade800,
                    Colors.blue.shade600,
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.shade300.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Background pattern
                  Positioned(
                    right: -20,
                    top: -20,
                    child: Icon(
                      Icons.admin_panel_settings,
                      size: 120,
                      color: Colors.white.withOpacity(0.1),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withOpacity(0.3),
                              width: 2,
                            ),
                          ),
                          child: Icon(
                            Icons.admin_panel_settings,
                            size: 32,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Admin Panel',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          FirebaseAuth.instance.currentUser?.email ?? 'Admin User',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 14,
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
            _buildDrawerSection(
              title: 'MANAGEMENT',
              icon: Icons.manage_accounts,
              children: [
                if(_currentUserData != null && _currentUserData!["role"] == AppConfig.ownerRole) _buildDrawerItem(
                  icon: Icons.admin_panel_settings,
                  title: 'Managers',
                  subtitle: 'Manage team leaders',
                  badgeCount: 0,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ManageUsersScreen(
                          organizationId: widget.organizationId,
                          userRole: AppConfig.managerRole,
                        ),
                      ),
                    );
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.people_alt,
                  title: 'Sales Team',
                  subtitle: 'Field executives',
                  badgeCount: 0,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ManageUsersScreen(
                          organizationId: widget.organizationId,
                          userRole: AppConfig.salesmanRole,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),

            _buildDrawerSection(
              title: 'CUSTOMERS',
              icon: Icons.group,
              children: [
                _buildDrawerItem(
                  icon: Icons.people_outline,
                  title: 'All Customers',
                  subtitle: 'View client list',
                  badgeCount: 0,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ManageCustomersScreen(organizationId: widget.organizationId),
                      ),
                    );
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.person_add_alt_1,
                  title: 'Add Customer',
                  subtitle: 'New client registration',
                  badgeCount: 0,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AddCustomerScreen(organizationId: widget.organizationId),
                      ),
                    );
                  },
                ),
              ],
            ),

            _buildDrawerSection(
              title: 'ENQUIRIES',
              icon: Icons.inbox,
              children: [
                _buildDrawerItem(
                  icon: Icons.list_alt,
                  title: 'All Enquiries',
                  subtitle: 'Manage leads',
                  badgeCount: 0,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ManageEnquiriesScreen(organizationId: widget.organizationId),
                      ),
                    );
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.add_comment,
                  title: 'New Enquiry',
                  subtitle: 'Create lead',
                  badgeCount: 0,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AddEnquiryScreen(organizationId: widget.organizationId),
                      ),
                    );
                  },
                ),
              ],
            ),

            // Quick Actions Section
            _buildDrawerSection(
              title: 'QUICK ACTIONS',
              icon: Icons.flash_on,
              children: [
                _buildDrawerItem(
                  icon: Icons.analytics,
                  title: 'Statistics',
                  subtitle: 'View insights',
                  badgeCount: 0,
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
                  subtitle: 'App configuration',
                  badgeCount: 0,
                  onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Settings feature coming soon!')),
                    );
                  },
                ),
              ],
            ),

            // Footer
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.blue.shade100,
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.help_outline,
                      size: 24,
                      color: Colors.blue.shade600,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Need Help?',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue.shade700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Contact support team',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue.shade600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
          child: Row(
            children: [
              Icon(
                icon,
                size: 18,
                color: Colors.blue.shade600,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.blue.shade700,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
        ...children,
      ],
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required int badgeCount,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.7),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.grey.shade200,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    size: 20,
                    color: Colors.blue.shade700,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
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
                if (badgeCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.red.shade500,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      badgeCount.toString(),
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                const SizedBox(width: 4),
                Icon(
                  Icons.chevron_right,
                  size: 18,
                  color: Colors.grey.shade400,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DashboardContent extends StatefulWidget {
  final String organizationId;
  final Map<String, dynamic> userData;

  const _DashboardContent({required this.organizationId, required this.userData});

  @override
  State<_DashboardContent> createState() => _DashboardContentState();
}

class _DashboardContentState extends State<_DashboardContent> {
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
            child: FutureBuilder<Map<String, dynamic>>(
              future: _getDashboardStats(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const LoadingIndicator();
                }

                final stats = snapshot.data ?? {};
                final adminCount = stats['adminCount'] ?? 0;
                final salesmanCount = stats['salesmanCount'] ?? 0;
                final customerCount = stats['customerCount'] ?? 0;
                final enquiryCount = stats['enquiryCount'] ?? 0;

                return GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.3,
                  children: [
                    if(widget.userData["role"] == AppConfig.ownerRole)  _buildStatCard(
                      title: 'Managers',
                      count: adminCount,
                      subtitle: 'Team Leaders',
                      color: Colors.blue,
                      icon: Icons.admin_panel_settings,
                    ),
                    _buildStatCard(
                      title: 'Sales Team',
                      count: salesmanCount,
                      subtitle: 'Field Executives',
                      color: Colors.green,
                      icon: Icons.people_alt,
                    ),
                    _buildStatCard(
                      title: 'Customers',
                      count: customerCount,
                      subtitle: 'Total Clients',
                      color: Colors.orange,
                      icon: Icons.person,
                    ),
                    _buildStatCard(
                      title: 'Enquiries',
                      count: enquiryCount,
                      subtitle: 'Active Leads',
                      color: Colors.purple,
                      icon: Icons.inbox,
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<Map<String, dynamic>> _getDashboardStats() async {
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

      return {
        'adminCount': adminCount,
        'salesmanCount': salesmanCount,
        'customerCount': customerCount,
        'enquiryCount': enquiryCount,
      };
    } catch (e) {
      print('Error loading stats: $e');
      return {};
    }
  }

  Widget _buildStatCard({
    required String title,
    required int count,
    required String subtitle,
    required Color color,
    required IconData icon,
  }) {
    return Card(
      elevation: 4,
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
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, size: 24, color: color),
                  ),
                  const Spacer(),
                  Text(
                    count.toString(),
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ),
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