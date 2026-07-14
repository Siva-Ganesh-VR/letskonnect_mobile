import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/app_colors.dart';
import '../core/api_client.dart';
import 'home_screen.dart';

class OtpScreen extends StatefulWidget {
  final String mobile;
  final String eventId;
  const OtpScreen({super.key, required this.mobile, required this.eventId});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final _otpCtrl = TextEditingController();
  bool _loading = false;

  String get _maskedMobile {
    final m = widget.mobile;
    return m.length >= 10
        ? '+91 ${m.substring(0, 2)}XXXXXX${m.substring(8)}'
        : '+91 ${widget.mobile}';
  }

  Future<void> _verifyOtp() async {
    if (_otpCtrl.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter the 6-digit OTP')),
      );
      return;
    }

    setState(() => _loading = true);

    final result = await ApiClient.call(() => ApiClient.dio.post(
      '/api/v1/stall/verify_otp',
      data: {
        'mobile_number': widget.mobile,
        'otp': _otpCtrl.text,
        'event_id': widget.eventId,
      },
    ));

    setState(() => _loading = false);
    if (!mounted) return;

    if (result.success) {
      final data = result.data as Map<String, dynamic>;
      await ApiClient.saveToken(data['token']);
      await ApiClient.saveStallOwnerJson(jsonEncode(data['stall_owner']));
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => HomeScreen()),
            (route) => false,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.error ?? 'Invalid OTP'),
          backgroundColor: Colors.red.shade600,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Verify OTP')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            const Text('Enter OTP',
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A))),
            const SizedBox(height: 6),
            Text('Sent to $_maskedMobile',
                style: const TextStyle(
                    fontSize: 14, color: Color(0xFF64748B))),
            const SizedBox(height: 8),
            const Text(
                'Check your Rails server terminal — OTP is printed there.',
                style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                    fontStyle: FontStyle.italic)),
            const SizedBox(height: 32),
            TextField(
              controller: _otpCtrl,
              keyboardType: TextInputType.number,
              maxLength: 6,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 16),
              textAlign: TextAlign.center,
              decoration: const InputDecoration(
                counterText: '',
                hintText: '• • • • • •',
                hintStyle: TextStyle(
                    fontSize: 20,
                    letterSpacing: 12,
                    color: Color(0xFFE2E8F0)),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(

              onPressed: _loading ? null : _verifyOtp,
              child: _loading
                  ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2.5))
                  : const Text('Verify OTP'),
            ),
          ],
        ),
      ),
    );
  }
}