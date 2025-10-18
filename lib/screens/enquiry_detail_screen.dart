import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:leadassist/shared/utils/firestore_utils.dart';
import '../services/enquiry_service.dart';
import '../services/user_service.dart';
import '../shared/widgets/loading_indicator.dart';
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

  @override
  void initState() {
    super.initState();
  }

  Future<void> _addUpdate() async {
    if (_updateController.text.trim().isEmpty) {
      _showError('Please enter an update');
      return;
    }

    setState(() => _isAddingUpdate = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      final userData = await UserService.getUser(user!.uid);
      final userName = userData['name'] ?? user.email ?? 'Unknown User';

      await EnquiryService.addUpdateToEnquiry(
        enquiryId: widget.enquiryId,
        updateText: _updateController.text.trim(),
        updatedBy: user.uid,
        updatedByName: userName,
        organizationId: widget.organizationId,
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
      await EnquiryService.updateEnquiryStatus(widget.organizationId, widget.enquiryId, newStatus);

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
    return StreamBuilder(
        stream: FirestoreUtils.getEnquiriesCollection(widget.organizationId).doc(widget.enquiryId).snapshots(),
        builder: (context, enquiryAsyncSnapshot){
          if(!enquiryAsyncSnapshot.hasData){
            return const Text("No Data Found");
          }
          if(enquiryAsyncSnapshot.hasError){
            return Text("Error while Loading Data: ${enquiryAsyncSnapshot.error}");
          }

          final enquiryData = enquiryAsyncSnapshot.data!.data() as Map<String, dynamic>;

          // Initialize _selectedStatus from the current enquiry data
          if (_selectedStatus == null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              setState(() {
                _selectedStatus = enquiryData['status'] ?? 'pending';
              });
            });
          }

          final customerFuture = FirestoreUtils.getCustomersCollection(widget.organizationId).doc(enquiryData["customerId"]).get();

          return FutureBuilder(
              future: customerFuture,
              builder: (context, customerAsyncSnapshot) {
                if(customerAsyncSnapshot.connectionState == ConnectionState.waiting){
                  return const LoadingIndicator();
                }

                if(!customerAsyncSnapshot.hasData || customerAsyncSnapshot.hasError){
                  return Text("Unable to Load Data: ${customerAsyncSnapshot.error}");
                }

                final customerData = customerAsyncSnapshot.data!.data() as Map<String, dynamic>;
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
                        _buildInfoRow('Customer', customerData['name']),
                        _buildInfoRow('Mobile', customerData['mobileNumber']),
                        _buildInfoRow('Address', customerData['address']),
                        _buildInfoRow('Product', enquiryData['product']),
                        _buildInfoRow('Description', enquiryData['description']),
                        if (!widget.isSalesman)
                          _buildInfoRow('Assigned To', enquiryData['assignedSalesmanName']),
                        // _buildInfoRow('Status', StatusUtils.formatStatus(enquiryData['status'])),
                        if (enquiryData['createdAt'] != null)
                          _buildInfoRow(
                            'Created',
                            DateUtilHelper.formatDateTime(enquiryData['createdAt']),
                          ),
                        if (enquiryData['updatedAt'] != null)
                          _buildInfoRow(
                            'Last Updated',
                            DateUtilHelper.formatDateTime(enquiryData['updatedAt']),
                          ),
                      ],
                    ),
                  ),
                );
              }
          );
        }
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
            if (_selectedStatus != null)
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
            StreamBuilder<QuerySnapshot>(
              stream: EnquiryService.getEnquiryUpdates(widget.organizationId, widget.enquiryId),
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
    updates.sort((a, b) {
      final aTime = (a.data() as Map<String, dynamic>)['createdAt']?.toDate() ?? DateTime.now();
      final bTime = (b.data() as Map<String, dynamic>)['createdAt']?.toDate() ?? DateTime.now();
      return bTime.compareTo(aTime);
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
                        updateData['updatedByName'] ?? 'Unknown User',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    if (updateData['createdAt'] != null)
                      Text(
                        DateUtilHelper.formatDateWithTime(updateData['createdAt']),
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
}