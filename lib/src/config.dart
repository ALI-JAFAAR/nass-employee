class AppConfig {
  /// Change this to your Laravel server base URL (without trailing slash).
  ///
  /// Examples:
  /// - Android emulator: http://10.0.2.2:8000
  /// - iOS simulator: http://127.0.0.1:8000
  /// - Device on LAN: http://192.168.1.10:8000
  /// Production build example:
  /// `flutter build apk --release --dart-define=API_BASE_URL=https://your-domain.com`
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://127.0.0.1:8000',
    // defaultValue: 'https://nassiq.com/backend/public',
  );
}
