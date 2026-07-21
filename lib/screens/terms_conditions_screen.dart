import 'package:flutter/material.dart';
import '../core/app_colors.dart';

class TermsConditionsScreen extends StatelessWidget {
  const TermsConditionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Terms of Service'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Terms of Service',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '📅 Effective: July 14, 2026\n🏢 Bhive Technologies, Tamil Nadu, India',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            
            _sectionTitle('01', 'Agreement'),
            _paragraph('By downloading, installing, or using StallConnect ("App"), you ("Stall Owner", "User") agree to be bound by these Terms of Service. If you do not agree, do not use the App.'),
            _paragraph('The App is operated by Bhive Technologies, Tamil Nadu, India.'),

            _sectionTitle('02', 'Eligibility'),
            _bulletItem('You must be at least 18 years of age'),
            _bulletItem('You must be a registered stall owner or exhibitor at an event managed through StallConnect'),
            _bulletItem('Your account must be created by an authorised event organiser or platform administrator'),
            _bulletItem('You must have a valid Indian mobile number'),

            _sectionTitle('03', 'Account Responsibility'),
            _bulletItem('Your credentials (mobile number and pass code) are personal and confidential'),
            _bulletItem('You are responsible for all activity that occurs under your account'),
            _bulletItem('Notify us immediately at support@stallconnect.in if you suspect unauthorised access'),
            _bulletItem('Do not share your pass code with others'),

            _sectionTitle('04', 'Permitted Use'),
            _paragraph('You may use the App to:'),
            _bulletItem('Scan visitor QR passes at events'),
            _bulletItem('View and manage your captured leads'),
            _bulletItem('Classify leads and add notes'),
            _bulletItem('Send WhatsApp follow-up messages to visitors'),
            _bulletItem('Export your lead data'),
            _bulletItem('View your stall analytics'),

            _sectionTitle('05', 'Prohibited Use'),
            _warnBox('Violation of these rules may result in immediate account termination and reporting to appropriate authorities.'),
            _bulletItem('Use the App for any purpose other than legitimate business lead management'),
            _bulletItem('Contact visitors for purposes unrelated to the event'),
            _bulletItem('Use visitor data for spam, harassment, or unsolicited marketing'),
            _bulletItem('Share visitor contact information with third parties without consent'),
            _bulletItem('Attempt to reverse engineer, hack, or compromise the App or platform'),
            _bulletItem('Create multiple accounts'),
            _bulletItem('Use automated tools to interact with the platform'),
            _bulletItem('Violate any applicable Indian law including the DPDP Act, IT Act, and consumer protection laws'),

            _sectionTitle('06', 'Visitor Data Responsibility'),
            _paragraph('As a stall owner, you are a data processor for visitor personal information. You agree to:'),
            _bulletItem('Use visitor data only for follow-up related to the event'),
            _bulletItem('Not retain visitor data beyond what is necessary'),
            _bulletItem('Not sell or transfer visitor data to third parties'),
            _bulletItem('Comply with all applicable data protection laws'),
            _bulletItem('Respect visitors who request not to be contacted'),

            _sectionTitle('07', 'Intellectual Property'),
            _paragraph('The StallConnect name, logo, and platform are owned by Bhive Technologies. You may not copy, reproduce, or use our brand without written permission.'),

            _sectionTitle('08', 'Termination'),
            _paragraph('We may suspend or terminate your access if you:'),
            _bulletItem('Violate these Terms'),
            _bulletItem('Use visitor data improperly'),
            _bulletItem('Engage in abusive or fraudulent behaviour'),
            _bulletItem('No longer participate in an active event'),

            _sectionTitle('09', 'Disclaimers'),
            _bulletItem('The App is provided "as is" without warranties of any kind'),
            _bulletItem('We do not guarantee uninterrupted service, especially during high-traffic event periods'),
            _bulletItem('We are not responsible for the accuracy of lead information entered by users'),

            _sectionTitle('10', 'Limitation of Liability'),
            _paragraph('To the maximum extent permitted by Indian law, Bhive Technologies shall not be liable for indirect, incidental, or consequential damages arising from use of the App.'),
            _infoBox('Our total liability shall not exceed INR 10,000 (Ten Thousand Rupees) in any case.'),

            _sectionTitle('11', 'Governing Law'),
            _paragraph('These Terms are governed by the laws of India. Any disputes shall be subject to the exclusive jurisdiction of courts in Madurai, Tamil Nadu.'),
            _paragraph('Questions about these Terms? Email support@stallconnect.in'),
            
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

  Widget _warnBox(String text) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16, top: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFEE2E2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_amber_rounded, color: Color(0xFFEF4444), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 13,
                height: 1.5,
                color: Color(0xFF991B1B),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
