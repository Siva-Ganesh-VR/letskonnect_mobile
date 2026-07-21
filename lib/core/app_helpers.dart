import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppHelpers {
  AppHelpers._();

  /// "hello world" → "Hello World"
  static String toTitleCase(String text) {
    if (text.isEmpty) return text;
    return text.toLowerCase().split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1);
    }).join(' ');
  }

  /// ISO timestamp → "3 min ago", "2 hr ago", "5d ago"
  static String timeAgo(String? iso) {
    if (iso == null) return '';
    final dt = DateTime.tryParse(iso);
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} hr ago';
    return '${diff.inDays}d ago';
  }

  /// "John Doe" → "JD", "Alice" → "A"
  static String initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  /// Deterministic avatar background colour from name hash
  static Color avatarColor(String name) {
    const colors = [
      Color(0xFF14B8A6),
      Color(0xFF8B5CF6),
      Color(0xFFF59E0B),
      Color(0xFFEF4444),
      Color(0xFF3B82F6),
      Color(0xFFEC4899),
    ];
    return colors[name.hashCode.abs() % colors.length];
  }

  /// Resolve the effective tag: temperature if status is new/empty, else status
  static String getLeadTag(Map<String, dynamic> lead) {
    final status = lead['status'] ?? 'new';
    if (status == 'new' || status == '') {
      return lead['temperature'] ?? 'warm';
    }
    return status;
  }

  /// Human-readable label for a lead's current tag
  static String statusLabelFromLead(Map<String, dynamic> lead) {
    final tag = getLeadTag(lead);
    if (['hot', 'warm', 'cold'].contains(tag)) {
      return tag[0].toUpperCase() + tag.substring(1);
    }
    return AppColors.statusLabel(tag);
  }

  /// Colour for a lead's current tag
  static Color statusColorFromLead(Map<String, dynamic> lead) {
    final tag = getLeadTag(lead);
    if (['hot', 'warm', 'cold'].contains(tag)) {
      return AppColors.temperatureColor(tag);
    }
    return AppColors.statusColor(tag);
  }

  /// ISO timestamp → "15 Jul 2026, 3:30 PM"
  static String formatDate(String? iso) {
    if (iso == null) return '';
    final dt = DateTime.tryParse(iso);
    if (dt == null) return '';
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final h = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final m = dt.minute.toString().padLeft(2, '0');
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}, $h:$m $ampm';
  }

  /// Two ISO strings → "10 Jul 2026 - 12 Jul 2026"
  static String formatDateRange(String? start, String? end) {
    if (start == null) return 'N/A';
    final startDate = DateTime.tryParse(start);
    if (startDate == null) return 'N/A';
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    String res = '${startDate.day} ${months[startDate.month - 1]} ${startDate.year}';
    if (end != null && end != start) {
      final endDate = DateTime.tryParse(end);
      if (endDate != null) {
        res += ' - ${endDate.day} ${months[endDate.month - 1]} ${endDate.year}';
      }
    }
    return res;
  }
}
