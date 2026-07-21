import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../core/app_helpers.dart';

class LeadCard extends StatelessWidget {
  final Map<String, dynamic> lead;
  final VoidCallback? onTap;
  final VoidCallback? onMoreTap;

  const LeadCard({
    super.key,
    required this.lead,
    this.onTap,
    this.onMoreTap,
  });

  @override
  Widget build(BuildContext context) {
    final visitor = lead['visitor'] ?? {};
    final name = AppHelpers.toTitleCase(visitor['full_name'] ?? 'Unknown');
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
                AppHelpers.initials(name),
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
