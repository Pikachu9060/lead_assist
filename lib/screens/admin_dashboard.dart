import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/enquiry_service.dart';
import '../services/auth_service.dart';
import '../shared/widgets/loading_indicator.dart';
import '../shared/widgets/empty_state.dart';
import '../shared/widgets/error_widget.dart';
import 'add_enquiry_screen.dart';
import 'add_salesman_screen.dart';
import 'enquiry_detail_screen.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: const _DashboardContent(),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'add_salesman',
            onPressed: () => _navigateToAddSalesman(context),
            child: const Icon(Icons.person_add),
          ),
          const SizedBox(height: 16),
          FloatingActionButton(
            heroTag: 'add_enquiry',
            onPressed: () => _navigateToAddEnquiry(context),
            child: const Icon(Icons.add_comment),
          ),
        ],
      ),
    );
  }

  static void _logout(BuildContext context) async {
    try {
      await AuthService.logout();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Logout failed: $e')),
      );
    }
  }

  static void _navigateToAddSalesman(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddSalesmanScreen()),
    );
  }

  static void _navigateToAddEnquiry(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddEnquiryScreen()),
    );
  }
}

class _DashboardContent extends StatelessWidget {
  const _DashboardContent();

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
          const SizedBox(height: 16),
          Expanded(child: _EnquiriesList()),
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
  const _EnquiriesList();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: EnquiryService.getAllEnquiries(),
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
            message: 'No enquiries yet\nTap + to create your first enquiry',
            icon: Icons.inbox,
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

  void _navigateToEnquiryDetail(BuildContext context, String enquiryId, Map<String, dynamic> data) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EnquiryDetailScreen(
          enquiryId: enquiryId,
          enquiryData: data,
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