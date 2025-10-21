
import 'package:flutter/material.dart';
import '../cached_services/cached_enquiry_service.dart';
import '../cached_services/cached_customer_service.dart';
import '../cached_services/cached_user_service.dart';
import '../shared/widgets/empty_state.dart';
import '../shared/widgets/loading_indicator.dart';
import '../shared/widgets/status_icon.dart';
import '../shared/utils/date_utils.dart';
import 'enquiry_detail_screen.dart';
import '../models/enquiry_model.dart';
import '../models/customer_model.dart';
import '../models/user_model.dart';

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
  bool _isSearchExpanded = false;
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
        hintText: 'Search product, description, customer name, mobile or address...',
        border: InputBorder.none,
        hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
      ),
      onChanged: (value) {
        setState(() {
          _searchQuery = value.trim();
        });
      },
      onSubmitted: (value) {
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
  final Map<String, CustomerModel> _customerCache = {};
  final Map<String, UserModel> _salesmanCache = {};
  final ValueNotifier<List<EnquiryModel>> _enquiriesNotifier = ValueNotifier<List<EnquiryModel>>([]);
  bool _isInitialLoad = true;

  @override
  void initState() {
    super.initState();
    _initializeStreams();
  }

  @override
  void dispose() {
    _enquiriesNotifier.dispose();
    super.dispose();
  }

  void _initializeStreams() {
    // Initialize customer stream
    final customerStream = CachedCustomerService.watchCustomers(widget.organizationId);
    customerStream.listen((customers) {
      for (final customer in customers) {
        _customerCache[customer.customerId] = customer;
      }
      if (mounted) setState(() {});
    });

    // Initialize salesman stream
    final salesmanStream = CachedUserService.watchUsers(widget.organizationId);
    salesmanStream.listen((users) {
      for (final user in users) {
        _salesmanCache[user.userId] = user;
      }
      if (mounted) setState(() {});
    });

    // Initialize enquiries stream - FIXED LOGIC
    Stream<List<EnquiryModel>> enquiriesStream;

    if (widget.salesmanId != null) {
      // For salesman: show only their assigned enquiries
      enquiriesStream = CachedEnquiryService.watchEnquiriesForSalesman(
        widget.organizationId,
        widget.salesmanId!,
        status: widget.selectedStatuses.contains('all') ? null : widget.selectedStatuses,
      );
    } else {
      // For admin/manager: show ALL enquiries in the organization
      enquiriesStream = CachedEnquiryService.watchAllEnquiries(widget.organizationId);
      print("admin here ${enquiriesStream.isEmpty}");
    }

    print("salesman Id : ${widget.salesmanId}");
    // Apply status filtering for admin/manager
    if (widget.salesmanId == null) {
      enquiriesStream = enquiriesStream.map((enquiries) {
        print("Here 2");
        if (widget.selectedStatuses.contains('all')) {
          return enquiries;
        }
        return enquiries.where((enquiry) =>
            widget.selectedStatuses.contains(enquiry.status)
        ).toList();
      });
    }

    enquiriesStream.length.then((value) => print("Enquiry Stream Value $value"));

    enquiriesStream.listen((enquiries) {
      _enquiriesNotifier.value = enquiries;
      print("Enquiries loaded: ${enquiries.length} for org: ${widget.organizationId}, statuses: ${widget.selectedStatuses}");
      if (_isInitialLoad) {
        setState(() {
          _isInitialLoad = false;
        });
      }
    }, onError: (error) {
      print("Error loading enquiries: $error");
      if (_isInitialLoad) {
        setState(() {
          _isInitialLoad = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitialLoad) {
      return const LoadingIndicator();
    }

    return ValueListenableBuilder<List<EnquiryModel>>(
      valueListenable: _enquiriesNotifier,
      builder: (context, enquiries, child) {
        final filteredEnquiries = _applySearchFilter(enquiries);

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
            final customer = _customerCache[enquiry.customerId];
            final salesman = _salesmanCache[enquiry.assignedSalesmanId];

            return _buildEnquiryCard(enquiry, customer, salesman);
          },
        );
      },
    );
  }

  List<EnquiryModel> _applySearchFilter(List<EnquiryModel> enquiries) {
    if (widget.searchQuery.isEmpty) {
      return enquiries;
    }

    final searchTerm = widget.searchQuery.toLowerCase();

    return enquiries.where((enquiry) {
      final customer = _customerCache[enquiry.customerId];

      final product = enquiry.product.toLowerCase();
      final description = enquiry.description.toLowerCase();
      final customerName = customer?.name.toLowerCase() ?? '';
      final customerMobile = customer?.mobileNumber.toLowerCase() ?? '';
      final customerAddress = customer?.address.toLowerCase() ?? '';

      return product.contains(searchTerm) ||
          description.contains(searchTerm) ||
          customerName.contains(searchTerm) ||
          customerMobile.contains(searchTerm) ||
          customerAddress.contains(searchTerm);
    }).toList();
  }

  Widget _buildEnquiryCard(EnquiryModel enquiry, CustomerModel? customer, UserModel? salesman) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: StatusIcon(status: enquiry.status),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (customer != null)
              _buildCustomerNameWithMobile(customer),
            const SizedBox(height: 4),
            _buildProductInfo(enquiry),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            if (salesman != null && _shouldShowSalesman(salesman))
              _buildSalesmanInfo(salesman),
            const SizedBox(height: 4),
            _buildDatesInfo(enquiry),
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => _navigateToEnquiryDetail(context, enquiry),
      ),
    );
  }

  bool _shouldShowSalesman(UserModel salesman) {
    return salesman.role == 'manager' || salesman.role == 'owner';
  }

  Widget _buildCustomerNameWithMobile(CustomerModel customer) {
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: customer.name,
            style: const TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          TextSpan(
            text: ' (${customer.mobileNumber})',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontStyle: FontStyle.italic,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductInfo(EnquiryModel enquiry) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            children: [
              const TextSpan(
                text: 'Product: ',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              TextSpan(
                text: enquiry.product,
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 2),
        _buildHighlightedText(
          enquiry.description,
          widget.searchQuery,
        ),
      ],
    );
  }

  Widget _buildSalesmanInfo(UserModel salesman) {
    return RichText(
      text: TextSpan(
        children: [
          const TextSpan(
            text: 'Assigned to: ',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 11,
            ),
          ),
          TextSpan(
            text: '${salesman.name} (${salesman.role})',
            style: TextStyle(
              color: Colors.blue.shade700,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDatesInfo(EnquiryModel enquiry) {
    return Row(
      children: [
        Expanded(
          child: RichText(
            text: TextSpan(
              children: [
                const TextSpan(
                  text: 'Created: ',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 10,
                  ),
                ),
                TextSpan(
                  text: DateUtilHelper.formatDate(enquiry.createdAt),
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              children: [
                const TextSpan(
                  text: 'Updated: ',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 10,
                  ),
                ),
                TextSpan(
                  text: DateUtilHelper.formatDate(enquiry.updatedAt),
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHighlightedText(
      String text,
      String query, {
        bool isTitle = false,
      }) {
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

  void _navigateToEnquiryDetail(BuildContext context, EnquiryModel enquiry) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EnquiryDetailScreen(
          enquiryId: enquiry.enquiryId,
          organizationId: widget.organizationId,
          isSalesman: widget.salesmanId != null,
        ),
      ),
    );
  }
}