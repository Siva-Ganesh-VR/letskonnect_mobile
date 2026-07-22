import 'dart:convert';
import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../core/app_helpers.dart';
import '../core/api_client.dart';
import '../core/refresh_notifier.dart';
import '../widgets/lead_card.dart';
import 'home_screen.dart';
import 'lead_detail_screen.dart';
import 'manual_add_visitor_screen.dart';

class LeadsScreen extends StatefulWidget {
  const LeadsScreen({super.key});

  @override
  State<LeadsScreen> createState() => _LeadsScreenState();
}

class _LeadsScreenState extends State<LeadsScreen> {
  List<dynamic> _leads = [];
  List<dynamic> _filtered = [];
  bool _loading = true;
  String _activeFilter = 'all';
  final _searchCtrl = TextEditingController();

  final _filters = [
    'all',
    'favorite',
    'hot',
    'warm',
    'cold',
    'contacted',
    'interested',
    'follow_up',
    'converted',
    'lost'
  ];

  @override
  void initState() {
    super.initState();
    _loadLeads();
    RefreshNotifier.leadsRefresh.addListener(_loadLeads);
  }

  @override
  void dispose() {
    RefreshNotifier.leadsRefresh.removeListener(_loadLeads);
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadLeads() async {
    if (!mounted) return;
    setState(() => _loading = true);

    // 1. Load the events first using the dashboard endpoint
    final dashResult = await ApiClient.call(
          () => ApiClient.dio.get('/api/v1/stall_owner/dashboard'),
    );

    List<dynamic> allAggregatedLeads = [];

    if (dashResult.success && dashResult.data is Map && dashResult.data['events'] is List) {
      final events = dashResult.data['events'] as List<dynamic>;

      // 2. Prepare API calls for every event in the array
      final leadRequests = events.map((event) {
        final eventId = event['id'].toString();
        return ApiClient.call(
              () => ApiClient.dio.get('/api/v1/stall_owner/leads',
              queryParameters: {'event_id': eventId, 'per_page': 1000}),
        );
      }).toList();

      // 3. Wait for all API requests to complete
      final results = await Future.wait(leadRequests);

      // 4. Merge all returned lead lists into one list
      for (var res in results) {
        if (res.success && res.data is List) {
          allAggregatedLeads.addAll(res.data as List<dynamic>);
        }
      }

      // 5. Remove duplicate leads using the lead id
      final seenIds = <dynamic>{};
      final uniqueLeads = <dynamic>[];
      for (var lead in allAggregatedLeads) {
        if (!seenIds.contains(lead['id'])) {
          uniqueLeads.add(lead);
          seenIds.add(lead['id']);
        }
      }
      _leads = uniqueLeads;

      // 6. Sort the merged list by scanned_at descending (latest first)
      _leads.sort((a, b) {
        final aTime = DateTime.tryParse(a['scanned_at'] ?? '') ?? DateTime(0);
        final bTime = DateTime.tryParse(b['scanned_at'] ?? '') ?? DateTime(0);
        return bTime.compareTo(aTime);
      });

      _applyFilter();
    }

    if (mounted) setState(() => _loading = false);
  }

  String _getLeadTag(Map<String, dynamic> lead) => AppHelpers.getLeadTag(lead);

  void _applyFilter() {
    final query = _searchCtrl.text.toLowerCase();
    setState(() {
      _filtered = _leads.where((lead) {
        bool matchFilter = true;
        if (_activeFilter == 'favorite') {
          matchFilter = lead['is_favorite'] == true;
        } else if (_activeFilter != 'all') {
          matchFilter = _getLeadTag(lead) == _activeFilter;
        }

        final visitor = lead['visitor'] ?? {};
        final matchSearch = query.isEmpty ||
            (visitor['full_name'] ?? '').toLowerCase().contains(query) ||
            (visitor['business_name'] ?? '').toLowerCase().contains(query);
        return matchFilter && matchSearch;
      }).toList();
    });
  }

  String _statusLabel(Map<String, dynamic> lead) =>
      AppHelpers.statusLabelFromLead(lead);

  String _toTitleCase(String text) => AppHelpers.toTitleCase(text);

  void _showEventsDialog(String visitorName, Map<String, dynamic> lead) {
    final eventName = lead['event_name'] ?? 'Event';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Events - $visitorName',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Current Event',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF64748B))),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('• ', style: TextStyle(fontWeight: FontWeight.w900)),
                Expanded(
                  child: Text(eventName,
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF0F172A))),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child:
            const Text('OK', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            HomeScreen.of(context)?.setTab(0);
          },
        ),
        title: const Text('My Leads',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        actions: [
          OutlinedButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ManualAddVisitorScreen()),
            ).then((_) => _loadLeads()),
            icon: const Icon(Icons.add, color: Colors.white, size: 18),
            label: const Text('Add Lead',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600)),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.white, width: 1.5),
              shape: const StadiumBorder(),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
              minimumSize: const Size(0, 36),
            ),
          ),
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadLeads,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (_) => _applyFilter(),
              decoration: InputDecoration(
                hintText: 'Search name or company...',
                filled: true,
                fillColor: Colors.white,
                contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                prefixIcon: const Icon(Icons.search_rounded,
                    color: Color(0xFF94A3B8)),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear_rounded,
                      color: Color(0xFF94A3B8)),
                  onPressed: () {
                    _searchCtrl.clear();
                    _applyFilter();
                  },
                )
                    : null,
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
                  borderSide:
                  const BorderSide(color: AppColors.primary, width: 2),
                ),
              ),
            ),
          ),

          // Filter chips
          SizedBox(
            height: 52,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              children: _filters.map((f) {
                final active = _activeFilter == f;
                return GestureDetector(
                  onTap: () {
                    final isFavorite = f == 'favorite';
                    setState(() {
                      if (active && f != 'all') {
                        _activeFilter = 'all';
                      } else {
                        _activeFilter = f;
                      }
                    });
                    if (isFavorite) {
                      _loadLeads();
                    } else {
                      _applyFilter();
                    }
                  },
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: active ? AppColors.primary : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: active
                              ? AppColors.primary
                              : const Color(0xFFE2E8F0)),
                    ),
                    child: Text(
                      f == 'all'
                          ? 'All'
                          : f == 'favorite'
                          ? 'Favorite'
                          : _statusLabel({
                        'status': ['hot', 'warm', 'cold'].contains(f)
                            ? 'new'
                            : f,
                        'temperature': f
                      }),
                      style: TextStyle(
                        color: active
                            ? Colors.white
                            : const Color(0xFF64748B),
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          // List
          Expanded(
            child: _loading
                ? const Center(
                child: CircularProgressIndicator(
                    color: AppColors.primary))
                : _filtered.isEmpty
                ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.people_alt_outlined,
                      size: 48, color: Color(0xFFE2E8F0)),
                  const SizedBox(height: 12),
                  Text(_activeFilter == 'favorite' ? 'No favorite leads found' : 'No leads found',
                      style: const TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 15)),
                ],
              ),
            )
                : RefreshIndicator(
              color: AppColors.primary,
              onRefresh: _loadLeads,
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: _filtered.length,
                separatorBuilder: (_, __) =>
                const SizedBox(height: 8),
                itemBuilder: (_, i) {
                  final lead = _filtered[i];
                  final visitor = lead['visitor'] ?? {};
                  final name = _toTitleCase(visitor['full_name'] ?? 'Unknown');

                  return LeadCard(
                    lead: lead,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => LeadDetailScreen(
                              leadId: lead['id'].toString(),
                              eventId: lead['event_id']?.toString())),
                    ).then((_) => _loadLeads()),
                    onMoreTap: () => _showEventsDialog(name, lead),
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