import 'package:flutter/foundation.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class ScannerService {
  MobileScannerController? _controller;

  bool get isWeb => kIsWeb;

  MobileScannerController? get controller => _controller;

  /// Returns true when [errorCode] indicates the user denied camera permission.
  static bool isPermissionDenied(MobileScannerErrorCode errorCode) =>
      errorCode == MobileScannerErrorCode.permissionDenied;

  /// Initialises [MobileScannerController] on native platforms.
  ///
  /// On web this is a no-op — the screen renders a manual-entry fallback.
  Future<void> initialize() async {
    if (kIsWeb) return;
    _controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
      torchEnabled: false,
    );
    // Note: the controller starts automatically when a MobileScanner widget
    // mounts it (autoStart defaults to true).  Permission errors surface via
    // MobileScanner.errorBuilder — see SearchScanScreen._buildScannerSection.
  }

  void dispose() {
    _controller?.dispose();
    _controller = null;
  }
}