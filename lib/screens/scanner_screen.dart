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

class _ScannerScreenState extends State<ScannerScreen> with WidgetsBindingObserver {
  final MobileScannerController _controller = MobileScannerController();
  bool _isProcessing = false;
  bool _permissionGranted = false;
  bool _permissionChecked = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkAndRequestPermission();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // If user comes back from Settings after granting permission, restart scanner
    if (state == AppLifecycleState.resumed && _permissionChecked && !_permissionGranted) {
      _checkAndRequestPermission();
    }
  }

  Future<void> _checkAndRequestPermission() async {
    final state = await _controller.requestPermission();
    if (!mounted) return;

    setState(() {
      _permissionChecked = true;
      _permissionGranted = state == MobileScannerAuthorizationState.authorized;
    });

    if (!_permissionGranted) {
      // Permission denied — show dialog
      _showPermissionDialog();
    }
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Camera Permission Required',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        content: const Text(
          'StallConnect needs camera access to scan visitor QR passes.\n\nPlease allow camera permission to continue.',
          style: TextStyle(color: Colors.white70, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context); // go back to previous screen
            },
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              // Opens app settings so user can grant permission manually
              MobileScannerController.requestPermission();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  void _onDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;
    final barcode = capture.barcodes.firstOrNull;
    if (barcode?.rawValue == null) return;

    setState(() => _isProcessing = true);
    _controller.stop();
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
            MaterialPageRoute(builder: (_) => LeadDetailScreen(leadId: leadId)),
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
        setState(() => _isProcessing = false);
        _controller.start();
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Show scanner only if permission is granted
          if (_permissionGranted)
            MobileScanner(
              controller: _controller,
              onDetect: _onDetect,
            )
          else
            // Show permission prompt UI while waiting or if denied
            _buildPermissionUI(),

          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                          child: const Icon(Icons.arrow_back_ios_new_rounded,
                              color: Colors.white, size: 18),
                        ),
                      ),
                      const Text('Scan Visitor QR',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w700)),
                      // Only show torch button when camera is active
                      if (_permissionGranted)
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
                        )
                      else
                        const SizedBox(width: 40),
                    ],
                  ),
                ),
                const Spacer(),
                // Scanner frame
                Container(
                  width: 240,
                  height: 240,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: _permissionGranted
                          ? AppColors.primary
                          : Colors.white24,
                      width: 3,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  // Show hint icon when permission not yet granted
                  child: _permissionGranted
                      ? null
                      : const Center(
                          child: Icon(
                            Icons.camera_alt_outlined,
                            color: Colors.white38,
                            size: 48,
                          ),
                        ),
                ),
                const SizedBox(height: 24),
                Text(
                  _permissionGranted
                      ? 'Point camera at visitor badge'
                      : 'Camera permission required',
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const Spacer(),
                if (_isProcessing)
                  Container(
                    margin: const EdgeInsets.only(bottom: 40),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
                else if (!_permissionGranted && _permissionChecked)
                  // Show retry button if permission was denied
                  Container(
                    margin: const EdgeInsets.only(bottom: 40),
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 28, vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24)),
                      ),
                      onPressed: _checkAndRequestPermission,
                      icon: const Icon(Icons.camera_alt_outlined, size: 18),
                      label: const Text('Allow Camera Access',
                          style: TextStyle(fontWeight: FontWeight.w600)),
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

  Widget _buildPermissionUI() {
    return Container(
      color: Colors.black,
      child: const Center(
        child: CircularProgressIndicator(
          color: AppColors.primary,
          strokeWidth: 2,
        ),
      ),
    );
  }
}