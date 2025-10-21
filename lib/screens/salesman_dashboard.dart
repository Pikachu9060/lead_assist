import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../cached_services/cached_enquiry_service.dart';
import '../cached_services/cached_data_service.dart';
import '../cached_services/cached_user_service.dart';
import '../cached_services/cached_user_notification_service.dart';
import '../models/enquiry_model.dart';
import '../shared/widgets/loading_indicator.dart';
import '../shared/widgets/error_widget.dart';
import 'manage_enquiries_screen.dart';
import 'notifications_screen.dart';

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
  bool _isHiveInitialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeHive();
    });
  }

  Future<void> _initializeHive() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await CachedDataService.initializeForUser(
        userId: user.uid,
        userRole: 'salesman',
        organizationId: widget.organizationId,
      );
      // Initialize notifications stream
      await CachedUserNotificationService.initializeUserNotificationsStream();
      setState(() {
        _isHiveInitialized = true;
      });
    }
  }

  void _logout(BuildContext context) async {
    try {
      await CachedDataService.logout();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Logout failed: $e')),
      );
    }
  }

  void _navigateToNotifications(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NotificationsScreen(
          organizationId: widget.organizationId
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final userId = user?.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Salesman Dashboard',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          // Notification Icon with Badge
          StreamBuilder<int>(
            stream: CachedUserNotificationService.watchUnreadCount(),
            builder: (context, snapshot) {
              final unreadCount = snapshot.data ?? 0;

              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications),
                    onPressed: () => _navigateToNotifications(context),
                    tooltip: 'Notifications',
                  ),
                  if (unreadCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          unreadCount > 99 ? '99+' : unreadCount.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _logout(context),
            tooltip: 'Logout',
          ),
        ],
      ),
      body: userId == null || !_isHiveInitialized
          ? const LoadingIndicator()
          : FutureBuilder<Map<String, dynamic>?>(
        future: CachedUserService.getDashboardUserData(userId),
        builder: (context, userSnapshot) {
          if (userSnapshot.connectionState == ConnectionState.waiting) {
            return const LoadingIndicator();
          }

          final userData = userSnapshot.data;
          final userName = userData?['name'] ?? 'Salesman';
          final userRegion = userData?['region'] ?? 'No region assigned';

          return Column(
            children: [
              // Notification Count Card below AppBar
              Expanded(
                child: _DashboardContent(
                  organizationId: widget.organizationId,
                  salesmanId: userId,
                  userName: userName,
                  userEmail: user?.email,
                  userRegion: userRegion,
                  selectedStatuses: _selectedStatuses,
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
  final Function(List<String>) onStatusFilterChanged;

  const _DashboardContent({
    required this.organizationId,
    required this.salesmanId,
    required this.userName,
    this.userEmail,
    required this.userRegion,
    required this.selectedStatuses,
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

          const Text(
            'My Performance',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          _SalesmanStats(
            salesmanId: salesmanId,
            organizationId: organizationId,
            onStatusTap: (String status) => _navigateToManageEnquiriesWithFilter(context, status),
          ),
        ],
      ),
    );
  }

  void _navigateToManageEnquiriesWithFilter(BuildContext context, String status) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ManageEnquiriesScreen(
          organizationId: organizationId,
          salesmanId: salesmanId,
          initialStatus: status,
        ),
      ),
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
  final Function(String status)? onStatusTap;

  const _SalesmanStats({
    required this.salesmanId,
    required this.organizationId,
    this.onStatusTap,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<EnquiryModel>>(
      stream: CachedEnquiryService.watchEnquiriesForSalesman(organizationId, salesmanId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingIndicator();
        }

        if (snapshot.hasError) {
          return const CustomErrorWidget(message: 'Failed to load enquiries');
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildEmptyStats(context);
        }

        final enquiries = snapshot.data!;
        final totalEnquiries = enquiries.length;
        final completedEnquiries = enquiries.where((enquiry) => enquiry.status == 'completed').length;
        final pendingEnquiries = enquiries.where((enquiry) => enquiry.status == 'pending').length;
        final inProgressEnquiries = enquiries.where((enquiry) => enquiry.status == 'in_progress').length;
        final cancelledEnquiries = enquiries.where((enquiry) => enquiry.status == 'cancelled').length;

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 2,
                child: _buildStatCard(
                  title: 'Total',
                  count: totalEnquiries,
                  color: Colors.purpleAccent,
                  icon: Icons.assignment,
                  onTap: () => _handleCardTap(context, 'all'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 3,
                child: Column(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              title: 'Pending',
                              count: pendingEnquiries,
                              color: Colors.blue,
                              icon: Icons.pending,
                              onTap: () => _handleCardTap(context, 'pending'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildStatCard(
                              title: 'In Progress',
                              count: inProgressEnquiries,
                              color: Colors.orange,
                              icon: Icons.autorenew,
                              onTap: () => _handleCardTap(context, 'in_progress'),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              title: 'Completed',
                              count: completedEnquiries,
                              color: Colors.green,
                              icon: Icons.check_circle,
                              onTap: () => _handleCardTap(context, 'completed'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildStatCard(
                              title: 'Cancelled',
                              count: cancelledEnquiries,
                              color: Colors.red,
                              icon: Icons.cancel,
                              onTap: () => _handleCardTap(context, 'cancelled'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyStats(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 2,
            child: _buildStatCard(
              title: 'Total',
              count: 0,
              color: Colors.purpleAccent,
              icon: Icons.assignment,
              onTap: () => _handleCardTap(context, 'all'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 3,
            child: Column(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          title: 'Pending',
                          count: 0,
                          color: Colors.blue,
                          icon: Icons.pending,
                          onTap: () => _handleCardTap(context, 'pending'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildStatCard(
                          title: 'In Progress',
                          count: 0,
                          color: Colors.orange,
                          icon: Icons.autorenew,
                          onTap: () => _handleCardTap(context, 'in_progress'),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          title: 'Completed',
                          count: 0,
                          color: Colors.green,
                          icon: Icons.check_circle,
                          onTap: () => _handleCardTap(context, 'completed'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildStatCard(
                          title: 'Cancelled',
                          count: 0,
                          color: Colors.red,
                          icon: Icons.cancel,
                          onTap: () => _handleCardTap(context, 'cancelled'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _handleCardTap(BuildContext context, String status) {
    if (onStatusTap != null) {
      onStatusTap!(status);
    }
  }

  Widget _buildStatCard({
    required String title,
    required int count,
    required Color color,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Card(
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
              mainAxisAlignment: MainAxisAlignment.center,
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
                const SizedBox(height: 4),
                Icon(Icons.arrow_circle_right_outlined, color: color)
              ],
            ),
          ),
        ),
      ),
    );
  }
}