import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:leadassist/cached_services/cached_update_service.dart';
import '../cached_services/cached_customer_service.dart';
import '../cached_services/cached_enquiry_service.dart';
import '../cached_services/cached_user_service.dart';
import '../models/customer_model.dart';
import '../models/enquiry_model.dart';
import '../models/update_model.dart';
import '../models/user_model.dart';
import '../shared/widgets/empty_state.dart';
import '../shared/utils/date_utils.dart';
import '../shared/utils/status_utils.dart';

class EnquiryDetailScreen extends StatefulWidget {
  final String enquiryId;
  final bool isSalesman;
  final String organizationId;

  const EnquiryDetailScreen({
    super.key,
    required this.enquiryId,
    required this.organizationId,
    this.isSalesman = false,
  });

  @override
  State<EnquiryDetailScreen> createState() => _EnquiryDetailScreenState();
}

class _EnquiryDetailScreenState extends State<EnquiryDetailScreen> {
  final TextEditingController _updateController = TextEditingController();
  bool _isAddingUpdate = false;
  bool _isUpdatingStatus = false;
  String? _selectedStatus;
  bool _isInitialLoad = true;

  @override
  void initState() {
    super.initState();
    // Initialize the updates stream for this enquiry
    CachedUpdateService.initializeUpdatesStream(
        widget.organizationId,
        widget.enquiryId
    );
    // Set initial load to false after a small delay to show cached data quickly
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          _isInitialLoad = false;
        });
      }
    });
  }

  Future<void> _addUpdate() async {
    if (_updateController.text.trim().isEmpty) {
      _showError('Please enter an update');
      return;
    }

    setState(() => _isAddingUpdate = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      final userData = await CachedUserService.getUserById(user!.uid);
      final userName = userData?.name ?? user.email ?? 'Unknown User';

      await CachedEnquiryService.addUpdateToEnquiry(
        organizationId: widget.organizationId,
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
        setState(() => _isAddingUpdate = false);
      }
    }
  }

  Future<void> _updateStatus(String? newStatus) async {
    if (_selectedStatus == newStatus || newStatus == null) return;

    setState(() => _isUpdatingStatus = true);

    try {
      await CachedEnquiryService.updateEnquiryStatus(
          widget.organizationId,
          widget.enquiryId,
          newStatus
      );

      setState(() {
        _selectedStatus = newStatus;
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
        setState(() => _isUpdatingStatus = false);
      }
    }
  }

  void _showUpdateDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildUpdateBottomSheet(),
    );
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
    if (_isInitialLoad) {
      return Scaffold(
        appBar: AppBar(title: const Text('Enquiry Details')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Enquiry Details'),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildEnquiryInfo(),
                  const SizedBox(height: 24),
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
    return StreamBuilder<List<EnquiryModel>>(
      stream: CachedEnquiryService.watchAllEnquiries(widget.organizationId),
      builder: (context, snapshot) {
        // Don't show loading for stream updates, only show data
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildEnquiryInfoPlaceholder();
        }

        // Find the specific enquiry
        final enquiry = snapshot.data!.firstWhere(
              (e) => e.enquiryId == widget.enquiryId,
          orElse: () => null as EnquiryModel,
        );

        if (enquiry == null) {
          return _buildEnquiryInfoPlaceholder();
        }

        // Initialize _selectedStatus from the current enquiry data
        if (_selectedStatus == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            setState(() {
              _selectedStatus = enquiry.status;
            });
          });
        }

        return StreamBuilder<List<CustomerModel>>(
          stream: CachedCustomerService.watchCustomers(widget.organizationId),
          builder: (context, customerSnapshot) {
            final customer = customerSnapshot.hasData
                ? customerSnapshot.data!.firstWhere(
                  (c) => c.customerId == enquiry.customerId,
              orElse: () => null as CustomerModel,
            )
                : null;

            return StreamBuilder<List<UserModel>>(
              stream: CachedUserService.watchUsers(widget.organizationId),
              builder: (context, userSnapshot) {
                final salesman = userSnapshot.hasData
                    ? userSnapshot.data!.firstWhere(
                      (u) => u.userId == enquiry.assignedSalesmanId,
                  orElse: () => null as UserModel,
                )
                    : null;

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
                        _buildInfoRow('Customer', customer?.name ?? 'Loading...'),
                        _buildInfoRow('Mobile', customer?.mobileNumber ?? 'Loading...'),
                        _buildInfoRow('Address', customer?.address ?? 'Loading...'),
                        _buildInfoRow('Product', enquiry.product),
                        _buildInfoRow('Description', enquiry.description),
                        if (!widget.isSalesman)
                          _buildInfoRow('Assigned To', salesman?.name ?? 'Loading...'),
                        _buildInfoRow('Status', StatusUtils.formatStatus(enquiry.status)),
                        _buildInfoRow(
                          'Created',
                          DateUtilHelper.formatDateTime(enquiry.createdAt),
                        ),
                        _buildInfoRow(
                          'Last Updated',
                          DateUtilHelper.formatDateTime(enquiry.updatedAt),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildEnquiryInfoPlaceholder() {
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
            _buildInfoRow('Customer', 'Loading...'),
            _buildInfoRow('Mobile', 'Loading...'),
            _buildInfoRow('Address', 'Loading...'),
            _buildInfoRow('Product', 'Loading...'),
            _buildInfoRow('Description', 'Loading...'),
            if (!widget.isSalesman)
              _buildInfoRow('Assigned To', 'Loading...'),
            _buildInfoRow('Status', 'Loading...'),
            _buildInfoRow('Created', 'Loading...'),
            _buildInfoRow('Last Updated', 'Loading...'),
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
    if (_selectedStatus == null) {
      return const SizedBox(); // Don't show until we have data
    }

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
            Stack(
              children: [
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
                  onChanged: _isUpdatingStatus ? null : (value) {
                    _updateStatus(value);
                  },
                ),
                if (_isUpdatingStatus)
                  Positioned.fill(
                    child: Container(
                      color: Colors.black.withOpacity(0.1),
                      child: const Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Current: ${StatusUtils.formatStatus(_selectedStatus!)}',
              style: TextStyle(
                color: StatusUtils.getStatusColor(_selectedStatus!),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

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
            StreamBuilder<List<UpdateModel>>(
              stream: CachedUpdateService.watchUpdatesForEnquiry(
                  widget.organizationId,
                  widget.enquiryId
              ),
              builder: (context, snapshot) {
                // Show empty state immediately if no data
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const EmptyStateWidget(
                    message: 'No updates yet\nTap the + button to add your first visit update',
                    icon: Icons.timeline,
                  );
                }

                final updates = snapshot.data!;
                return _buildTimeline(updates);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeline(List<UpdateModel> updates) {
    // Sort updates by createdAt in descending order (newest first)
    updates.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: updates.length,
      itemBuilder: (context, index) {
        final update = updates[index];
        final isFirst = index == 0;
        final isLast = index == updates.length - 1;

        return _TimelineItem(
          update: update,
          isFirst: isFirst,
          isLast: isLast,
        );
      },
    );
  }

  Widget _buildAddUpdateFAB() {
    return FloatingActionButton.extended(
      onPressed: _showUpdateDialog,
      icon: const Icon(Icons.add_comment),
      label: const Text('Add Update'),
      backgroundColor: Colors.blue,
      foregroundColor: Colors.white,
    );
  }

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
              hintStyle: TextStyle(
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w300,
                color: Colors.grey,
              ),
            ),
            maxLines: 5,
            autofocus: true,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _isAddingUpdate ? null : _hideUpdateDialog,
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _isAddingUpdate ? null : _addUpdate,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                  child: _isAddingUpdate
                      ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                      : const Text('Add Update'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _TimelineItem extends StatelessWidget {
  final UpdateModel update;
  final bool isFirst;
  final bool isLast;

  const _TimelineItem({
    required this.update,
    required this.isFirst,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            if (!isFirst)
              Container(
                width: 2,
                height: 20,
                color: Colors.grey[300],
              ),
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 20,
                color: Colors.grey[300],
              ),
          ],
        ),
        const SizedBox(width: 16),
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
                        "${update.updatedByName} (${update.updatedBy == FirebaseAuth.instance.currentUser!.uid ? 'You' : 'Manager'})",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    Text(
                      DateUtilHelper.formatDateWithTime(update.createdAt),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  update.text ?? '',
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    DateUtilHelper.parseTimestamp(update.createdAt).toString() ?? '',
                    style: const TextStyle(fontSize: 11, color: Colors.grey, fontStyle: FontStyle.italic),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}