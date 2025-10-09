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
      final userDoc = await FirebaseFirestore.instance
          .collection(widget.isSalesman ? 'salesmen' : 'admins')
          .doc(user!.uid)
          .get();
      final userName = userDoc['name'] ?? user.email ?? 'Unknown User';

      await EnquiryService.addUpdateToEnquiry(
        enquiryId: widget.enquiryId,
        updateText: _updateController.text.trim(),
        updatedBy: user.uid,
        updatedByName: userName,
      );

      _updateController.clear();
      _hideUpdateDialog();
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

      // Update local state
      setState(() {
        widget.enquiryData['status'] = _selectedStatus;
      });

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

  void _showUpdateDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildUpdateBottomSheet(),
    ).then((_) {
    });
  }

  void _hideUpdateDialog() {
    Navigator.of(context).pop();
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

                  // ✅ STATUS UPDATE SECTION - AVAILABLE FOR SALESMAN
                  _buildStatusUpdateSection(),
                  const SizedBox(height: 24),

                  _buildTimelineSection(),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: _buildAddUpdateFAB(),
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
            if (!widget.isSalesman)
              _buildInfoRow('Assigned To', widget.enquiryData['assignedSalesmanName']),
            _buildInfoRow('Status', _formatStatus(widget.enquiryData['status'])),
            if (widget.enquiryData['createdAt'] != null)
              _buildInfoRow(
                'Created',
                _formatDate(widget.enquiryData['createdAt']),
              ),
            if (widget.enquiryData['updatedAt'] != null)
              _buildInfoRow(
                'Last Updated',
                _formatDate(widget.enquiryData['updatedAt']),
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

  // ✅ STATUS UPDATE - AVAILABLE FOR SALESMAN
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
            const SizedBox(height: 8),
            Text(
              'Current: ${_formatStatus(widget.enquiryData['status'])}',
              style: TextStyle(
                color: _getStatusColor(widget.enquiryData['status']),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ TIMELINE SECTION
  Widget _buildTimelineSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.timeline, color: Colors.blue),
                const SizedBox(width: 8),
                const Text(
                  'Visit Timeline & Updates',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Track all customer visits and updates in chronological order',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
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
                    message: 'No updates yet\nTap the + button to add your first visit update',
                    icon: Icons.timeline,
                  );
                }

                final updates = snapshot.data!.docs;

                return _buildTimeline(updates);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeline(List<QueryDocumentSnapshot> updates) {
    // Sort updates by creation date (newest first)
    updates.sort((a, b) {
      final aTime = (a.data() as Map<String, dynamic>)['createdAt']?.toDate() ?? DateTime.now();
      final bTime = (b.data() as Map<String, dynamic>)['createdAt']?.toDate() ?? DateTime.now();
      return bTime.compareTo(aTime); // Newest first
    });

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: updates.length,
      itemBuilder: (context, index) {
        final update = updates[index];
        final data = update.data() as Map<String, dynamic>;
        final isFirst = index == 0;
        final isLast = index == updates.length - 1;

        return _TimelineItem(
          updateData: data,
          isFirst: isFirst,
          isLast: isLast,
        );
      },
    );
  }

  // ✅ FAB FOR ADDING UPDATES
  Widget _buildAddUpdateFAB() {
    return FloatingActionButton.extended(
      onPressed: _showUpdateDialog,
      icon: const Icon(Icons.add_comment),
      label: const Text('Add Update'),
      backgroundColor: Colors.blue,
      foregroundColor: Colors.white,
    );
  }

  // ✅ BOTTOM SHEET FOR ADDING UPDATES
  Widget _buildUpdateBottomSheet() {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Add Visit Update',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Share customer visit details, feedback, or next steps...',
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _updateController,
            decoration: const InputDecoration(
              hintText: 'Describe your visit, customer feedback, next actions...',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
            maxLines: 5,
            autofocus: true,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _hideUpdateDialog,
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _addUpdate,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Add Update'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
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
      default:
        return Colors.blue;
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
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'Invalid date';
    }
  }
}

// ✅ TIMELINE ITEM WIDGET
class _TimelineItem extends StatelessWidget {
  final Map<String, dynamic> updateData;
  final bool isFirst;
  final bool isLast;

  const _TimelineItem({
    required this.updateData,
    required this.isFirst,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Timeline line
        Column(
          children: [
            // Top connector (hidden for first item)
            if (!isFirst)
              Container(
                width: 2,
                height: 20,
                color: Colors.grey[300],
              ),
            // Timeline dot
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
            // Bottom connector (hidden for last item)
            if (!isLast)
              Container(
                width: 2,
                height: 20,
                color: Colors.grey[300],
              ),
          ],
        ),
        const SizedBox(width: 16),
        // Content
        Expanded(
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.blue[100],
                      radius: 14,
                      child: Icon(
                        Icons.person,
                        size: 14,
                        color: Colors.blue[600],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        updateData['updatedByName'] ?? 'Unknown User',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    if (updateData['createdAt'] != null)
                      Text(
                        _formatDateTime(updateData['createdAt']),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  updateData['text'] ?? '',
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _formatDateTime(dynamic timestamp) {
    if (timestamp == null) return '';

    try {
      final date = timestamp.toDate();
      return '${_formatTime(date)} • ${_formatDate(date)}';
    } catch (e) {
      return '';
    }
  }

  String _formatTime(DateTime date) {
    return '${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}