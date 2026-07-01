import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Immutable snapshot of the technical context attached to an AI feedback
/// session. It is injected into the Gemini system prompt and appended to the
/// generated GitHub issue so maintainers receive device/build metadata without
/// having to ask the user for it (issue #337 — "invisible" context enrichment).
@immutable
class DeviceContext {
  final String appName;
  final String appVersion;
  final String buildNumber;

  /// e.g. "Android", "iOS", "Web".
  final String platform;

  /// OS release string, e.g. "14" (Android) or "17.4" (iOS). May be empty.
  final String osVersion;

  /// Human device/browser model, e.g. "Pixel 7" or "Chrome". May be empty.
  final String deviceModel;

  const DeviceContext({
    required this.appName,
    required this.appVersion,
    required this.buildNumber,
    required this.platform,
    required this.osVersion,
    required this.deviceModel,
  });

  /// Placeholder used before the real context has been gathered, or when a
  /// platform channel is unavailable (e.g. in a unit test host).
  static const DeviceContext unknown = DeviceContext(
    appName: '—',
    appVersion: '—',
    buildNumber: '—',
    platform: '—',
    osVersion: '—',
    deviceModel: '—',
  );

  /// Compact, human-readable multi-line block embedded in the AI system prompt
  /// and in the final issue footer. Pure — unit-tested directly.
  String toPromptBlock() {
    final buffer = StringBuffer()
      ..writeln('App: $appName $appVersion ($buildNumber)')
      ..writeln('Platform: $platform')
      ..writeln('OS version: $osVersion')
      ..write('Device: $deviceModel');
    return buffer.toString();
  }
}

/// Gathers [DeviceContext] from `package_info_plus` + `device_info_plus`.
///
/// The plugin instances are injectable so the gathering path is exercisable in
/// tests, while [DeviceContext.toPromptBlock] holds the pure formatting logic.
class DeviceContextService {
  final DeviceInfoPlugin _deviceInfo;

  DeviceContextService({DeviceInfoPlugin? deviceInfo})
    : _deviceInfo = deviceInfo ?? DeviceInfoPlugin();

  Future<DeviceContext> gather() async {
    final package = await PackageInfo.fromPlatform();

    var platform = '—';
    var osVersion = '—';
    var deviceModel = '—';

    try {
      if (kIsWeb) {
        final web = await _deviceInfo.webBrowserInfo;
        platform = 'Web';
        osVersion = web.platform ?? '—';
        deviceModel = web.browserName.name;
      } else {
        switch (defaultTargetPlatform) {
          case TargetPlatform.android:
            final android = await _deviceInfo.androidInfo;
            platform = 'Android';
            osVersion = android.version.release;
            deviceModel = '${android.manufacturer} ${android.model}';
          case TargetPlatform.iOS:
            final ios = await _deviceInfo.iosInfo;
            platform = 'iOS';
            osVersion = ios.systemVersion;
            deviceModel = ios.utsname.machine;
          case _:
            platform = defaultTargetPlatform.name;
        }
      }
    } catch (e, st) {
      // Device probing must never block the feedback flow — fall back to the
      // package info alone and log for diagnostics.
      debugPrint('DeviceContextService.gather device probe failed: $e\n$st');
    }

    return DeviceContext(
      appName: package.appName,
      appVersion: package.version,
      buildNumber: package.buildNumber,
      platform: platform,
      osVersion: osVersion,
      deviceModel: deviceModel,
    );
  }
}
