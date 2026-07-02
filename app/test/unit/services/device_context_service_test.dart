import 'package:app/services/device_context_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DeviceContext.toPromptBlock', () {
    test('formats all fields into a labelled multi-line block', () {
      const context = DeviceContext(
        appName: 'SafeBite',
        appVersion: '1.2.0',
        buildNumber: '42',
        platform: 'Android',
        osVersion: '14',
        deviceModel: 'Google Pixel 7',
      );

      final block = context.toPromptBlock();

      expect(block, contains('App: SafeBite 1.2.0 (42)'));
      expect(block, contains('Platform: Android'));
      expect(block, contains('OS version: 14'));
      expect(block, contains('Device: Google Pixel 7'));
    });

    test('unknown placeholder still renders every label', () {
      final block = DeviceContext.unknown.toPromptBlock();
      expect(block, contains('App:'));
      expect(block, contains('Platform:'));
      expect(block, contains('OS version:'));
      expect(block, contains('Device:'));
    });
  });
}
