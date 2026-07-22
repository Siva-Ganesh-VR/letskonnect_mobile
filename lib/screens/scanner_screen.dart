import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
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
  MobileScannerController? _controller;
  bool _isProcessing = false;
  bool _permissionGranted = false;
  bool _permissionChecked = false;
  String? _cameraError;

  @override
  void initState() {
    super.initState();
    _requestCameraPermission();
  }

  Future<void> _requestCameraPermission() async {
    try {
      var status = await Permission.camera.status;
      if (status.isDenied) status = await Permission.camera.request();
      if (!mounted) return;

      if (status.isPermanentlyDenied) {
        setState(() {
          _permissionGranted = false;
          _permissionChecked = true;
          _cameraError =
              'Camera permission permanently denied. Open app settings to enable it.';
        });
        return;
      }

      final granted = status.isGranted;
      setState(() {
        _permissionGranted = granted;
        _permissionChecked = true;
        _cameraError = null;
      });

      if (granted) await _initController();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _permissionGranted = false;
        _permissionChecked = true;
        _cameraError = 'Camera initialization failed: ${e.toString()}';
      });
    }
  }

  Future<void> _initController() async {
    try {
      _controller = MobileScannerController(
        detectionSpeed: DetectionSpeed.normal,
        facing: CameraFacing.back,
        torchEnabled: false,
      );
      await _controller?.start();
      setState(() {});
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _cameraError = 'Failed to access camera: ${e.toString()}';
      });
    }
  }

  void _onDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;
    final barcode = capture.barcodes.firstOrNull;
    if (barcode?.rawValue == null) return;

    setState(() => _isProcessing = true);
    _controller?.stop();
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
        final lead = data['lead'] as Map<String, dynamic>?;
        final leadId = lead?['id']?.toString() ?? '';
        final message = data['message']?.toString() ?? '';

        // ── Extract event_id from scan response ──────────────────────
        // The scan response returns the lead object which contains event_id.
        // We pass it to LeadDetailScreen so all subsequent API calls include
        // ?event_id=xxx — this lets the backend find the correct stall owner
        // when a stall owner participates in multiple events.
        final eventId = lead?['event_id']?.toString();

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
              builder: (_) => LeadDetailScreen(
                leadId: leadId,
                eventId: eventId, // ← pass event_id here
              ),
            ),
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
        _controller?.start();
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // ── Camera view or permission state ──────────────────────────
          if (!_permissionChecked)
            const SizedBox.expand()
          else if (_permissionGranted && _controller != null)
            MobileScanner(
              controller: _controller!,
              onDetect: _onDetect,
            )
          else
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.camera_alt_outlined,
                        color: Colors.white38, size: 72),
                    const SizedBox(height: 20),
                    const Text('Camera Access Required',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700),
                        textAlign: TextAlign.center),
                    const SizedBox(height: 10),
                    Text(
                      _cameraError ??
                          'Please allow camera access to scan visitor QR codes.',
                      style: const TextStyle(
                          color: Colors.white54, fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 28),
                    ElevatedButton(
                      onPressed: () async {
                        await openAppSettings();
                        if (mounted) _requestCameraPermission();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 32, vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Open Settings'),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: _requestCameraPermission,
                      child: const Text('Try Again',
                          style: TextStyle(color: Colors.white54)),
                    ),
                  ],
                ),
              ),
            ),

          // ── Overlay UI ───────────────────────────────────────────────
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
                          child: const Icon(Icons.arrow_back_ios_new_rounded,
                              color: Colors.white, size: 18),
                        ),
                      ),
                      const Text('Scan Visitor QR',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w700)),
                      GestureDetector(
                        onTap: _permissionGranted
                            ? () => _controller?.toggleTorch()
                            : null,
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.4),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.flash_on_rounded,
                              color: _permissionGranted
                                  ? Colors.white
                                  : Colors.white24,
                              size: 20),
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                if (_permissionGranted) ...[
                  Container(
                    width: 240,
                    height: 240,
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.primary, width: 3),
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text('Point camera at visitor badge',
                      style:
                          TextStyle(color: Colors.white70, fontSize: 14)),
                ],
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