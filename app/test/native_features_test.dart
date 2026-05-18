import 'package:flutter_test/flutter_test.dart';
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
  });
}
