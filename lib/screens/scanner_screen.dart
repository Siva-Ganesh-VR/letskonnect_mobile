import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../core/app_colors.dart';
import '../core/api_client.dart';
import '../core/refresh_notifier.dart';
import 'lead_detail_screen.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  final MobileScannerController _controller = MobileScannerController();
  bool _isProcessing = false;

  void _onDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;
    final barcode = capture.barcodes.firstOrNull;
    if (barcode?.rawValue == null) return;

    setState(() => _isProcessing = true);
    HapticFeedback.mediumImpact();

    String qrToken = barcode!.rawValue!;
    if (qrToken.contains('/v/')) {
      qrToken = qrToken.split('/v/').last;
    }

    try {
      final result = await ApiClient.call(() => ApiClient.dio.post(
            '/api/v1/stall_owner/scan',
            data: {'qr_token': qrToken},
          ));

      if (!mounted) return;

      if (result.success) {
        final data = result.data as Map<String, dynamic>;
        final leadId = data['lead']?['id']?.toString() ?? '';
        final message = data['message']?.toString() ?? '';

        if (message.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message)),
          );
        }

        RefreshNotifier.refreshLeads();

        if (leadId.isNotEmpty) {
          await Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => LeadDetailScreen(leadId: leadId)),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.error ?? 'Invalid QR code'),
            backgroundColor: Colors.red.shade600,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Network error — please try again'),
          backgroundColor: Colors.red.shade600,
        ),
      );
    } finally {
      if (mounted) {
        // Reset processing flag after a short delay to prevent rapid re-scans
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) setState(() => _isProcessing = false);
        });
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // MobileScanner manages camera permission natively.
          // It must be rendered unconditionally for the camera to initialize.
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.4),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                              Icons.arrow_back_ios_new_rounded,
                              color: Colors.white,
                              size: 18),
                        ),
                      ),
                      const Text('Scan Visitor QR',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w700)),
                      GestureDetector(
                        onTap: () => _controller.toggleTorch(),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.4),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.flash_on_rounded,
                              color: Colors.white, size: 20),
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Container(
                  width: 240,
                  height: 240,
                  decoration: BoxDecoration(
                    border: Border.all(
                        color: AppColors.primary, width: 3),
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  _isProcessing
                      ? 'Processing QR code...'
                      : 'Point camera at visitor badge',
                  style: const TextStyle(
                      color: Colors.white70, fontSize: 14),
                ),
                const Spacer(),
                if (_isProcessing)
                  Container(
                    margin: const EdgeInsets.only(bottom: 40),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        ),
                        SizedBox(width: 8),
                        Text('Fetching lead...',
                            style: TextStyle(color: Colors.white)),
                      ],
                    ),
                  )
                else
                  const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
