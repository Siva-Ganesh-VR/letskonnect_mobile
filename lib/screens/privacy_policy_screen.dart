import 'package:flutter/material.dart';
import '../core/app_colors.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Privacy Policy'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Privacy Policy',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '📅 Effective: July 14, 2026\n🔄 Last updated: July 14, 2026\n🏢 Bhive Technologies, Tamil Nadu, India',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            
            _sectionTitle('01', 'Who We Are'),
            _paragraph('StallConnect is a product of Bhive Technologies, a company registered in Tamil Nadu, India, with offices in Madurai and Chennai.'),
            _contactCard([
              _contactRow('🌐', 'Website', 'stallconnect.in'),
              _contactRow('✉️', 'Email', 'support@stallconnect.in'),
              _contactRow('📍', 'Address', 'Bhive Technologies, Tamil Nadu, India'),
            ]),

            _sectionTitle('02', 'Information We Collect'),
            _paragraph('Your stall owner account is created by your event organiser. The following information is collected at account creation:'),
            const SizedBox(height: 8),
            _dataTable([
              ['Data', 'Required', 'Stored'],
              ['Full name', 'Required', 'Encrypted server'],
              ['Mobile number', 'Required', 'Encrypted server'],
              ['Company name', 'Required', 'Encrypted server'],
              ['Email address', 'Optional', 'Encrypted server'],
              ['Stall number & category', 'Optional', 'Encrypted server'],
              ['Website URL', 'Optional', 'Encrypted server'],
              ['Login token (JWT)', 'Auto-generated', 'Device secure storage only'],
            ]),
            const SizedBox(height: 12),
            _paragraph('We do not collect: GPS location, phone contacts, photos, microphone audio, advertising identifiers, biometric data, or government ID numbers.'),

            _sectionTitle('03', 'Camera Usage'),
            _infoBox('The App uses your device camera only to scan visitor QR pass codes at events. We do not store, transmit, or process any images captured by your camera. The camera is used solely for real-time QR code reading and nothing is saved.'),

            _sectionTitle('04', 'Visitor Data You Manage'),
            _paragraph('As a stall owner, you capture and manage lead information about event visitors. This data is collected by visitors themselves through WhatsApp during event registration and includes:'),
            _bulletItem('Visitor name and mobile number'),
            _bulletItem('City / location'),
            _bulletItem('Business category and networking goals'),
            _bulletItem('Decision-maker status'),
            _paragraph('You are responsible for handling visitor information lawfully. You must not use visitor data for purposes unrelated to the event for which it was collected.'),

            _sectionTitle('05', 'How We Use Your Information'),
            _bulletItem('Provide and operate the StallConnect service'),
            _bulletItem('Enable QR code scanning and lead capture at events'),
            _bulletItem('Allow you to manage, classify, and follow up with leads'),
            _bulletItem('Generate lead reports and analytics'),
            _bulletItem('Send WhatsApp follow-up messages when you initiate them'),
            _bulletItem('Provide customer support'),
            _bulletItem('Improve the App and fix issues'),

            _sectionTitle('06', 'How We Share Information'),
            _paragraph('We do not sell your personal information. We share data only with:'),
            const SizedBox(height: 8),
            _dataTable([
              ['Party', 'Purpose', 'Data shared'],
              ['Twilio Inc.', 'WhatsApp message delivery', 'Visitor mobile numbers, message content'],
              ['AWS S3 (Mumbai)', 'QR code image storage', 'QR images (no personal data)'],
              ['Event Organisers', 'Event management', 'Your stall profile and lead counts'],
            ]),
            const SizedBox(height: 12),
            _paragraph('All third-party providers are bound by data processing agreements.'),

            _sectionTitle('07', 'Security'),
            _bulletItem('All communication uses HTTPS/TLS encryption'),
            _bulletItem('Passwords stored using BCrypt hashing — never in plain text'),
            _bulletItem('Your login token is stored using iOS Keychain / Android Keystore'),
            _bulletItem('API endpoints protected by rate limiting'),
            _bulletItem('Tokens invalidated immediately on sign-out'),
            _bulletItem('OTP codes expire after 10 minutes'),

            _sectionTitle('08', 'Data Retention'),
            const SizedBox(height: 8),
            _dataTable([
              ['Data Type', 'Retained For'],
              ['Account & lead data', 'Active account + 12 months after last event'],
              ['Visitor registration data', '12 months from event date'],
              ['Authentication tokens', 'Session only — deleted on sign-out'],
              ['OTP codes', 'Deleted immediately after use'],
              ['Exported files', '24 hours — automatic deletion'],
            ]),

            _sectionTitle('09', 'Your Rights (DPDP Act 2023)'),
            _paragraph('Under India\'s Digital Personal Data Protection Act 2023, you have the right to:'),
            _bulletItem('Access your personal data'),
            _bulletItem('Correction of inaccurate data'),
            _bulletItem('Erasure of your personal data'),
            _bulletItem('Grievance redressal within 30 days'),
            _paragraph('To exercise these rights, email support@stallconnect.in with subject "Data Rights Request".'),

            _sectionTitle('10', 'Account & Data Deletion'),
            _stepItem('1', 'Email support@stallconnect.in with subject "Account Deletion Request"'),
            _stepItem('2', 'Include your registered mobile number'),
            _stepItem('3', 'We confirm receipt within 2 business days'),
            _stepItem('4', 'Deletion completed within 7 business days'),
            _infoBox('Anonymised aggregated statistics may be retained for organiser reporting. You will receive email confirmation when deletion is complete.'),

            _sectionTitle('11', 'Children\'s Privacy'),
            _paragraph('StallConnect is a business application intended for adults only. We do not knowingly collect personal information from anyone under 18. If you believe a minor has used the App, contact us immediately at support@stallconnect.in.'),

            _sectionTitle('12', 'Contact Us'),
            _contactCard([
              _contactRow('🏢', 'Company', 'Bhive Technologies, Tamil Nadu, India'),
              _contactRow('✉️', 'Email', 'support@stallconnect.in'),
              _contactRow('🌐', 'Website', 'stallconnect.in'),
            ]),
            
            const SizedBox(height: 40),
            Center(
              child: Text(
                '© 2026 Bhive Technologies. All rights reserved.',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary.withOpacity(0.7)),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String num, String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            num,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _paragraph(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          height: 1.6,
          color: Color(0xFF334155),
        ),
      ),
    );
  }

  Widget _bulletItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                height: 1.5,
                color: Color(0xFF334155),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _stepItem(String num, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              num,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                height: 1.5,
                color: Color(0xFF334155),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoBox(String text) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16, top: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          height: 1.6,
          color: Color(0xFF475569),
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }

  Widget _contactCard(List<Widget> rows) {
    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(children: rows),
    );
  }

  Widget _contactRow(String icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF64748B),
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _dataTable(List<List<String>> rows) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE2E8F0)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Table(
          columnWidths: const {
            0: FlexColumnWidth(2),
            1: FlexColumnWidth(1.5),
            2: FlexColumnWidth(2),
          },
          border: const TableBorder(
            horizontalInside: BorderSide(color: Color(0xFFE2E8F0)),
            verticalInside: BorderSide(color: Color(0xFFE2E8F0)),
          ),
          children: rows.asMap().entries.map((entry) {
            final idx = entry.key;
            final row = entry.value;
            return TableRow(
              decoration: BoxDecoration(
                color: idx == 0 ? const Color(0xFFF8FAFC) : Colors.white,
              ),
              children: row.map((cell) {
                return Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    cell,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: idx == 0 ? FontWeight.bold : FontWeight.normal,
                      color: idx == 0 ? const Color(0xFF0F172A) : const Color(0xFF334155),
                    ),
                  ),
                );
              }).toList(),
            );
          }).toList(),
        ),
      ),
    );
  }
}
