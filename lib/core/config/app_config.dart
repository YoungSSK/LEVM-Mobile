import 'package:flutter/foundation.dart';

/// API base URL. Order of precedence:
///
/// 1. `--dart-define=API_BASE_URL=https://...`  (e.g. for prod / staging / LAN)
/// 2. Platform default:
///     - `kIsWeb`              → http://localhost:5001/api
///     - Android emulator      → http://10.0.2.2:5001/api
///                              (set --dart-define=FORCE_LOCALHOST_HOST=true
///                               to force `localhost` instead)
///     - iOS simulator         → http://localhost:5001/api
///     - Windows / Mac desktop → http://localhost:5001/api
class AppConfig {
  AppConfig._();

  /// Override at build/run time:
  ///   flutter run --dart-define=API_BASE_URL=http://192.168.1.10:5001/api
  static const String _overrideBaseUrl =
      String.fromEnvironment('API_BASE_URL');

  /// Opt-out flag: Android emulator mặc định đã trỏ về `10.0.2.2` (alias của
  /// `localhost` trên host). Bật flag này nếu bạn đang forward cổng kiểu
  /// `adb reverse tcp:5001 tcp:5001` và muốn dùng `localhost` thay thế.
  ///   flutter run --dart-define=FORCE_LOCALHOST_HOST=true
  static const bool _forceLocalhostHost =
      bool.fromEnvironment('FORCE_LOCALHOST_HOST');

  /// Mặc định Android emulator trỏ về 10.0.2.2 (host loopback) để tránh
  /// "Connection refused" do emulator không forward `localhost` của máy host.
  static bool get _shouldUseEmulatorHost {
    if (_overrideBaseUrl.isNotEmpty) return false;
    if (kIsWeb) return false;
    if (defaultTargetPlatform != TargetPlatform.android) return false;
    return !_forceLocalhostHost;
  }

  static String get baseUrl {
    if (_overrideBaseUrl.isNotEmpty) return _overrideBaseUrl;
    if (_shouldUseEmulatorHost) return 'http://10.0.2.2:5001/api';
    return 'http://localhost:5001/api';
  }

  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
}
