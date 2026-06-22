import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../core/theme.dart';
import '../../data/models/mission_config.dart';
import 'mission_scaffold.dart';

/// Scan a QR/barcode to dismiss. If the alarm has a saved [qrPayload], the
/// scanned code must match it (so users stick a code in the bathroom/kitchen);
/// otherwise any code works.
class QrMission extends StatefulWidget {
  final MissionConfig config;
  final VoidCallback onComplete;
  const QrMission({super.key, required this.config, required this.onComplete});

  @override
  State<QrMission> createState() => _QrMissionState();
}

class _QrMissionState extends State<QrMission> {
  final _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
  );
  bool _done = false;
  String _status = 'Point the camera at your saved code';

  void _onDetect(BarcodeCapture capture) {
    if (_done) return;
    for (final b in capture.barcodes) {
      final value = b.rawValue ?? '';
      final required = widget.config.qrPayload.trim();
      if (required.isEmpty || value == required) {
        _done = true;
        _controller.dispose();
        widget.onComplete();
        return;
      } else {
        setState(() => _status = 'Wrong code — find the right one');
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
    return MissionScaffold(
      title: 'Scan to dismiss',
      subtitle: _status,
      progress: _done ? 1 : 0,
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: SizedBox(
              height: 320,
              width: double.infinity,
              child: MobileScanner(
                controller: _controller,
                onDetect: _onDetect,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton.filledTonal(
                onPressed: () => _controller.toggleTorch(),
                icon: const Icon(Icons.flashlight_on),
              ),
              const SizedBox(width: 16),
              IconButton.filledTonal(
                onPressed: () => _controller.switchCamera(),
                icon: const Icon(Icons.cameraswitch),
              ),
            ],
          ),
          if (widget.config.qrPayload.trim().isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 12),
              child: Text(
                'Tip: set a specific code in alarm settings so you must walk to it.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textMuted, fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }
}
