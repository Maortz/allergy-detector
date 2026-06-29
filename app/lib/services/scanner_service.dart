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

  /// Initialises the [MobileScannerController].
  ///
  /// Creates the controller on every platform, including web: mounting a
  /// [MobileScanner] with it triggers the browser's `getUserMedia`
  /// camera-permission prompt (issue #332). Callers that want a manual-only
  /// experience (e.g. [SearchScanScreen] on web) simply skip calling this.
  Future<void> initialize() async {
    _controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      // On web, CameraFacing.back maps to getUserMedia facingMode:'environment',
      // which most laptop/desktop browsers lack — the request can fail or
      // silently fall back. Prefer the front camera on web for predictability;
      // native devices keep the rear camera for barcode scanning.
      facing: kIsWeb ? CameraFacing.front : CameraFacing.back,
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