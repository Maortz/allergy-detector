import 'package:flutter/foundation.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';

class ScannerService {
  MobileScannerController? _controller;

  bool get isWeb => kIsWeb;

  MobileScannerController? get controller => _controller;

  /// Returns true when [errorCode] indicates the user denied camera permission.
  static bool isPermissionDenied(MobileScannerErrorCode errorCode) =>
      errorCode == MobileScannerErrorCode.permissionDenied;

  /// Whether the OS has *permanently* denied camera access (the user picked
  /// "don't ask again" / revoked it in Settings). In that state a fresh
  /// permission request is a no-op, so the UI must deep-link to system
  /// settings instead of re-prompting.
  ///
  /// Overridable so widget tests can drive both branches without a real OS
  /// permission backend.
  Future<bool> isCameraPermissionPermanentlyDenied() =>
      Permission.camera.isPermanentlyDenied;

  /// Opens the OS app-settings page so the user can grant camera access.
  /// Overridable in tests. Returns whether the settings page opened.
  Future<bool> openSettings() => openAppSettings();

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