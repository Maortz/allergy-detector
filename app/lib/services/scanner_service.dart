import 'package:flutter/foundation.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class ScannerService {
  MobileScannerController? _controller;
  
  bool get isWeb => kIsWeb;
  
  MobileScannerController? get controller => _controller;
  
  Future<void> initialize() async {
    if (kIsWeb) return;
    _controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
      torchEnabled: false,
    );
  }
  
  void dispose() {
    _controller?.dispose();
    _controller = null;
  }
}