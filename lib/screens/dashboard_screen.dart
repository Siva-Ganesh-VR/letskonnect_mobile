import 'dart:convert';
import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../core/app_helpers.dart';
import '../core/api_client.dart';
import '../core/refresh_notifier.dart';
import 'event_leads_screen.dart';
import 'lead_detail_screen.dart';
import 'scanner_screen.dart';
import 'manual_add_visitor_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Map<String, dynamic>? _stallOwner;
  Map<String, dynamic>? _event;
  List<dynamic> _allLeads = [];
  bool _loading = true;
  bool _loadFailed = false;
  int _totalCount = 0;
  int _selectedDayOffset = 0;
  int _totalDays = 1;

  static final List<BoxShadow> _cardShadow = [
    BoxShadow(
      color: Colors.black.withOpacity(0.10),
      blurRadius: 28,
      offset: const Offset(0, 10),
    ),
  ];

  static final List<BoxShadow> _smallShadow = [
    BoxShadow(
      color: Colors.black.withOpacity(0.20),
      blurRadius: 16,
      offset: const Offset(0, 6),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _load();
    RefreshNotifier.leadsRefresh.addListener(_load);
  }

  @override
  void dispose() {
    RefreshNotifier.leadsRefresh.removeListener(_load);
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadFailed = false;
    });
    final stallJson = await ApiClient.getStallOwnerJson();
    if (stallJson != null) _stallOwner = jsonDecode(stallJson);

    final eventJson = await ApiClient.getEventJson();
    if (eventJson != null) _event = jsonDecode(eventJson);

    final result = await ApiClient.call(() => ApiClient.dio.get(
      '/api/v1/stall_owner/leads',
      queryParameters: {'per_page': 1000},
    ));
    if (result.success && result.data is List) {
      _allLeads = result.data as List<dynamic>;
      _totalCount = result.meta?['total'] ?? _allLeads.length;

      if (_event != null) {
        final start = DateTime.tryParse(_event!['start_date'] ?? '');
        final end = DateTime.tryParse(_event!['end_date'] ?? '');
        if (start != null && end != null) {
          _totalDays = end.difference(start).inDays + 1;
          if (_totalDays < 1) _totalDays = 1;

          final now = DateTime.now();
          final today = DateTime(now.year, now.month, now.day);
          final eventStartDay = DateTime(start.year, start.month, start.day);
          _selectedDayOffset = today.difference(eventStartDay).inDays;
          if (_selectedDayOffset < 0) _selectedDayOffset = 0;
          if (_selectedDayOffset >= _totalDays) _selectedDayOffset = _totalDays - 1;
        }
      }
    } else {
      _loadFailed = !result.success;
      _allLeads = [];
      _totalCount = 0;
    }
    if (mounted) setState(() => _loading = false);
  }

  String _greetingText() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good Morning';
    if (h < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  String _greetingEmoji() {
    final h = DateTime.now().hour;
    if (h < 12) return '👋';
    if (h < 17) return '☀️';
    return '🌙';
  }

  String _timeAgo(String? iso) => AppHelpers.timeAgo(iso);

  Color _avatarColor(String name) => AppHelpers.avatarColor(name);

  String _toTitleCase(String text) => AppHelpers.toTitleCase(text);

  void _openAllLeads() {
    if (_event == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EventLeadsScreen(
          eventId: _event!['id'].toString(),
          eventName: _event!['name'] ?? 'Event',
        ),
      ),
    ).then((_) => _load());
  }

  List<double> _getHourlyCounts() {
    if (_event == null) return List.filled(24, 0.0);
    final startStr = _event!['start_date'];
    if (startStr == null) return List.filled(24, 0.0);
    final start = DateTime.tryParse(startStr);
    if (start == null) return List.filled(24, 0.0);

    final targetDate = DateTime(start.year, start.month, start.day)
        .add(Duration(days: _selectedDayOffset));
    final counts = List.filled(24, 0.0);

    for (var lead in _allLeads) {
      final scannedAt = lead['scanned_at'];
      if (scannedAt == null) continue;
      final dt = DateTime.tryParse(scannedAt);
      if (dt == null) continue;

      if (dt.year == targetDate.year &&
          dt.month == targetDate.month &&
          dt.day == targetDate.day) {
        counts[dt.hour] += 1.0;
      }
    }
    return counts;
  }

  void _changeDay(int delta) {
    setState(() {
      _selectedDayOffset = (_selectedDayOffset + delta).clamp(0, _totalDays - 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final name = _stallOwner?['company_name'] ??
        _stallOwner?['name'] ??
        'Stall Owner';
    final stallNo = _stallOwner?['stall_number'] ?? '';
    final eventName = _event?['name'] ?? 'Event';

    // Calculate current day's date based on offset
    String displayDate = 'N/A';
    if (_event != null && _event!['start_date'] != null) {
      final start = DateTime.tryParse(_event!['start_date']);
      if (start != null) {
        final targetDate = start.add(Duration(days: _selectedDayOffset));
        final months = [
          '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
          'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
        ];
        displayDate = '${targetDate.day.toString().padLeft(2, '0')} ${months[targetDate.month]} ${targetDate.year}';
      }
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _load,
        child: _loading
            ? const Center(
            child: CircularProgressIndicator(color: AppColors.primary))
            : CustomScrollView(
          primary: false,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // ───────────── Header + floating stats card ─────────────
            SliverToBoxAdapter(
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    height: 185,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Color(0xFF2DE0CC),
                          Color(0xFF1AC2B0),
                          Color(0xFF0FA597),
                        ],
                        stops: [0.0, 0.55, 1.0],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Positioned.fill(
                          child: CustomPaint(
                            painter: _HeaderWavePainter(),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 38, 20, 0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                        '${_greetingText()} ${_greetingEmoji()}',
                                        style: const TextStyle(
                                            color: Colors.white70,
                                            fontSize: 14.5,
                                            fontWeight: FontWeight.w500)),
                                    const SizedBox(height: 6),
                                    Text(name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 20,
                                            letterSpacing: 0.1,
                                            fontWeight: FontWeight.w700)),
                                    const SizedBox(height: 9),
                                    if (stallNo.isNotEmpty)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.18),
                                          borderRadius: BorderRadius.circular(32),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Text('Stall No: ',
                                                style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w600)),
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                  horizontal: 9, vertical: 3),
                                              decoration: BoxDecoration(
                                                color: Colors.white.withOpacity(0.85),
                                                borderRadius: BorderRadius.circular(20),
                                              ),
                                              child: Text(stallNo,
                                                  style: const TextStyle(
                                                      color: Color(0xFF0F766E),
                                                      fontSize: 12,
                                                      fontWeight: FontWeight.w800)),
                                            ),
                                          ],
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  Positioned(
                    top: 140,
                    left: 14,
                    right: 14,
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: _cardShadow,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('$eventName Leads',
                                      style: const TextStyle(
                                          fontSize: 13.5,
                                          color: Color(0xFF475569),
                                          fontWeight: FontWeight.w700)),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  const Text('Event Date',
                                      style: TextStyle(
                                          fontSize: 10,
                                          color: Color(0xFF64748B),
                                          fontWeight: FontWeight.w600)),
                                  Text(displayDate,
                                      style: const TextStyle(
                                          color: Color(0xFF0EA89A),
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w700)),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('$_totalCount',
                                  style: const TextStyle(
                                      fontSize: 50,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF0EA89A),
                                      height: 1.0,
                                      letterSpacing: -0.5)),
                              Container(
                                margin: const EdgeInsets.only(bottom: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      visualDensity: VisualDensity.compact,
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      icon: Icon(Icons.arrow_left_rounded,
                                          color: _selectedDayOffset > 0
                                              ? AppColors.primary
                                              : Colors.grey.shade300),
                                      onPressed: _selectedDayOffset > 0
                                          ? () => _changeDay(-1)
                                          : null,
                                    ),
                                    Text('Day ${_selectedDayOffset + 1}',
                                        style: const TextStyle(
                                            color: AppColors.primary,
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.w800)),
                                    IconButton(
                                      visualDensity: VisualDensity.compact,
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      icon: Icon(Icons.arrow_right_rounded,
                                          color: _selectedDayOffset < _totalDays - 1
                                              ? AppColors.primary
                                              : Colors.grey.shade300),
                                      onPressed: _selectedDayOffset < _totalDays - 1
                                          ? () => _changeDay(1)
                                          : null,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          _MiniChart(data: _getHourlyCounts()),
                          const SizedBox(height: 5),
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('9 AM', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
                              Text('11 AM', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
                              Text('1 PM', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
                              Text('3 PM', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
                              Text('5 PM', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
                              Text('7 PM', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 330),
                ],
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 12)),

            // ───────────── Action cards ─────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: _ActionCard(
                        gradientColors: const [
                          Color(0xFF1FC9B5),
                          Color(0xFF0D8E82),
                        ],
                        iconColor: const Color(0xFF0D9488),
                        icon: Icons.crop_free_rounded,
                        title: 'Scan Visitor QR',
                        subtitle: 'Collect Leads',
                        onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const ScannerScreen())),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _ActionCard(
                        gradientColors: const [
                          Color(0xFFF6A93D),
                          Color(0xFFD97706),
                        ],
                        iconColor: const Color(0xFFD97706),
                        icon: Icons.person_add_alt_1_rounded,
                        title: 'Add Visitor',
                        subtitle: 'Create Lead',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const ManualAddVisitorScreen()),
                        ).then((_) => _load()),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ───────────── Recent leads header ─────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 5),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Recent Five Leads',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0F172A))),
                    TextButton(
                      onPressed: _openAllLeads,
                      child: const Text('View All',
                          style: TextStyle(
                              color: Color(0xFF0B7C72),
                              fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
              ),
            ),

            // ───────────── Recent leads list / empty / error states ─────────────
            if (_loadFailed)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.red.shade100),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.error_outline_rounded,
                            color: Colors.red.shade400, size: 28),
                        const SizedBox(height: 8),
                        const Text(
                          "Couldn't load your leads — pull down to retry.",
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else if (_allLeads.isEmpty)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.people_alt_outlined,
                            size: 48, color: Color(0xFFE2E8F0)),
                        SizedBox(height: 12),
                        Text('No leads yet — scan your first visitor!',
                            style: TextStyle(color: Color(0xFF94A3B8), fontSize: 14)),
                      ],
                    ),
                  ),
                ),
              )
            else
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: _cardShadow,
                  ),
                  child: Column(
                    children: List.generate(_allLeads.length > 5 ? 5 : _allLeads.length, (i) {
                      final lead = _allLeads[i];
                      final visitor = lead['visitor'] ?? {};
                      final name = _toTitleCase(visitor['full_name'] ?? 'Unknown');
                      final phone = visitor['mobile_number'] ?? '';
                      final location = visitor['location'] ?? '';
                      final color = _avatarColor(name);
                      final isLast = i == (_allLeads.length > 5 ? 4 : _allLeads.length - 1);
                      return InkWell(
                        borderRadius: BorderRadius.vertical(
                          top: i == 0 ? const Radius.circular(22) : Radius.zero,
                          bottom: isLast ? const Radius.circular(22) : Radius.zero,
                        ),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => LeadDetailScreen(
                                  leadId: lead['id'].toString())),
                        ).then((_) => _load()),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            border: isLast
                                ? null
                                : const Border(
                                    bottom: BorderSide(
                                        color: Color(0xFFF1F5F9), width: 1),
                                  ),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 22,
                                backgroundColor: color,
                                child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?',
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 16)),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                  CrossAxisAlignment.start,
                                  children: [
                                    Text(name,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w800,
                                            fontSize: 16,
                                            color: Color(0xFF0F172A))),
                                    const SizedBox(height: 2),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        if (phone.isNotEmpty)
                                          Text(phone,
                                              style: const TextStyle(
                                                  fontSize: 13,
                                                  color: Color(0xFF475569))),
                                        if (location.isNotEmpty)
                                          Text(location,
                                              style: const TextStyle(
                                                  fontSize: 13,
                                                  color: Color(0xFF475569))),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.chevron_right_rounded,
                                  color: Color(0xFF94A3B8), size: 24),
                            ],
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ),

            const SliverToBoxAdapter(child: SizedBox(height: 150)),
          ],
        ),
      ),
    );
  }
}

class _HeaderWavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final wave1 = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.white.withOpacity(0.20),
          Colors.white.withOpacity(0.0),
        ],
        begin: Alignment.topRight,
        end: Alignment.bottomLeft,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    final p1 = Path();
    p1.moveTo(size.width * 0.26, 0);
    p1.quadraticBezierTo(
      size.width * 0.60, size.height * 0.26,
      size.width, size.height * 0.07,
    );
    p1.lineTo(size.width, 0);
    p1.close();
    canvas.drawPath(p1, wave1);

    final wave2 = Paint()
      ..color = Colors.white.withOpacity(0.09)
      ..style = PaintingStyle.fill;
    final p2 = Path();
    p2.moveTo(size.width * 0.45, size.height * 0.02);
    p2.quadraticBezierTo(
      size.width * 0.78, size.height * 0.32,
      size.width, size.height * 0.18,
    );
    p2.lineTo(size.width, 0);
    p2.lineTo(size.width * 0.45, 0);
    p2.close();
    canvas.drawPath(p2, wave2);

    final wave3 = Paint()
      ..color = Colors.white.withOpacity(0.06)
      ..style = PaintingStyle.fill;
    final p3 = Path();
    p3.moveTo(0, size.height * 0.55);
    p3.quadraticBezierTo(
      size.width * 0.22, size.height * 0.72,
      size.width * 0.10, size.height,
    );
    p3.lineTo(0, size.height);
    p3.close();
    canvas.drawPath(p3, wave3);

    final blobPaint1 = Paint()
      ..color = Colors.white.withOpacity(0.11)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 26);
    canvas.drawCircle(
        Offset(size.width * 0.04, size.height * 0.88), 70, blobPaint1);

    final blobPaint2 = Paint()
      ..color = Colors.white.withOpacity(0.09)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);
    canvas.drawCircle(
        Offset(size.width * 0.93, size.height * 0.50), 46, blobPaint2);

    final blobPaint3 = Paint()
      ..color = Colors.white.withOpacity(0.10)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16);
    canvas.drawCircle(
        Offset(size.width * 0.18, size.height * 0.16), 26, blobPaint3);

    final blobPaint4 = Paint()
      ..color = Colors.white.withOpacity(0.07)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14);
    canvas.drawCircle(
        Offset(size.width * 0.68, size.height * 0.36), 20, blobPaint4);
  }

  @override
  bool shouldRepaint(_HeaderWavePainter oldDelegate) => false;
}

class _ActionCard extends StatelessWidget {
  final List<Color> gradientColors;
  final Color iconColor;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionCard({
    required this.gradientColors,
    required this.iconColor,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        clipBehavior: Clip.antiAlias,
        constraints: const BoxConstraints(minHeight: 130),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
                color: gradientColors.last.withOpacity(0.30),
                blurRadius: 18,
                offset: const Offset(0, 8)),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              top: -28,
              right: -28,
              child: Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.10),
                ),
              ),
            ),
            Positioned(
              bottom: -36,
              left: -30,
              child: Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.07),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.18),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(icon, color: iconColor, size: 28),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 14)),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          Expanded(
                            child: Text(subtitle,
                                style: TextStyle(
                                    color: Colors.white.withOpacity(0.88),
                                    fontSize: 12.5)),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            width: 28,
                            height: 28,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.30),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.10),
                                  blurRadius: 5,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(Icons.arrow_forward_rounded,
                                color: Colors.white, size: 14),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniChart extends StatelessWidget {
  final List<double> data;
  const _MiniChart({required this.data});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: CustomPaint(
        painter: _LinePainter(data),
        size: const Size(double.infinity, 40),
      ),
    );
  }
}

class _LinePainter extends CustomPainter {
  final List<double> points;
  static const int _dotsFromIndex = 3;

  const _LinePainter(this.points);

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = const Color(0xFF14B8A6)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final dotPaint = Paint()
      ..color = const Color(0xFF14B8A6)
      ..style = PaintingStyle.fill;

    final dotRingPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final max = points.reduce((a, b) => a > b ? a : b);
    final min = points.reduce((a, b) => a < b ? a : b);
    final range = max - min == 0 ? 1.0 : max - min;
    final offsets = <Offset>[];
    for (int i = 0; i < points.length; i++) {
      final x = i * size.width / (points.length - 1);
      final y = size.height -
          ((points[i] - min) / range) * size.height * 0.72 -
          size.height * 0.14;
      offsets.add(Offset(x, y));
    }

    final linePath = Path();
    final fillPath = Path();

    for (int i = 0; i < offsets.length; i++) {
      if (i == 0) {
        linePath.moveTo(offsets[i].dx, offsets[i].dy);
        fillPath.moveTo(offsets[i].dx, size.height);
        fillPath.lineTo(offsets[i].dx, offsets[i].dy);
      } else {
        final prev = offsets[i - 1];
        final curr = offsets[i];
        final cpX = (prev.dx + curr.dx) / 2;
        linePath.cubicTo(cpX, prev.dy, cpX, curr.dy, curr.dx, curr.dy);
        fillPath.cubicTo(cpX, prev.dy, cpX, curr.dy, curr.dx, curr.dy);
      }
    }
    fillPath.lineTo(offsets.last.dx, size.height);
    fillPath.close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          const Color(0xFF14B8A6).withOpacity(0.14),
          const Color(0xFF14B8A6).withOpacity(0.0),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(linePath, linePaint);

    for (int i = 0; i < offsets.length; i++) {
      if (i < _dotsFromIndex) continue;
      canvas.drawCircle(offsets[i], 3.0, dotRingPaint);
      canvas.drawCircle(offsets[i], 2.0, dotPaint);
    }
  }

  @override
  bool shouldRepaint(_LinePainter old) => old.points != points;
}
