import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/app_colors.dart';
import '../core/app_helpers.dart';
import '../core/api_client.dart';
import '../core/refresh_notifier.dart';

class LeadDetailScreen extends StatefulWidget {
  final String leadId;
  const LeadDetailScreen({super.key, required this.leadId});

  @override
  State<LeadDetailScreen> createState() => _LeadDetailScreenState();
}

class _LeadDetailScreenState extends State<LeadDetailScreen> {
  Map<String, dynamic>? _visitor;
  Map<String, dynamic>? _lead;
  bool _loading = true;
  bool _saving = false;
  bool _loadFailed = false;

  String _temperature = 'warm';
  String _status = 'new';
  int _interestRating = 3;
  bool _isFavorite = false;
  final _notesCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadFailed = false;
    });
    final result = await ApiClient.call(
            () => ApiClient.dio.get('/api/v1/stall_owner/leads/${widget.leadId}'));
    if (result.success) {
      final data = result.data as Map<String, dynamic>;
      _lead = data;
      _visitor = data['visitor'] as Map<String, dynamic>?;
      _temperature = data['temperature'] ?? 'warm';
      _status = data['status'] ?? 'new';
      _interestRating = data['interest_rating'] ?? 3;
      _isFavorite = data['is_favorite'] == true;
      _notesCtrl.text = data['notes'] ?? '';
    } else {
      _loadFailed = true;
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    
    final Map<String, dynamic> leadData = {
      'temperature': _temperature.isEmpty ? null : _temperature,
      'status': _status,
      'interest_rating': _interestRating,
      'notes': _notesCtrl.text,
    };

    final requestBody = {'lead': leadData};

    if (kDebugMode) {
      print('==========================');
      print('PATCH REQUEST (Manual Save)');
      print('==========================');
      print('URL: ${ApiClient.baseUrl}/api/v1/stall_owner/leads/${widget.leadId}');
      print('HTTP Method: PATCH');
      print('Content-Type: application/json');
      print('Values being sent:');
      print('- temperature: ${_temperature.isEmpty ? 'null' : _temperature}');
      print('- status: $_status');
      print('- interest_rating: $_interestRating');
      print('Request Body (exact JSON):');
      print(jsonEncode(requestBody));
      print('==========================');
    }

    final result = await ApiClient.call(() => ApiClient.dio.patch(
      '/api/v1/stall_owner/leads/${widget.leadId}',
      data: requestBody,
    ));

    if (kDebugMode) {
      print('==========================');
      print('PATCH RESPONSE (Manual Save)');
      print('==========================');
      print('Status Code: ${result.success ? '2xx' : 'Error'}');
      print('Raw Response Body: ${result.data}');
      if (result.error != null) print('Error: ${result.error}');
      print('==========================');
    }

    setState(() => _saving = false);
    if (!mounted) return;
    if (result.success) {
      RefreshNotifier.refreshLeads();
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lead updated successfully')));
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(result.error ?? 'Failed to save'),
          backgroundColor: Colors.red.shade600));
    }
  }

  Future<void> _sendWhatsapp() async {
    final rawMobile = _visitor?['mobile_number']?.toString() ?? '';
    if (rawMobile.isEmpty) return;

    // Clean mobile number (only digits)
    final mobile = rawMobile.replaceAll(RegExp(r'[^0-9]'), '');
    final phone = mobile.length == 10 ? '91$mobile' : mobile;

    final name = _visitor?['full_name'] ?? '';
    final message = 'Hi $name,\nThank you for visiting our stall. Please let us know if you have any questions.';
    final uri = Uri.parse('https://wa.me/$phone?text=${Uri.encodeComponent(message)}');

    try {
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('WhatsApp is not installed.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('WhatsApp is not installed.')),
        );
      }
    }
  }

  void _openPastEvents() async {
    final eventJson = await ApiClient.getEventJson();
    Map<String, dynamic>? event;
    if (eventJson != null) {
      try {
        event = jsonDecode(eventJson);
      } catch (_) {}
    }

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Current Event',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (event != null) ...[
              Text(event['name'] ?? 'Event Details',
                  style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: Color(0xFF0F172A))),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.calendar_today_rounded,
                      size: 14, color: Color(0xFF64748B)),
                  const SizedBox(width: 8),
                  Text(
                    'Start: ${_formatDate(event['start_date'])}',
                    style:
                        const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                  ),
                ],
              ),
              if (event['end_date'] != null) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.calendar_today_rounded,
                        size: 14, color: Color(0xFF64748B)),
                    const SizedBox(width: 8),
                    Text(
                      'End: ${_formatDate(event['end_date'])}',
                      style: const TextStyle(
                          fontSize: 13, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 12),
              const Text(
                'Visitor event history is not yet available.',
                style: TextStyle(
                    fontSize: 11,
                    color: Color(0xFF94A3B8),
                    fontStyle: FontStyle.italic),
              ),
            ] else
              const Text('Event details are currently unavailable.',
                  style: TextStyle(color: Color(0xFF64748B), fontSize: 14)),
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

  Future<void> _callNumber() async {
    final rawMobile = _visitor?['mobile_number']?.toString() ?? '';
    if (rawMobile.isEmpty) return;
    final mobile = rawMobile.replaceAll(RegExp(r'[^0-9]'), '');
    final uri = Uri(scheme: 'tel', path: mobile);
    try {
      await launchUrl(uri);
    } catch (_) {}
  }

  Future<void> _addNote() async {
    final ctrl = TextEditingController(text: _notesCtrl.text);
    final result = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.note_add_rounded,
                  color: AppColors.primary, size: 18),
            ),
            const SizedBox(width: 10),
            const Text('Add Note'),
          ],
        ),
        content: TextField(
          controller: ctrl,
          maxLines: 4,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'What did you discuss?'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, ctrl.text),
            child: const Text('Save Note'),
          ),
        ],
      ),
    );
    if (result == null) return;
    setState(() {
      _notesCtrl.text = result;
      _saving = true;
    });

    final requestBody = {'lead': {'notes': result}};

    if (kDebugMode) {
      print('==========================');
      print('PATCH REQUEST (Add Note)');
      print('==========================');
      print('URL: ${ApiClient.baseUrl}/api/v1/stall_owner/leads/${widget.leadId}');
      print('HTTP Method: PATCH');
      print('Content-Type: application/json');
      print('Request Body (exact JSON):');
      print(jsonEncode(requestBody));
      print('==========================');
    }

    final patchResult = await ApiClient.call(() => ApiClient.dio.patch(
      '/api/v1/stall_owner/leads/${widget.leadId}',
      data: requestBody,
    ));

    if (kDebugMode) {
      print('==========================');
      print('PATCH RESPONSE (Add Note)');
      print('==========================');
      print('Status Code: ${patchResult.success ? '2xx' : 'Error'}');
      print('Raw Response Body: ${patchResult.data}');
      if (patchResult.error != null) print('Error: ${patchResult.error}');
      print('==========================');
    }

    if (patchResult.success && patchResult.data != null) {
      _lead = patchResult.data as Map<String, dynamic>;
    }
    if (mounted) {
      setState(() => _saving = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Note saved')));
    }
  }


  String _initials(String name) => AppHelpers.initials(name);

  String _formatDate(String? iso) => AppHelpers.formatDate(iso);

  String _timeAgo(String? iso) => AppHelpers.timeAgo(iso);

  Future<void> _updateTag({String? temp, String? status, int? rating, bool? favorite}) async {
    final Map<String, dynamic> changedFields = {};

    setState(() {
      _saving = true;
      if (temp != null) {
        _temperature = temp;
        changedFields['temperature'] = temp;
      }
      if (status != null) {
        _status = status;
        changedFields['status'] = status;
      }
      if (rating != null) {
        _interestRating = rating;
        changedFields['interest_rating'] = rating;
      }
      if (favorite != null) {
        _isFavorite = favorite;
        changedFields['is_favorite'] = favorite;
      }
    });

    if (changedFields.isEmpty) {
      if (mounted) setState(() => _saving = false);
      return;
    }

    ApiResult result;
    if (favorite != null) {
      // Use the specific toggle_favorite endpoint for favorites
      result = await ApiClient.call(() => ApiClient.dio.patch(
        '/api/v1/stall_owner/leads/${widget.leadId}/toggle_favorite',
      ));
    } else {
      // Use the normal update endpoint for other fields
      final requestBody = {'lead': changedFields};
      result = await ApiClient.call(() => ApiClient.dio.patch(
        '/api/v1/stall_owner/leads/${widget.leadId}',
        data: requestBody,
      ));
    }

    if (result.success && result.data != null) {
      if (favorite != null) {
        // toggle_favorite returns { success: true, data: { is_favorite: bool, ... } }
        _isFavorite = result.data['is_favorite'] == true;
      } else {
        // Normal update returns the full updated lead object
        _lead = result.data as Map<String, dynamic>;
        _visitor = _lead!['visitor'] as Map<String, dynamic>?;
      }
      RefreshNotifier.refreshLeads();
    } else if (!result.success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(result.error ?? 'Update failed'),
            backgroundColor: Colors.red.shade600));
      }
    }

    if (mounted) setState(() => _saving = false);
  }

  String _toTitleCase(String text) => AppHelpers.toTitleCase(text);

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
          backgroundColor: Color(0xFFF8FAFC),
          body: Center(
              child: CircularProgressIndicator(color: AppColors.primary)));
    }
    if (_loadFailed || _visitor == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Lead Details')),
        body: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('Could not load this lead'),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: _load, child: const Text('Retry')),
          ]),
        ),
      );
    }

    final name = _toTitleCase(_visitor!['full_name'] ?? 'Unknown');
    final company = _visitor!['business_name'] ?? '';
    final mobile = _visitor!['mobile_number']?.toString() ?? '';
    final email = _visitor!['email']?.toString() ?? '';
    final location = _visitor!['location']?.toString() ?? '';
    final profession = _visitor!['profession']?.toString() ?? '';
    final businessCategory = _visitor!['business_category']?.toString() ?? '';
    final designation = _visitor!['designation']?.toString() ?? '';
    final scannedAt = _lead?['scanned_at'];
    final statusColor = AppColors.statusColor(_status);
    final isStarred = _isFavorite;

    // Logic for single selection of tags (Warm or Interested)
    // We treat 'warm' temperature and 'interested' status as the two selectable tags.
    final bool isWarm = _temperature == 'warm';
    final bool isInterested = _status == 'interested';

    return PopScope(
      canPop: !_saving,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please wait while saving...')),
        );
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          title: const Text('Lead Details'),
          actions: [
            if (_saving)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  ),
                ),
              )
            else
              IconButton(
                icon: const Icon(Icons.check_rounded),
                onPressed: _save,
              ),
          ],
        ),
        body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── Header card with overlapping star ─────────────
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 2))
                    ],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: const BoxDecoration(
                          color: Color(0xFF0D9488),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            _initials(name),
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 22),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(name,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 18,
                                          color: Color(0xFF0F172A))),
                                ),
                                GestureDetector(
                                  onTap: _openPastEvents,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: AppColors.accent.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: AppColors.accent.withOpacity(0.2)),
                                    ),
                                    child: const Row(
                                      children: [
                                        Icon(Icons.history_rounded, size: 14, color: AppColors.accent),
                                        SizedBox(width: 4),
                                        Text('Past Events', 
                                          style: TextStyle(
                                            fontSize: 11, 
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.accent
                                          )
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                if (company.isNotEmpty)
                                  Flexible(
                                    child: Text(company,
                                        style: const TextStyle(
                                            color: Color(0xFF64748B),
                                            fontSize: 13)),
                                  ),
                                if (company.isNotEmpty)
                                  const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: statusColor.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    AppColors.statusLabel(_status),
                                    style: TextStyle(
                                        color: statusColor,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800),
                                  ),
                                ),
                              ],
                            ),
                            if (scannedAt != null) ...[
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  const Icon(Icons.access_time_rounded,
                                      size: 12, color: Color(0xFF94A3B8)),
                                  const SizedBox(width: 4),
                                  Flexible(
                                    child: Text(
                                      '${_timeAgo(scannedAt)}  •  ${_formatDate(scannedAt)}',
                                      style: const TextStyle(
                                          fontSize: 11,
                                          color: Color(0xFF94A3B8)),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 32),
                    ],
                  ),
                ),
                // Star overlapping top-right corner
                Positioned(
                  top: -10,
                  right: -4,
                  child: GestureDetector(
                    onTap: () => _updateTag(favorite: !isStarred),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isStarred
                            ? const Color(0xFFF59E0B)
                            : Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isStarred
                              ? const Color(0xFFF59E0B)
                              : const Color(0xFFE2E8F0),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: isStarred
                                ? const Color(0xFFF59E0B).withOpacity(0.4)
                                : Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        isStarred
                            ? Icons.star_rounded
                            : Icons.star_border_rounded,
                        color: isStarred
                            ? Colors.white
                            : const Color(0xFF94A3B8),
                        size: 22,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // ── Contact card ──────────────────────────────────
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2))
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (mobile.isNotEmpty)
                    _contactRow(
                      label: 'Mobile Number',
                      icon: Icons.phone_rounded,
                      iconBg: AppColors.primary.withOpacity(0.1),
                      iconColor: AppColors.primary,
                      text: '+91 $mobile',
                      trailing: _whatsappButton(onTap: _sendWhatsapp),
                      showDivider: true,
                    ),
                  if (location.isNotEmpty)
                    _contactRow(
                      label: 'Location',
                      icon: Icons.location_on_rounded,
                      iconBg: Colors.red.withOpacity(0.1),
                      iconColor: Colors.red,
                      text: location,
                      trailing: _actionCircle(
                        icon: Icons.map_outlined,
                        color: Colors.red,
                        onTap: () {},
                      ),
                      showDivider: email.isNotEmpty || profession.isNotEmpty || company.isNotEmpty || businessCategory.isNotEmpty || designation.isNotEmpty,
                    ),
                  if (email.isNotEmpty)
                    _contactRow(
                      label: 'Email',
                      icon: Icons.email_outlined,
                      iconBg: AppColors.accent.withOpacity(0.1),
                      iconColor: AppColors.accent,
                      text: email,
                      trailing: _actionCircle(
                        icon: Icons.mail_outline_rounded,
                        color: AppColors.accent,
                        onTap: () async {
                          final uri = Uri(scheme: 'mailto', path: email);
                          try {
                            await launchUrl(uri);
                          } catch (_) {}
                        },
                      ),
                      showDivider: profession.isNotEmpty || company.isNotEmpty || businessCategory.isNotEmpty || designation.isNotEmpty,
                    ),
                  if (profession.isNotEmpty)
                    _contactRow(
                      label: 'Profession',
                      icon: Icons.work_outline_rounded,
                      iconBg: Colors.indigo.withOpacity(0.1),
                      iconColor: Colors.indigo,
                      text: profession,
                      trailing: const SizedBox.shrink(),
                      showDivider: company.isNotEmpty || businessCategory.isNotEmpty || designation.isNotEmpty,
                    ),
                  if (company.isNotEmpty)
                    _contactRow(
                      label: 'Business Name',
                      icon: Icons.business_rounded,
                      iconBg: Colors.blue.withOpacity(0.1),
                      iconColor: Colors.blue,
                      text: company,
                      trailing: const SizedBox.shrink(),
                      showDivider: businessCategory.isNotEmpty || designation.isNotEmpty,
                    ),
                  if (businessCategory.isNotEmpty)
                    _contactRow(
                      label: 'Business Category',
                      icon: Icons.category_outlined,
                      iconBg: Colors.purple.withOpacity(0.1),
                      iconColor: Colors.purple,
                      text: businessCategory,
                      trailing: const SizedBox.shrink(),
                      showDivider: designation.isNotEmpty,
                    ),
                  if (designation.isNotEmpty)
                    _contactRow(
                      label: 'Designation',
                      icon: Icons.badge_outlined,
                      iconBg: Colors.orange.withOpacity(0.1),
                      iconColor: Colors.orange,
                      text: designation,
                      trailing: const SizedBox.shrink(),
                      showDivider: false,
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // ── Notes + Tags combined card ─────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2))
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Notes header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: AppColors.accent.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.sticky_note_2_rounded,
                                color: AppColors.accent, size: 16),
                          ),
                          const SizedBox(width: 8),
                          const Text('Notes',
                              style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                  color: Color(0xFF0F172A))),
                        ],
                      ),
                      GestureDetector(
                        onTap: _addNote,
                        child: const Text('Add/Edit',
                            style: TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                                fontSize: 13)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _notesCtrl.text.isNotEmpty
                        ? _notesCtrl.text
                        : '', // Removed placeholder text
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.5,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Divider(height: 1, color: Color(0xFFE2E8F0)),
                  const SizedBox(height: 16),

                  // Tags header
                  const Text('Tags',
                      style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: Color(0xFF0F172A))),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      // Temperature Tags
                      ...['hot', 'warm', 'cold'].map((t) {
                        final bool isSelected = _temperature == t && (_status == 'new' || _status == '');
                        return GestureDetector(
                          onTap: () => _updateTag(temp: t),
                          child: _tagChip(
                            label: t[0].toUpperCase() + t.substring(1),
                            color: AppColors.temperatureColor(t),
                            selected: isSelected,
                          ),
                        );
                      }),
                      // Status Tags
                      ...['contacted', 'interested', 'follow_up', 'converted', 'lost'].map((s) {
                        final bool isSelected = _status == s;
                        return GestureDetector(
                          onTap: () => _updateTag(status: s),
                          child: _tagChip(
                            label: AppColors.statusLabel(s),
                            color: AppColors.statusColor(s),
                            selected: isSelected,
                          ),
                        );
                      }),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),

      // ── Bottom action bar ─────────────────────────────────
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 12,
                  offset: const Offset(0, -2))
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: _sendWhatsapp,
                      icon: const Icon(Icons.chat_rounded, size: 18),
                      label: const Text('WhatsApp'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF25D366),
                        foregroundColor: Colors.white,
                        minimumSize: const Size(0, 52),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        textStyle: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 15),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _callNumber,
                      icon: const Icon(Icons.call_rounded, size: 18),
                      label: const Text('Call'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF0F172A),
                        minimumSize: const Size(0, 52),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        side: const BorderSide(color: Color(0xFFE2E8F0)),
                        textStyle: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 15),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
    );
  }

  Widget _tagChip({
    required String label,
    required Color color,
    required bool selected,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: selected
            ? color.withOpacity(0.12)
            : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(20),
        border:
        Border.all(color: selected ? color : const Color(0xFFE2E8F0)),
      ),
      child: Text(
        label,
        style: TextStyle(
            color: selected ? color : const Color(0xFF64748B),
            fontWeight: FontWeight.w600,
            fontSize: 13),
      ),
    );
  }

  Widget _contactRow({
    String? label,
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String text,
    required Widget trailing,
    required bool showDivider,
  }) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration:
                BoxDecoration(color: iconBg, shape: BoxShape.circle),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (label != null)
                      Text(label,
                          style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF64748B),
                              fontWeight: FontWeight.w500)),
                    if (label != null) const SizedBox(height: 2),
                    Text(text,
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF0F172A))),
                  ],
                ),
              ),
              trailing,
            ],
          ),
        ),
        if (showDivider)
          const Divider(
              height: 1,
              indent: 16,
              endIndent: 16,
              color: Color(0xFFE2E8F0)),
      ],
    );
  }

  Widget _whatsappButton({required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: const BoxDecoration(
          color: Color(0xFF25D366),
          shape: BoxShape.circle,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
            const Icon(Icons.phone_rounded,
                color: Color(0xFF25D366), size: 16),
          ],
        ),
      ),
    );
  }

  Widget _actionCircle({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }

}
