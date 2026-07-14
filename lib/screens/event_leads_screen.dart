import 'dart:convert';
import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../core/api_client.dart';
import '../core/refresh_notifier.dart';
import '../widgets/lead_card.dart';
import 'home_screen.dart';
import 'lead_detail_screen.dart';
import 'manual_add_visitor_screen.dart';

class EventLeadsScreen extends StatefulWidget {
  final String eventId;
  final String eventName;
  const EventLeadsScreen({super.key, required this.eventId, required this.eventName});

  @override
  State<EventLeadsScreen> createState() => _EventLeadsScreenState();
}

class _EventLeadsScreenState extends State<EventLeadsScreen> {
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
    _loadData();
    RefreshNotifier.leadsRefresh.addListener(_loadData);
  }

  @override
  void dispose() {
    RefreshNotifier.leadsRefresh.removeListener(_loadData);
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _loading = true);

    print('DEBUG: EventLeadsScreen _loadData started');
    print('DEBUG: widget.eventId = ${widget.eventId}');
    print('DEBUG: widget.eventName = ${widget.eventName}');

    final queryParams = {
      'event_id': widget.eventId,
      'per_page': 1000
    };

    final result = await ApiClient.call(
      () => ApiClient.dio.get('/api/v1/stall_owner/leads', queryParameters: queryParams),
    );

    print('DEBUG: API Request finished');
    print('DEBUG: Endpoint = /api/v1/stall_owner/leads');
    print('DEBUG: Query Params = $queryParams');
    print('DEBUG: result.success = ${result.success}');
    print('DEBUG: result.error = ${result.error}');
    print('DEBUG: result.data type = ${result.data.runtimeType}');

    if (result.success && result.data is List) {
      _leads = result.data as List<dynamic>;
      print('DEBUG: result.data.length = ${_leads.length}');
      _applyFilter();
    } else {
      print('DEBUG: result.data = ${result.data}');
    }

    if (mounted) setState(() => _loading = false);
  }

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

  String _getLeadTag(Map<String, dynamic> lead) {
    final status = lead['status'] ?? 'new';
    if (status == 'new' || status == '') {
      return lead['temperature'] ?? 'warm';
    }
    return status;
  }

  String _statusLabel(Map<String, dynamic> lead) {
    final tag = _getLeadTag(lead);
    if (['hot', 'warm', 'cold'].contains(tag)) {
      return tag[0].toUpperCase() + tag.substring(1);
    }
    return AppColors.statusLabel(tag);
  }

  String _toTitleCase(String text) {
    if (text.isEmpty) return text;
    return text.toLowerCase().split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1);
    }).join(' ');
  }

  void _showEventsDialog(String visitorName) {
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
                  child: Text(widget.eventName,
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('${widget.eventName} Leads',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        actions: [
          OutlinedButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ManualAddVisitorScreen()),
            ).then((_) => _loadData()),
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
            onPressed: _loadData,
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
                      _loadData();
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
              onRefresh: _loadData,
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
                              leadId: lead['id'].toString())),
                    ).then((_) => _loadData()),
                    onMoreTap: () => _showEventsDialog(name),
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
