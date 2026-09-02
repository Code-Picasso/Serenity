import 'package:flutter/foundation.dart';

/// Global, compile-time application configuration.
///
/// The API base URL can be overridden at build/run time with:
///   flutter run --dart-define=API_BASE_URL=http://192.168.1.10:8000
///
/// Defaults (when no `--dart-define` is supplied):
///   - Android emulator:        http://10.0.2.2:8000
///   - iOS simulator/desktop/web: http://localhost:8000
///   - Physical device:         use your machine's LAN IP (see docs/FRONTEND.md).
class AppConfig {
  AppConfig._();

  static const String appName = 'Serenity';
  static const String appTagline = 'Read. Share. Connect.';

  static const String _apiBaseUrlOverride = String.fromEnvironment('API_BASE_URL');
  static const String _socketUrlOverride = String.fromEnvironment('SOCKET_URL');

  /// The gateway host. `10.0.2.2` is the Android emulator's alias for the host
  /// loopback; everywhere else `localhost` is correct (the iOS simulator and
  /// desktop share the host network, and web is served from the host).
  static String get baseUrl {
    if (_apiBaseUrlOverride.isNotEmpty) return _apiBaseUrlOverride;
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8000';
    }
    return 'http://localhost:8000';
  }

  /// Path where the Socket.IO server is reachable (through the gateway).
  static String get socketUrl {
    if (_socketUrlOverride.isNotEmpty) return _socketUrlOverride;
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8000';
    }
    return 'http://localhost:8000';
  }

  static const String logoAsset = 'assets/logo.png';

  static const int pageSize = 20;
}
