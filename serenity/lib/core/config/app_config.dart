/// Global, compile-time application configuration.
///
/// The API base URL can be overridden at build/run time with:
///   flutter run --dart-define=API_BASE_URL=http://192.168.1.10:8000
///
/// Defaults:
///   - Android emulator: http://10.0.2.2:8000
///   - iOS simulator:    http://localhost:8000
///   - Physical device:  use your machine's LAN IP (see docs/FRONTEND.md).
class AppConfig {
  AppConfig._();

  static const String appName = 'Serenity';
  static const String appTagline = 'Read. Share. Connect.';

  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8000',
  );

  /// Path where the Socket.IO server is reachable (through the gateway).
  static const String socketUrl = String.fromEnvironment(
    'SOCKET_URL',
    defaultValue: 'http://10.0.2.2:8000',
  );

  static const String logoAsset = 'assets/logo.png';

  static const int pageSize = 20;
}
