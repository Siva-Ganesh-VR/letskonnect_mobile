import 'package:flutter/material.dart';
import '../core/app_colors.dart';

class LeadCard extends StatelessWidget {
  final Map<String, dynamic> lead;
  final VoidCallback? onTap;
  final VoidCallback? onMoreTap;
  final bool showTags;

  const LeadCard({
    super.key,
    required this.lead,
    this.onTap,
    this.onMoreTap,
    this.showTags = true,
  });

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  String _getLeadTag(Map<String, dynamic> lead) {
    final status = lead['status'] ?? 'new';
    if (status == 'new' || status == '') {
      return lead['temperature'] ?? 'warm';
    }
    return status;
  }

  Color _statusColor(Map<String, dynamic> lead) {
    final tag = _getLeadTag(lead);
    if (['hot', 'warm', 'cold'].contains(tag)) {
      return AppColors.temperatureColor(tag);
    }
    return AppColors.statusColor(tag);
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

  String _timeAgo(String? iso) {
    if (iso == null) return '';
    final dt = DateTime.tryParse(iso);
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    final visitor = lead['visitor'] ?? {};
    final name = _toTitleCase(visitor['full_name'] ?? 'Unknown');
    final bool isStarred = lead['is_favorite'] == true;
    final eventCount = visitor['attended_events_count'] ?? 1;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: AppColors.primary.withOpacity(0.12),
              child: Text(
                _initials(name),
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(name,
                            style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                                color: Color(0xFF0F172A))),
                      ),
                      Icon(
                        isStarred ? Icons.star_rounded : Icons.star_border_rounded,
                        color: isStarred
                            ? const Color(0xFFF59E0B)
                            : const Color(0xFF94A3B8),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: onMoreTap,
                        child: const Icon(Icons.more_vert_rounded,
                            size: 20, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('No. of Events : $eventCount',
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF64748B))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
