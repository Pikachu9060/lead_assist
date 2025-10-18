import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../services/enquiry_service.dart';
import '../shared/widgets/empty_state.dart';
import '../shared/widgets/loading_indicator.dart';
import '../shared/widgets/status_icon.dart';
import '../shared/utils/date_utils.dart';
import 'enquiry_detail_screen.dart';

class ManageEnquiriesScreen extends StatefulWidget {
  final String organizationId;
  final String? salesmanId;
  final String? initialStatus;

  const ManageEnquiriesScreen({
    super.key,
    required this.organizationId,
    this.salesmanId,
    this.initialStatus,
  });

  @override
  State<ManageEnquiriesScreen> createState() => _ManageEnquiriesScreenState();
}

class _ManageEnquiriesScreenState extends State<ManageEnquiriesScreen> {
  final List<String> _selectedStatuses = ['all'];
  final List<String> _allStatuses = ['all', 'pending', 'in_progress', 'completed', 'cancelled'];
  String _searchQuery = '';
  bool _showFilters = true;
  bool _isSearchExpanded = false; // Controls app bar search expansion
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();

    if (widget.initialStatus != null) {
      _selectedStatuses.clear();
      _selectedStatuses.add(widget.initialStatus!);
      _showFilters = false;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: Column(
        children: [
          if (_showFilters) _buildFilterSection(),
          if (!_showFilters && widget.initialStatus != null) _buildStatusHeader(),
          Expanded(
            child: _EnquiriesList(
              salesmanId: widget.salesmanId,
              selectedStatuses: _getEffectiveStatuses(),
              searchQuery: _searchQuery,
              organizationId: widget.organizationId,
            ),
          ),
        ],
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      title: _isSearchExpanded ? _buildSearchField() : _buildAppBarTitle(),
      actions: _buildAppBarActions(),
    );
  }

  Widget _buildSearchField() {
    return TextField(

      controller: _searchController,
      autofocus: true,
      decoration: InputDecoration(
        hintText: 'Search in product, description...',
        border: InputBorder.none,
        hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
      ),
      // style: const TextStyle(color: Colors.white),
      onChanged: (value) {
        setState(() {
          _searchQuery = value.trim();
        });
      },
      onSubmitted: (value) {
        // Keep search expanded after submission
        setState(() {
          _searchQuery = value.trim();
        });
      },
    );
  }

  List<Widget> _buildAppBarActions() {
    if (_isSearchExpanded) {
      return [
        IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () {
            setState(() {
              _isSearchExpanded = false;
              _searchQuery = '';
              _searchController.clear();
            });
          },
        ),
      ];
    } else {
      return [
        IconButton(
          icon: const Icon(Icons.search),
          onPressed: () {
            setState(() {
              _isSearchExpanded = true;
            });
          },
        ),
        if (_showFilters)
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              setState(() {
                _showFilters = !_showFilters;
              });
            },
          ),
      ];
    }
  }

  List<String> _getEffectiveStatuses() {
    if (widget.initialStatus != null) {
      return widget.initialStatus == 'all'
          ? ['pending', 'in_progress', 'completed', 'cancelled']
          : [widget.initialStatus!];
    }
    return _selectedStatuses.contains('all')
        ? ['pending', 'in_progress', 'completed', 'cancelled']
        : _selectedStatuses;
  }

  Widget _buildAppBarTitle() {
    if (widget.initialStatus != null && widget.initialStatus != 'all') {
      return Text(
        '${_formatStatus(widget.initialStatus!)} Enquiries',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    }
    return Text(
      widget.salesmanId != null ? 'My Assigned Enquiries' : 'Manage Enquiries',
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildStatusHeader() {
    if (widget.initialStatus != null && widget.initialStatus != 'all') {
      final status = widget.initialStatus!;
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        color: _getStatusColor(status).withOpacity(0.1),
        child: Text(
          'Showing ${_formatStatus(status)} Enquiries',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: _getStatusColor(status),
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      );
    }
    return const SizedBox();
  }

  Widget _buildFilterSection() {
    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Status Filters
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
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _getCurrentStatusText(),
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatStatus(String status) {
    return status.replaceAll('_', ' ').toUpperCase();
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending': return Colors.blue;
      case 'in_progress': return Colors.orange;
      case 'completed': return Colors.green;
      case 'cancelled': return Colors.red;
      default: return Colors.grey;
    }
  }

  String _getCurrentStatusText() {
    if (_selectedStatuses.contains('all') || _selectedStatuses.length == 4) {
      return 'All Statuses';
    } else {
      return _selectedStatuses.map((status) => status.replaceAll('_', ' ')).join(', ');
    }
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
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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
                  onPressed: () => Navigator.pop(context),
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

class _EnquiriesList extends StatefulWidget {
  final List<String> selectedStatuses;
  final String searchQuery;
  final String organizationId;
  final String? salesmanId;

  const _EnquiriesList({
    required this.selectedStatuses,
    required this.searchQuery,
    required this.organizationId,
    this.salesmanId,
  });

  @override
  State<_EnquiriesList> createState() => __EnquiriesListState();
}

class __EnquiriesListState extends State<_EnquiriesList> {
  late Stream<QuerySnapshot> _enquiriesStream;

  @override
  void initState() {
    super.initState();
    _updateStream();
  }

  @override
  void didUpdateWidget(_EnquiriesList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedStatuses.join() != widget.selectedStatuses.join()) {
      _updateStream();
    }
  }

  void _updateStream() {
    _enquiriesStream = EnquiryService.searchEnquiries(
      salesmanId: widget.salesmanId,
      searchType: 'all', // Always get all data for client-side search
      query: '', // Empty query to get all data
      statuses: widget.selectedStatuses,
      organizationId: widget.organizationId,
    );
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
          return Center(
            child: Text(
              'Error: ${snapshot.error}',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          );
        }

        if (!snapshot.hasData) {
          return const EmptyStateWidget(
            message: 'No data available',
            icon: Icons.error_outline,
          );
        }

        // Get all enquiries from stream
        List<QueryDocumentSnapshot> allEnquiries = snapshot.data!.docs;

        // Apply client-side search filtering
        List<QueryDocumentSnapshot> filteredEnquiries = _applySearchFilter(allEnquiries);

        if (filteredEnquiries.isEmpty) {
          return EmptyStateWidget(
            message: widget.searchQuery.isEmpty
                ? 'No enquiries found\nTry adjusting your filters'
                : 'No results for "${widget.searchQuery}"\nTry different search terms',
            icon: Icons.search_off,
          );
        }

        return ListView.builder(
          itemCount: filteredEnquiries.length,
          itemBuilder: (context, index) {
            final enquiry = filteredEnquiries[index];
            final data = enquiry.data() as Map<String, dynamic>;

            return _EnquiryCard(
              enquiryId: enquiry.id,
              data: data,
              searchQuery: widget.searchQuery, // Pass search query for highlighting
              onTap: () => _navigateToEnquiryDetail(
                context,
                enquiry.id,
                data,
                widget.organizationId,
              ),
            );
          },
        );
      },
    );
  }

  List<QueryDocumentSnapshot> _applySearchFilter(List<QueryDocumentSnapshot> enquiries) {
    if (widget.searchQuery.isEmpty) {
      return enquiries; // Return all if no search query
    }

    final searchTerm = widget.searchQuery.toLowerCase();

    return enquiries.where((enquiry) {
      final data = enquiry.data() as Map<String, dynamic>;

      // Search across multiple fields
      final product = data['product']?.toString().toLowerCase() ?? '';
      final description = data['description']?.toString().toLowerCase() ?? '';
      final customerName = data['customerName']?.toString().toLowerCase() ?? '';
      final salesmanName = data['assignedSalesmanName']?.toString().toLowerCase() ?? '';

      // Search in all relevant fields
      return product.contains(searchTerm) ||
          description.contains(searchTerm) ||
          customerName.contains(searchTerm) ||
          salesmanName.contains(searchTerm);
    }).toList();
  }

  void _navigateToEnquiryDetail(
      BuildContext context,
      String enquiryId,
      Map<String, dynamic> data,
      String organizationId,
      ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EnquiryDetailScreen(
          enquiryId: enquiryId,
          organizationId: organizationId,
          isSalesman: widget.salesmanId != null,
        ),
      ),
    );
  }
}

class _EnquiryCard extends StatelessWidget {
  final String enquiryId;
  final Map<String, dynamic> data;
  final String searchQuery;
  final VoidCallback onTap;

  const _EnquiryCard({
    required this.enquiryId,
    required this.data,
    required this.searchQuery,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: StatusIcon(status: data['status']),
        title: _buildHighlightedText(
          data['product'] ?? 'No Product',
          searchQuery,
          isTitle: true,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHighlightedText(
              data['description'] ?? 'No description',
              searchQuery,
            ),
            const SizedBox(height: 4),
            // if (data['customerName'] != null)
            //   _buildHighlightedText(
            //     'Customer: ${data['customerName']}',
            //     searchQuery,
            //   ),
            // if (data['assignedSalesmanName'] != null)
            //   _buildHighlightedText(
            //     'Salesman: ${data['assignedSalesmanName']}',
            //     searchQuery,
            //   ),
            // const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 12, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(
                  DateUtilHelper.formatDate(data['createdAt']),
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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

  Widget _buildHighlightedText(String text, String query, {bool isTitle = false}) {
    if (query.isEmpty) {
      return Text(
        text,
        maxLines: 1,
        overflow: isTitle ? TextOverflow.ellipsis : TextOverflow.fade,
        style: TextStyle(
          fontWeight: isTitle ? FontWeight.bold : FontWeight.normal,
          color: Colors.grey[600],
          fontSize: isTitle ? null : 12,
        ),
      );
    }

    final textLower = text.toLowerCase();
    final queryLower = query.toLowerCase();
    final matches = <TextSpan>[];
    int start = 0;

    while (start < textLower.length) {
      final matchIndex = textLower.indexOf(queryLower, start);
      if (matchIndex == -1) {
        // No more matches
        matches.add(TextSpan(
          text: text.substring(start),
          style: TextStyle(
            fontWeight: isTitle ? FontWeight.bold : FontWeight.normal,
            color: Colors.grey[600],
            fontSize: isTitle ? null : 12,
          ),
        ));
        break;
      }

      // Add text before match
      if (matchIndex > start) {
        matches.add(TextSpan(
          text: text.substring(start, matchIndex),
          style: TextStyle(
            fontWeight: isTitle ? FontWeight.bold : FontWeight.normal,
            color: Colors.grey[600],
            fontSize: isTitle ? null : 12,
          ),
        ));
      }

      // Add matched text with highlight
      matches.add(TextSpan(
        text: text.substring(matchIndex, matchIndex + query.length),
        style: TextStyle(
          fontWeight: isTitle ? FontWeight.bold : FontWeight.normal,
          color: Colors.blue.shade700,
          backgroundColor: Colors.blue.shade100,
          fontSize: isTitle ? null : 12,
        ),
      ));

      start = matchIndex + query.length;
    }

    return RichText(
      maxLines: 1,
      overflow: isTitle ? TextOverflow.ellipsis : TextOverflow.fade,
      text: TextSpan(children: matches),
    );
  }
}