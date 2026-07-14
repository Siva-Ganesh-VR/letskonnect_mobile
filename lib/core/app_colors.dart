import 'package:flutter/material.dart';

class AppColors {
  static const primary       = Color(0xFF14B8A6);
  static const accent        = Color(0xFFF59E0B);
  static const success       = Color(0xFF22C55E);
  static const background    = Color(0xFFF8FAFC);
  static const card          = Color(0xFFFFFFFF);
  static const textPrimary   = Color(0xFF0F172A);
  static const textSecondary = Color(0xFF64748B);
  static const border        = Color(0xFFE2E8F0);

  static const tempHot  = Color(0xFFEF4444);
  static const tempWarm = Color(0xFFF59E0B);
  static const tempCold = Color(0xFF3B82F6);

  static const statusNew        = Color(0xFF3B82F6);
  static const statusContacted  = Color(0xFF8B5CF6);
  static const statusInterested = Color(0xFF14B8A6);
  static const statusFollowUp   = Color(0xFFF59E0B);
  static const statusConverted  = Color(0xFF22C55E);
  static const statusLost       = Color(0xFF94A3B8);

  static Color temperatureColor(String t) {
    switch (t) {
      case 'hot':  return tempHot;
      case 'cold': return tempCold;
      default:     return tempWarm;
    }
  }

  static Color statusColor(String s) {
    switch (s) {
      case 'contacted':  return statusContacted;
      case 'interested': return statusInterested;
      case 'follow_up':  return statusFollowUp;
      case 'converted':  return statusConverted;
      case 'lost':       return statusLost;
      default:           return statusNew;
    }
  }

  static String statusLabel(String s) {
    switch (s) {
      case 'contacted':  return 'Contacted';
      case 'interested': return 'Interested';
      case 'follow_up':  return 'Follow-up';
      case 'converted':  return 'Converted';
      case 'lost':       return 'Lost';
      default:           return 'New';
    }
  }
}