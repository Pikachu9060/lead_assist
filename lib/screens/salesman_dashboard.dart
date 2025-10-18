import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/enquiry_service.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import '../shared/widgets/loading_indicator.dart';
import '../shared/widgets/error_widget.dart';
import 'manage_enquiries_screen.dart';
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
      child: ClipRect(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _WelcomeHeader(
              userName: userName,
              userEmail: userEmail,
              userRegion: userRegion,
            ),
            const SizedBox(height: 24),

            // Stats Section
            const Text(
              'My Performance',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Stats Cards - Clickable
            _SalesmanStats(
              salesmanId: salesmanId,
              organizationId: organizationId,
              onStatusTap: (String status) => _navigateToManageEnquiriesWithFilter(context, status),
            ),
            const SizedBox(height: 24),

            // Quick Actions
            // _buildQuickActions(context),
            // const SizedBox(height: 24),

            // Recent Enquiries
            // const Text(
            //   'Recent Enquiries',
            //   style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            // ),
            // const SizedBox(height: 16),
            //
            // Expanded(
            //   child: _EnquiriesList(
            //     salesmanId: salesmanId,
            //     organizationId: organizationId,
            //     selectedStatuses: selectedStatuses,
            //   ),
            // ),
          ],
        ),
      ),
    );
  }

  // Widget _buildQuickActions(BuildContext context) {
  //   return Card(
  //     child: Padding(
  //       padding: const EdgeInsets.all(16.0),
  //       child: Column(
  //         crossAxisAlignment: CrossAxisAlignment.start,
  //         children: [
  //           const Text(
  //             'Quick Actions',
  //             style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
  //           ),
  //           const SizedBox(height: 12),
  //           Row(
  //             children: [
  //               Expanded(
  //                 child: _buildActionButton(
  //                   icon: Icons.assignment,
  //                   label: 'All Enquiries',
  //                   onTap: () => _navigateToManageEnquiriesWithFilter(context, 'all'),
  //                 ),
  //               ),
  //               const SizedBox(width: 12),
  //               Expanded(
  //                 child: _buildActionButton(
  //                   icon: Icons.filter_list,
  //                   label: 'With Filters',
  //                   onTap: () => _navigateToManageEnquiries(context),
  //                 ),
  //               ),
  //             ],
  //           ),
  //         ],
  //       ),
  //     ),
  //   );
  // }

  // Widget _buildActionButton({
  //   required IconData icon,
  //   required String label,
  //   required VoidCallback onTap,
  // }) {
  //   return InkWell(
  //     onTap: onTap,
  //     child: Container(
  //       padding: const EdgeInsets.all(12),
  //       decoration: BoxDecoration(
  //         color: Colors.blue.shade50,
  //         borderRadius: BorderRadius.circular(8),
  //       ),
  //       child: Column(
  //         children: [
  //           Icon(icon, color: Colors.blue, size: 24),
  //           const SizedBox(height: 4),
  //           Text(
  //             label,
  //             textAlign: TextAlign.center,
  //             style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
  //           ),
  //         ],
  //       ),
  //     ),
  //   );
  // }

  void _navigateToManageEnquiriesWithFilter(BuildContext context, String status) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ManageEnquiriesScreen(
          organizationId: organizationId,
          salesmanId: salesmanId,
          initialStatus: status, // Pass single status
        ),
      ),
    );
  }

  // void _navigateToManageEnquiries(BuildContext context) {
  //   Navigator.push(
  //     context,
  //     MaterialPageRoute(
  //       builder: (context) => ManageEnquiriesScreen(
  //         organizationId: organizationId,
  //         salesmanId: salesmanId,
  //       ),
  //     ),
  //   );
  // }
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
          return data['status'] == 'pending';
        }).length;

        final inProgressEnquiries = enquiries.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return data['status'] == 'in_progress';
        }).length;

        final cancelledEnquiries = enquiries.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return data['status'] == 'cancelled';
        }).length;

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Total Card
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
              // Status Cards
              Expanded(
                flex: 3,
                child: Column(
                  children: [
                    // First row
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
                    // Second row
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
                Icon(Icons.arrow_circle_right_outlined,color: color)
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ... Rest of the _EnquiriesList and _EnquiryCard classes remain the same as your original code

// class _EnquiriesList extends StatefulWidget {
//   final String salesmanId;
//   final String organizationId;
//   final List<String> selectedStatuses;
//
//   const _EnquiriesList({
//     required this.salesmanId,
//     required this.organizationId,
//     required this.selectedStatuses,
//   });
//
//   @override
//   State<_EnquiriesList> createState() => __EnquiriesListState();
// }
//
// class __EnquiriesListState extends State<_EnquiriesList> {
//   late Stream<QuerySnapshot> _enquiriesStream;
//
//   @override
//   void initState() {
//     super.initState();
//     _updateStream();
//   }
//
//   @override
//   void didUpdateWidget(_EnquiriesList oldWidget) {
//     super.didUpdateWidget(oldWidget);
//     // Only update the stream if the status filter actually changed
//     if (oldWidget.selectedStatuses.join() != widget.selectedStatuses.join()) {
//       _updateStream();
//     }
//   }
//
//   void _updateStream() {
//     final effectiveStatuses = widget.selectedStatuses.contains('all')
//         ? ['pending', 'in_progress', 'completed', 'cancelled']
//         : widget.selectedStatuses;
//
//     _enquiriesStream = EnquiryService.searchEnquiries(
//       searchType: 'customer',
//       query: '',
//       statuses: effectiveStatuses,
//       organizationId: widget.organizationId,
//       salesmanId: widget.salesmanId,
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return StreamBuilder<QuerySnapshot>(
//       stream: _enquiriesStream,
//       builder: (context, snapshot) {
//         if (snapshot.connectionState == ConnectionState.waiting) {
//           return const LoadingIndicator();
//         }
//
//         if (snapshot.hasError) {
//           return CustomErrorWidget(
//             message: 'Failed to load enquiries: ${snapshot.error}',
//             onRetry: () {},
//           );
//         }
//
//         if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
//           return const EmptyStateWidget(
//             message: 'No enquiries assigned to you yet',
//             icon: Icons.assignment,
//           );
//         }
//
//         final enquiries = snapshot.data!.docs;
//
//         return ListView.separated(
//           itemCount: enquiries.length,
//           separatorBuilder: (context, index) => const SizedBox(height: 8),
//           itemBuilder: (context, index) {
//             final enquiry = enquiries[index];
//             final data = enquiry.data() as Map<String, dynamic>;
//
//             return _EnquiryCard(
//               enquiryId: enquiry.id,
//               data: data,
//               onTap: () => _navigateToEnquiryDetail(context, enquiry.id, data, widget.organizationId),
//             );
//           },
//         );
//       },
//     );
//   }
//
//   void _navigateToEnquiryDetail(BuildContext context, String enquiryId, Map<String, dynamic> data, String organizationId) async{
//     final userData = await CustomerService.getCustomerById(organizationId, data["customerId"]);
//     Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (context) => EnquiryDetailScreen(
//           userData: userData.data() as Map<String, dynamic>,
//           enquiryId: enquiryId,
//           enquiryData: data,
//           organizationId: organizationId,
//           isSalesman: true,
//         ),
//       ),
//     );
//   }
// }
//
// class _EnquiryCard extends StatelessWidget {
//   final String enquiryId;
//   final Map<String, dynamic> data;
//   final VoidCallback onTap;
//
//   const _EnquiryCard({
//     required this.enquiryId,
//     required this.data,
//     required this.onTap,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     return Card(
//       elevation: 2,
//       child: ListTile(
//         leading: StatusIcon(status: data['status']),
//         title: Text(
//           data['customerName'] ?? 'Unknown Customer',
//           style: const TextStyle(fontWeight: FontWeight.bold),
//           maxLines: 1,
//           overflow: TextOverflow.ellipsis,
//         ),
//         subtitle: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               data['product'] ?? 'No product specified',
//               maxLines: 1,
//               overflow: TextOverflow.ellipsis,
//             ),
//             const SizedBox(height: 4),
//             Row(
//               children: [
//                 Container(
//                   padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
//                   decoration: BoxDecoration(
//                     color: StatusUtils.getSalesmanStatusColor(data['status']).withOpacity(0.1),
//                     borderRadius: BorderRadius.circular(12),
//                     border: Border.all(
//                       color: StatusUtils.getSalesmanStatusColor(data['status']).withOpacity(0.3),
//                     ),
//                   ),
//                   child: Text(
//                     StatusUtils.formatStatus(data['status']),
//                     style: TextStyle(
//                       fontSize: 10,
//                       fontWeight: FontWeight.w600,
//                       color: StatusUtils.getSalesmanStatusColor(data['status']),
//                     ),
//                   ),
//                 ),
//                 const Spacer(),
//                 if (data['createdAt'] != null)
//                   Text(
//                     DateUtilHelper.formatDate(data['createdAt']),
//                     style: TextStyle(
//                       color: Colors.grey[600],
//                       fontSize: 10,
//                     ),
//                   ),
//               ],
//             ),
//           ],
//         ),
//         trailing: Icon(
//           Icons.chevron_right,
//           color: Colors.grey.shade400,
//         ),
//         onTap: onTap,
//         contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//       ),
//     );
//   }
// }