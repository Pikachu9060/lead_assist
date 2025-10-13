import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:leadassist/services/customer_service.dart';

import '../services/enquiry_service.dart';
import '../shared/widgets/empty_state.dart';
import '../shared/widgets/loading_indicator.dart';
import 'enquiry_detail_screen.dart';

class ManageEnquiriesScreen extends StatefulWidget {
  final String organizationId;

  const ManageEnquiriesScreen({super.key, required this.organizationId});

  @override
  State<ManageEnquiriesScreen> createState() => _ManageEnquiriesScreenState();
}

class _ManageEnquiriesScreenState extends State<ManageEnquiriesScreen> {
  final List<String> _selectedStatuses = ['all'];
  final List<String> _allStatuses = ['all', 'pending', 'in_progress', 'completed', 'cancelled'];
  String _searchType = 'customer';
  String _searchQuery = '';
  bool _showFilters = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Enquiries'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              setState(() {
                _showFilters = !_showFilters;
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          if (_showFilters) _buildFilterSection(),
          Expanded(
            child: _EnquiriesList(
              key: ValueKey('enquiries_${_selectedStatuses.join('_')}_$_searchType$_searchQuery'),
              selectedStatuses: _selectedStatuses.contains('all')
                  ? ['pending', 'in_progress', 'completed', 'cancelled']
                  : _selectedStatuses,
              searchType: _searchType,
              searchQuery: _searchQuery,
              organizationId: widget.organizationId,
            ),
          ),
        ],
      ),

    );
  }

  Widget _buildFilterSection() {
    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Search Row
            Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      hintText: 'Search enquiries...',
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  value: _searchType,
                  items: const [
                    DropdownMenuItem(value: 'customer', child: Text('Customer')),
                    DropdownMenuItem(value: 'salesman', child: Text('Salesman')),
                    DropdownMenuItem(value: 'enquiry', child: Text('Product')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _searchType = value!;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Status Filters - Clickable Text
            Row(
              children: [
                GestureDetector(
                  onTap: _showStatusSelectionDialog,
                  child: const Row(
                    children: [
                      Text(
                        'Filter by Status',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(Icons.arrow_drop_down, size: 16, color: Colors.blue),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showStatusSelectionDialog() {
    List<String> tempSelectedStatuses = List.from(_selectedStatuses);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Select Statuses'),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: _allStatuses.map((status) {
                    final isSelected = tempSelectedStatuses.contains(status);
                    return CheckboxListTile(
                      title: Text(
                        status == 'all'
                            ? 'All Statuses'
                            : status.replaceAll('_', ' ').toUpperCase(),
                      ),
                      value: isSelected,
                      onChanged: (bool? value) {
                        setStateDialog(() {
                          if (status == 'all') {
                            tempSelectedStatuses.clear();
                            if (value == true) {
                              tempSelectedStatuses.add('all');
                            }
                          } else {
                            tempSelectedStatuses.remove('all');
                            if (value == true) {
                              tempSelectedStatuses.add(status);
                            } else {
                              tempSelectedStatuses.remove(status);
                            }

                            if (tempSelectedStatuses.isEmpty) {
                              tempSelectedStatuses.add('all');
                            }
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _selectedStatuses.clear();
                      _selectedStatuses.addAll(tempSelectedStatuses);
                    });
                    Navigator.pop(context);
                  },
                  child: const Text('Apply'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

// Update _EnquiriesList to be stateful and maintain its own stream
class _EnquiriesList extends StatefulWidget {
  final List<String> selectedStatuses;
  final String searchType;
  final String searchQuery;
  final String organizationId;

  const _EnquiriesList({
    required this.selectedStatuses,
    required this.searchType,
    required this.searchQuery,
    required this.organizationId,
    Key? key,
  }) : super(key: key);

  @override
  State<_EnquiriesList> createState() => __EnquiriesListState();
}

class __EnquiriesListState extends State<_EnquiriesList> {
  late Stream<QuerySnapshot> _enquiriesStream;

  @override
  void initState() {
    super.initState();
    _enquiriesStream = EnquiryService.searchEnquiries(
      searchType: widget.searchType,
      query: widget.searchQuery,
      statuses: widget.selectedStatuses,
      organizationId: widget.organizationId,
    );
  }

  @override
  void didUpdateWidget(_EnquiriesList oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Only update the stream if the filter parameters actually changed
    if (oldWidget.selectedStatuses.join() != widget.selectedStatuses.join() ||
        oldWidget.searchType != widget.searchType ||
        oldWidget.searchQuery != widget.searchQuery) {
      _enquiriesStream = EnquiryService.searchEnquiries(
        searchType: widget.searchType,
        query: widget.searchQuery,
        statuses: widget.selectedStatuses,
        organizationId: widget.organizationId,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _enquiriesStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingIndicator();
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const EmptyStateWidget(
            message: 'No enquiries found\nTry adjusting your filters',
            icon: Icons.search_off,
          );
        }

        final enquiries = snapshot.data!.docs;

        return ListView.builder(
          itemCount: enquiries.length,
          itemBuilder: (context, index) {
            final enquiry = enquiries[index];
            final data = enquiry.data() as Map<String, dynamic>;

            return _EnquiryCard(
              enquiryId: enquiry.id,
              data: data,
              onTap: () => _navigateToEnquiryDetail(context, enquiry.id, data, widget.organizationId),
            );
          },
        );
      },
    );
  }

  void _navigateToEnquiryDetail(
      BuildContext context,
      String enquiryId,
      Map<String, dynamic> data,
      String organizationId,
      ) async{
    final userData = await CustomerService.getCustomerById(widget.organizationId, data["customerId"]);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EnquiryDetailScreen(
          userData: userData.data() as Map<String, dynamic>,
          enquiryId: enquiryId,
          enquiryData: data,
          organizationId: organizationId,
          isSalesman: false,
        ),
      ),
    );
  }
}

// _EnquiryCard remains the same...
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
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: _buildStatusIcon(data['status']),
        title: Text(
          data['customerName'] ?? 'Unknown Customer',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Product: ${data['product'] ?? 'Not specified'}'),
            if (data['assignedSalesmanName'] != null)
              Text('Salesman: ${data['assignedSalesmanName']}'),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 12, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(
                  _formatDate(data['createdAt']),
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
              ],
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
    String tooltip;

    switch (status) {
      case 'completed':
        icon = Icons.check_circle;
        color = Colors.green;
        tooltip = 'Completed';
        break;
      case 'in_progress':
        icon = Icons.refresh;
        color = Colors.orange;
        tooltip = 'In Progress';
        break;
      case 'cancelled':
        icon = Icons.cancel;
        color = Colors.red;
        tooltip = 'Cancelled';
        break;
      default:
        icon = Icons.pending;
        color = Colors.blue;
        tooltip = 'Pending';
    }

    return Tooltip(
      message: tooltip,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: 20),
      ),
    );
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