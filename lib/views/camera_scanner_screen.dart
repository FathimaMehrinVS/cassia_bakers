import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../core/constants.dart';

class CameraScannerScreen extends StatefulWidget {
  const CameraScannerScreen({super.key});

  @override
  State<CameraScannerScreen> createState() => _CameraScannerScreenState();
}

class _CameraScannerScreenState extends State<CameraScannerScreen> {
  final MobileScannerController controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
    torchEnabled: false,
  );

  bool _isScanned = false;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Scan Product Barcode', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          // Flash Torch Toggle Button
          ValueListenableBuilder<MobileScannerState>(
            valueListenable: controller,
            builder: (context, state, child) {
              final torchState = state.torchState;
              return IconButton(
                color: Colors.white,
                iconSize: 26.0,
                icon: Icon(
                  torchState == TorchState.on ? Icons.flash_on : Icons.flash_off,
                  color: torchState == TorchState.on ? AppColors.secondaryGold : Colors.grey,
                ),
                onPressed: () => controller.toggleTorch(),
              );
            },
          ),
          // Lens Swapping Button
          ValueListenableBuilder<MobileScannerState>(
            valueListenable: controller,
            builder: (context, state, child) {
              final facing = state.cameraFacing;
              return IconButton(
                color: Colors.white,
                iconSize: 26.0,
                icon: Icon(
                  facing == CameraFacing.front ? Icons.camera_front : Icons.camera_rear,
                  color: facing == CameraFacing.front ? AppColors.secondaryGold : Colors.white,
                ),
                onPressed: () => controller.switchCamera(),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // 1. Mobile Camera Scanner stream
          MobileScanner(
            controller: controller,
            onDetect: (capture) {
              if (_isScanned) return;

              final List<Barcode> barcodes = capture.barcodes;
              if (barcodes.isNotEmpty) {
                final String? rawValue = barcodes.first.rawValue;
                if (rawValue != null && rawValue.isNotEmpty) {
                  setState(() {
                    _isScanned = true;
                  });
                  // Trigger device feedback and slide back with scanned code
                  controller.stop();
                  Navigator.of(context).pop(rawValue);
                }
              }
            },
          ),
          
          // 2. Translucent dark overlay with a hollow scanner frame
          ColorFiltered(
            colorFilter: ColorFilter.mode(
              Colors.black.withOpacity(0.5),
              BlendMode.srcOut,
            ),
            child: Stack(
              children: [
                Container(
                  decoration: const BoxDecoration(
                    color: Colors.transparent,
                  ),
                ),
                Align(
                  alignment: Alignment.center,
                  child: Container(
                    width: 260,
                    height: 260,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 3. Premium Gold Corner Border rings and Maroon Scanning Laser line
          Align(
            alignment: Alignment.center,
            child: SizedBox(
              width: 270,
              height: 270,
              child: Stack(
                children: [
                  // Gold corners
                  Positioned(
                    top: 0,
                    left: 0,
                    child: _buildScannerCorner(top: true, left: true),
                  ),
                  Positioned(
                    top: 0,
                    right: 0,
                    child: _buildScannerCorner(top: true, left: false),
                  ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    child: _buildScannerCorner(top: false, left: true),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: _buildScannerCorner(top: false, left: false),
                  ),

                  // Pulsing scanning laser bar indicator
                  const Align(
                    alignment: Alignment.center,
                    child: _PulsingLaserLine(),
                  ),
                ],
              ),
            ),
          ),

          // 4. Instructional caption text
          Positioned(
            bottom: 60,
            left: 20,
            right: 20,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: AppColors.secondaryGold.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.center_focus_weak, color: AppColors.secondaryGold, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Align barcode inside the gold frame',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScannerCorner({required bool top, required bool left}) {
    const double size = 30.0;
    const double thickness = 4.0;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          Positioned(
            top: top ? 0 : null,
            bottom: top ? null : 0,
            left: left ? 0 : null,
            right: left ? null : 0,
            child: Container(
              width: size,
              height: thickness,
              color: AppColors.secondaryGold,
            ),
          ),
          Positioned(
            top: top ? 0 : null,
            bottom: top ? null : 0,
            left: left ? 0 : null,
            right: left ? null : 0,
            child: Container(
              width: thickness,
              height: size,
              color: AppColors.secondaryGold,
            ),
          ),
        ],
      ),
    );
  }
}

// Custom animated laser line widget
class _PulsingLaserLine extends StatefulWidget {
  const _PulsingLaserLine();

  @override
  State<_PulsingLaserLine> createState() => _PulsingLaserLineState();
}

class _PulsingLaserLineState extends State<_PulsingLaserLine> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: -100.0, end: 100.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _animation.value),
          child: Container(
            width: 240,
            height: 3,
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryMaroon.withOpacity(0.8),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
              gradient: LinearGradient(
                colors: [
                  AppColors.primaryMaroon.withOpacity(0.1),
                  AppColors.primaryMaroon,
                  AppColors.primaryMaroon.withOpacity(0.1),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
