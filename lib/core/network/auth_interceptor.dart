import 'dart:async';

import 'package:dio/dio.dart';

import '../constants/storage_keys.dart';
import '../services/secure_storage_service.dart';
import '../../features/auth/services/auth_api.dart';
import 'dio_client.dart';

/// Attaches `Authorization: Bearer <accessToken>` to every request,
/// and on 401 tries to refresh via `/auth/refresh` once using the
/// stored refresh token.
///
/// We send the refresh token via the `x-refresh-token` header rather
/// than relying on the cookie because:
///   - The Flutter app doesn't share the user's browser cookie jar
///   - Cookies with `secure: true` won't be set over plain http://10.0.2.2
///
/// Concurrent 401s share a single refresh promise to avoid stampedes.
class AuthInterceptor extends Interceptor {
  AuthInterceptor();

  /// Single in-flight refresh shared across simultaneous 401s.
  Future<String>? _pendingRefresh;

  /// Marker so a retry triggered by [onError] doesn't loop infinitely.
  static const String _retriedKey = "_levm_retried";

  /// Header key used to forward the refresh token to `/auth/refresh`.
  static const String _refreshHeader = "x-refresh-token";

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await SecureStorageService.read(StorageKeys.accessToken);
    if (token != null && token.isNotEmpty) {
      options.headers["Authorization"] = "Bearer $token";
    }
    handler.next(options);
  }

  @override
  void onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final status = err.response?.statusCode;
    final alreadyRetried = err.requestOptions.extra[_retriedKey] == true;

    if (status != 401 || alreadyRetried) {
      handler.next(err);
      return;
    }

    final refreshToken =
        await SecureStorageService.read(StorageKeys.refreshToken);
    if (refreshToken == null || refreshToken.isEmpty) {
      handler.next(err);
      return;
    }

    try {
      final newAccess = await (_pendingRefresh ??= _doRefresh(refreshToken));
      await SecureStorageService.write(
        key: StorageKeys.accessToken,
        value: newAccess,
      );

      // Retry the original request with the new token.
      final req = err.requestOptions;
      req.headers["Authorization"] = "Bearer $newAccess";
      req.extra[_retriedKey] = true;

      final dio = Dio(BaseOptions(
        baseUrl: req.baseUrl,
        connectTimeout: req.connectTimeout,
        receiveTimeout: req.receiveTimeout,
        headers: req.headers,
      ));
      final response = await dio.fetch<dynamic>(req);
      handler.resolve(response);
    } catch (_) {
      // Refresh failed — wipe tokens; user must log in again.
      await AuthApi.clearTokens();
      handler.next(err);
    } finally {
      _pendingRefresh = null;
    }
  }

  Future<String> _doRefresh(String refreshToken) async {
    // Fresh Dio so we don't recurse through this interceptor.
    final baseUrl = DioClient.dio.options.baseUrl;
    final dio = Dio(BaseOptions(baseUrl: baseUrl));
    final res = await dio.post(
      "/auth/refresh",
      options: Options(headers: {_refreshHeader: refreshToken}),
    );
    final body = (res.data is Map<String, dynamic>)
        ? res.data as Map<String, dynamic>
        : <String, dynamic>{};
    final newAccess = (body["accessToken"] ?? "").toString();
    if (newAccess.isEmpty) {
      throw Exception("Refresh token không hợp lệ");
    }
    return newAccess;
  }
}
