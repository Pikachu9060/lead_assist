import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/enquiry_service.dart';
import '../shared/widgets/loading_indicator.dart';
import '../shared/widgets/empty_state.dart';

class EnquiryDetailScreen extends StatefulWidget {
  final String enquiryId;
  final Map<String, dynamic> enquiryData;
  final bool isSalesman;

  const EnquiryDetailScreen({
    super.key,
    required this.enquiryId,
    required this.enquiryData,
    this.isSalesman = false,
  });

  @override
  State<EnquiryDetailScreen> createState() => _EnquiryDetailScreenState();
}

class _EnquiryDetailScreenState extends State<EnquiryDetailScreen> {
  final TextEditingController _updateController = TextEditingController();
  bool _isLoading = false;
  String? _selectedStatus;

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.enquiryData['status'] ?? 'pending';
  }

  Future<void> _addUpdate() async {
    if (_updateController.text.trim().isEmpty) {
      _showError('Please enter an update');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      final userName = user?.displayName ?? user?.email ?? 'Unknown User';

      await EnquiryService.addUpdateToEnquiry(
        enquiryId: widget.enquiryId,
        updateText: _updateController.text.trim(),
        updatedBy: user!.uid,
        updatedByName: userName,
      );

      _updateController.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Update added successfully')),
        );
      }
    } catch (e) {
      _showError('Failed to add update: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _updateStatus() async {
    if (_selectedStatus == widget.enquiryData['status']) return;

    setState(() => _isLoading = true);

    try {
      await EnquiryService.updateEnquiryStatus(widget.enquiryId, _selectedStatus!);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Status updated successfully')),
        );
      }
    } catch (e) {
      _showError('Failed to update status: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Enquiry Details'),
      ),
      body: _isLoading
          ? const LoadingIndicator(message: 'Processing...')
          : Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildEnquiryInfo(),
                  const SizedBox(height: 24),
                  if (!widget.isSalesman) _buildStatusUpdateSection(),
                  const SizedBox(height: 24),
                  _buildUpdatesSection(),
                ],
              ),
            ),
          ),
          if (!widget.isSalesman) _buildUpdateInputSection(),
        ],
      ),
    );
  }

  Widget _buildEnquiryInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enquiry Information',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Customer', widget.enquiryData['customerName']),
            _buildInfoRow('Mobile', widget.enquiryData['customerMobile']),
            _buildInfoRow('Product', widget.enquiryData['product']),
            _buildInfoRow('Description', widget.enquiryData['description']),
            _buildInfoRow('Assigned To', widget.enquiryData['assignedSalesmanName']),
            _buildInfoRow('Status', _formatStatus(widget.enquiryData['status'])),
            if (widget.enquiryData['createdAt'] != null)
              _buildInfoRow(
                'Created',
                _formatDate(widget.enquiryData['createdAt']),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value ?? 'Not specified'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusUpdateSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Update Status',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _selectedStatus,
              decoration: const InputDecoration(
                labelText: 'Status',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'pending', child: Text('Pending')),
                DropdownMenuItem(value: 'in_progress', child: Text('In Progress')),
                DropdownMenuItem(value: 'completed', child: Text('Completed')),
                DropdownMenuItem(value: 'cancelled', child: Text('Cancelled')),
              ],
              onChanged: (value) {
                setState(() => _selectedStatus = value);
                _updateStatus();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUpdatesSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Updates',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            StreamBuilder<QuerySnapshot>(
              stream: EnquiryService.getEnquiryUpdates(widget.enquiryId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const LoadingIndicator();
                }

                if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const EmptyStateWidget(
                    message: 'No updates yet',
                    icon: Icons.chat,
                  );
                }

                final updates = snapshot.data!.docs;

                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: updates.length,
                  separatorBuilder: (context, index) => const Divider(),
                  itemBuilder: (context, index) {
                    final update = updates[index];
                    final data = update.data() as Map<String, dynamic>;

                    return _UpdateItem(updateData: data);
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUpdateInputSection() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(top: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _updateController,
              decoration: const InputDecoration(
                hintText: 'Add an update...',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              maxLines: null,
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.send),
            onPressed: _addUpdate,
          ),
        ],
      ),
    );
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
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'Invalid date';
    }
  }
}

class _UpdateItem extends StatelessWidget {
  final Map<String, dynamic> updateData;

  const _UpdateItem({required this.updateData});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              updateData['updatedByName'] ?? 'Unknown User',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            if (updateData['createdAt'] != null)
              Text(
                _formatDate(updateData['createdAt']),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Text(updateData['text'] ?? ''),
      ],
    );
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return '';

    try {
      final date = timestamp.toDate();
      return '${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return '';
    }
  }
}