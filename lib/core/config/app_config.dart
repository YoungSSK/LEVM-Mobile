import 'package:flutter/foundation.dart';

/// API base URL. Order of precedence:
///
/// 1. `--dart-define=API_BASE_URL=https://...`  (e.g. for prod / staging / LAN)
/// 2. Platform default:
///     - `kIsWeb`         → http://localhost:5001/api
///     - Android emulator → http://10.0.2.2:5001/api
///     - iOS simulator    → http://localhost:5001/api
///     - Windows / Mac    → http://localhost:5001/api
class AppConfig {
  AppConfig._();

  /// Override at build/run time:
  ///   flutter run --dart-define=API_BASE_URL=http://192.168.1.10:5001/api
  static const String _overrideBaseUrl =
      String.fromEnvironment('API_BASE_URL');

  /// Some Android emulators don't forward localhost. Set this to true to
  /// force using the emulator-special host alias 10.0.2.2 instead.
  ///   flutter run --dart-define=USE_ANDROID_EMULATOR_HOST=true
  static const bool _useAndroidEmulatorHost =
      bool.fromEnvironment('USE_ANDROID_EMULATOR_HOST');

  /// Whether we should target the Android emulator host alias.
  static bool get _shouldUseEmulatorHost {
    if (_overrideBaseUrl.isNotEmpty) return false;
    if (kIsWeb) return false;
    if (defaultTargetPlatform != TargetPlatform.android) return false;
    return _useAndroidEmulatorHost;
  }

  static String get baseUrl {
    if (_overrideBaseUrl.isNotEmpty) return _overrideBaseUrl;
    if (_shouldUseEmulatorHost) return 'http://10.0.2.2:5001/api';
    return 'http://localhost:5001/api';
  }

  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
}
