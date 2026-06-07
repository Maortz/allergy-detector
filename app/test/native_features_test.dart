import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:app/services/image_service.dart';
import 'package:app/services/scanner_service.dart';

void main() {
  group('ImageService', () {
    test('should have pickFromGallery method', () {
      final service = ImageService();
      expect(service.pickFromGallery, isNotNull);
    });

    test('should have pickFromCamera method', () {
      final service = ImageService();
      expect(service.pickFromCamera, isNotNull);
    });
  });

  group('ScannerService', () {
    test('should have isWeb getter', () {
      final service = ScannerService();
      expect(service.isWeb, isA<bool>());
    });

    test('should have initialize method', () {
      final service = ScannerService();
      expect(service.initialize, isNotNull);
    });

    test('should have dispose method', () {
      final service = ScannerService();
      expect(service.dispose, isNotNull);
    });

    // -----------------------------------------------------------------------
    // isPermissionDenied — issue #52
    // Verifies that the static helper correctly identifies the permissionDenied
    // error code so that SearchScanScreen.onScannerError can route it to the
    // _cameraDenied state.
    // -----------------------------------------------------------------------
    test('isPermissionDenied returns true for permissionDenied error code', () {
      expect(
        ScannerService.isPermissionDenied(MobileScannerErrorCode.permissionDenied),
        isTrue,
      );
    });

    test('isPermissionDenied returns false for non-permission error codes', () {
      for (final code in MobileScannerErrorCode.values) {
        if (code == MobileScannerErrorCode.permissionDenied) continue;
        expect(
          ScannerService.isPermissionDenied(code),
          isFalse,
          reason: 'Expected false for $code',
        );
      }
    });
  });
}

