import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../core/app_helpers.dart';
import '../core/api_client.dart';
import 'event_leads_screen.dart';

class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  List<dynamic> _allEvents = [];
  List<dynamic> _displayEvents = [];
  bool _loading = true;
  bool _error = false;
  String _searchQuery = '';
  String _selectedFilter = 'All';

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadEvents() async {
    setState(() {
      _loading = true;
      _error = false;
    });
    final result = await ApiClient.call(
      () => ApiClient.dio.get('/api/v1/stall_owner/dashboard'),
    );
    if (result.success && result.data is Map && result.data['events'] is List) {
      _allEvents = result.data['events'] as List<dynamic>;

      // Sort events by start_date descending (latest first)
      AppHelpers.sortEvents(_allEvents);

      _applyFilters();
    } else {
      _error = true;
    }
    if (mounted) setState(() => _loading = false);
  }

  void _applyFilters() {
    setState(() {
      _displayEvents = _allEvents.where((event) {
        final name = (event['name'] ?? '').toString().toLowerCase();
        final venue = (event['venue'] ?? '').toString().toLowerCase();
        final status = (event['status'] ?? '').toString().toLowerCase();
        
        final matchesSearch = name.contains(_searchQuery.toLowerCase()) || 
                             venue.contains(_searchQuery.toLowerCase());
        
        bool matchesFilter = true;
        if (_selectedFilter != 'All') {
          matchesFilter = status == _selectedFilter.toLowerCase();
        }

        return matchesSearch && matchesFilter;
      }).toList();
    });
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Filter Events',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: ['All', 'Upcoming', 'Ongoing', 'Completed'].map((filter) {
                  final isSelected = _selectedFilter == filter;
                  return GestureDetector(
                    onTap: () {
                      setState(() => _selectedFilter = filter);
                      _applyFilters();
                      Navigator.pop(context);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primary : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: isSelected ? AppColors.primary : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Text(
                        filter,
                        style: TextStyle(
                          color: isSelected ? Colors.white : const Color(0xFF64748B),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 32),
            ],
          ),
        );
      },
    );
  }

  String _formatDateRange(String? start, String? end) =>
      AppHelpers.formatDateRange(start, end);

  Widget _buildStatusBadge(String status) {
    Color color;
    Color bgColor;
    
    switch (status.toLowerCase()) {
      case 'upcoming':
        color = const Color(0xFF10B981);
        bgColor = const Color(0xFFECFDF5);
        break;
      case 'ongoing':
        color = const Color(0xFF3B82F6);
        bgColor = const Color(0xFFEFF6FF);
        break;
      case 'completed':
        color = const Color(0xFF64748B);
        bgColor = const Color(0xFFF1F5F9);
        break;
      default:
        color = const Color(0xFF64748B);
        bgColor = const Color(0xFFF1F5F9);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(32),
      ),
      child: Text(
        status[0].toUpperCase() + status.substring(1),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  String _initials(String name) => AppHelpers.initials(name);

  Color _avatarColor(String name) => AppHelpers.avatarColor(name);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          // Header with search
          Container(
            padding: const EdgeInsets.fromLTRB(20, 60, 20, 24),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF14B8A6), Color(0xFF0F766E)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Events',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onChanged: (val) {
                          setState(() => _searchQuery = val);
                          _applyFilters();
                        },
                        decoration: InputDecoration(
                          hintText: 'Search events...',
                          hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF94A3B8)),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppColors.primary, width: 2),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: _showFilterBottomSheet,
                      child: Container(
                        height: 48,
                        width: 48,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            const Icon(Icons.tune_rounded, color: AppColors.primary),
                            if (_selectedFilter != 'All')
                              Positioned(
                                top: 12,
                                right: 12,
                                child: Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFF59E0B),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : _error
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.error_outline_rounded, size: 48, color: Colors.redAccent),
                            const SizedBox(height: 16),
                            const Text('Failed to load events'),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _loadEvents,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : _displayEvents.isEmpty
                        ? const Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.event_busy_rounded, size: 48, color: Color(0xFFE2E8F0)),
                                SizedBox(height: 12),
                                Text('No events found', style: TextStyle(color: Color(0xFF94A3B8))),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            color: AppColors.primary,
                            onRefresh: _loadEvents,
                            child: ListView.separated(
                              padding: const EdgeInsets.all(20),
                              itemCount: _displayEvents.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 16),
                              itemBuilder: (context, index) {
                                final event = _displayEvents[index];
                                final id = event['id'].toString();
                                final name = event['name'] ?? 'Event Name';
                                final status = event['status'] ?? 'upcoming';
                                final stallNo = event['stall_number'];
                                final totalLeads = event['total_leads'] ?? 0;

                                return GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => EventLeadsScreen(
                                          eventId: id,
                                          eventName: name,
                                        ),
                                      ),
                                    );
                                  },
                                  child: Container(
                                    height: 140,
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(24),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.04),
                                          blurRadius: 16,
                                          offset: const Offset(0, 6),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      children: [
                                        // Left: Avatar
                                        CircleAvatar(
                                          radius: 36,
                                          backgroundColor: _avatarColor(name),
                                          child: Text(
                                            _initials(name),
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 24,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        // Right: Info
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              _buildStatusBadge(status),
                                              const SizedBox(height: 6),
                                              Text(
                                                name,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w800,
                                                  color: Color(0xFF0F172A),
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Row(
                                                children: [
                                                  const Icon(Icons.calendar_today_rounded, size: 13, color: Color(0xFF94A3B8)),
                                                  const SizedBox(width: 8),
                                                  Expanded(
                                                    child: Text(
                                                      _formatDateRange(event['start_date'], event['end_date']),
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                      style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const Spacer(),
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Text(
                                                    'Booth: ${stallNo ?? "-"}',
                                                    style: const TextStyle(
                                                      color: Color(0xFF10B981),
                                                      fontSize: 12,
                                                      fontWeight: FontWeight.w800,
                                                    ),
                                                  ),
                                                  Padding(
                                                    padding: const EdgeInsets.only(right: 8),
                                                    child: Text(
                                                      'Total Leads: $totalLeads',
                                                      style: const TextStyle(
                                                        color: Color(0xFF64748B),
                                                        fontSize: 12,
                                                        fontWeight: FontWeight.w700,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                        // Arrow
                                        const SizedBox(width: 8),
                                        Container(
                                          width: 32,
                                          height: 32,
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFF8FAFC),
                                            shape: BoxShape.circle,
                                            border: Border.all(color: const Color(0xFFE2E8F0)),
                                          ),
                                          child: const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Color(0xFF64748B)),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}
