import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/enquiry_service.dart';
import '../services/auth_service.dart';
import '../shared/widgets/loading_indicator.dart';
import '../shared/widgets/empty_state.dart';
import '../shared/widgets/error_widget.dart';
import 'enquiry_detail_screen.dart';

class SalesmanDashboard extends StatelessWidget {
  const SalesmanDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Salesman Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: const _DashboardContent(),
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
}

class _DashboardContent extends StatelessWidget {
  const _DashboardContent();

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final salesmanId = user?.uid;

    if (salesmanId == null) {
      return const CustomErrorWidget(message: 'User not authenticated');
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _WelcomeHeader(user: user),
          const SizedBox(height: 24),
          const Text(
            'My Assigned Enquiries',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Expanded(child: _EnquiriesList(salesmanId: salesmanId)),
        ],
      ),
    );
  }
}

class _WelcomeHeader extends StatelessWidget {
  final User? user;

  const _WelcomeHeader({required this.user});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            const Icon(Icons.person, size: 40),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome, Salesman',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  Text(
                    user?.email ?? 'Salesman User',
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
  final String salesmanId;

  const _EnquiriesList({required this.salesmanId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: EnquiryService.getEnquiriesForSalesman(salesmanId),
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
            Text('Status: ${_formatStatus(data['status'])}'),
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