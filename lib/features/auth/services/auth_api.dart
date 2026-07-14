import 'package:dio/dio.dart';

import '../../../core/constants/storage_keys.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/services/secure_storage_service.dart';
import '../models/auth_models.dart';

/// Talks to `/auth/*` endpoints.
///
/// Responsibilities:
///  - Persist access/refresh tokens into secure storage
///  - Expose a public [refreshAccessToken] so the AuthInterceptor can call it
///    on a 401, with a single in-flight refresh promise to avoid stampedes.
class AuthApi {
  AuthApi({Dio? dio}) : _dio = dio ?? DioClient.dio;

  final Dio _dio;

  Future<LoginResponse> login({
    required String email,
    required String password,
  }) async {
    try {
      final res = await _dio.post(
        "/auth/login",
        data: {"email": email, "password": password},
      );
      final body = (res.data is Map<String, dynamic>)
          ? res.data as Map<String, dynamic>
          : <String, dynamic>{};
      return LoginResponse.fromJson(body);
    } on DioException catch (e) {
      throw _translateError(e);
    }
  }

  Future<RegisterResponse> register({
    required String username,
    required String email,
    required String password,
  }) async {
    try {
      final res = await _dio.post(
        "/auth/register",
        data: {
          "username": username,
          "email": email,
          "password": password,
        },
      );
      final body = (res.data is Map<String, dynamic>)
          ? res.data as Map<String, dynamic>
          : <String, dynamic>{};
      final code = res.statusCode ?? 201;
      return RegisterResponse.fromJson(body, statusCode: code);
    } on DioException catch (e) {
      throw _translateError(e);
    }
  }

  Future<void> logout() async {
    try {
      final refreshToken =
          await SecureStorageService.read(StorageKeys.refreshToken);
      // Mobile clients don't share cookies with the browser, so we
      // forward the refresh token in the body so the server can revoke it.
      await _dio.post(
        "/auth/logout",
        data: refreshToken != null && refreshToken.isNotEmpty
            ? {"refreshToken": refreshToken}
            : null,
      );
    } on DioException {
      // Logout is best-effort — even if the server call fails we clear locally.
    }
  }

  /// Uses the stored refresh token in the `x-refresh-token` header to obtain
  /// a fresh access token. Returns the new access token.
  Future<String> refreshAccessToken() async {
    final refreshToken =
        await SecureStorageService.read(StorageKeys.refreshToken);
    if (refreshToken == null || refreshToken.isEmpty) {
      throw Exception("Không tìm thấy refresh token");
    }
    final res = await _dio.post(
      "/auth/refresh",
      options: Options(headers: {"x-refresh-token": refreshToken}),
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

  // --- token persistence -------------------------------------------------

  static Future<void> saveTokens({
    required String accessToken,
    String? refreshToken,
  }) async {
    await SecureStorageService.write(
      key: StorageKeys.accessToken,
      value: accessToken,
    );
    if (refreshToken != null && refreshToken.isNotEmpty) {
      await SecureStorageService.write(
        key: StorageKeys.refreshToken,
        value: refreshToken,
      );
    }
  }

  static Future<void> clearTokens() async {
    await SecureStorageService.delete(StorageKeys.accessToken);
    await SecureStorageService.delete(StorageKeys.refreshToken);
  }

  // --- helpers -----------------------------------------------------------

  Exception _translateError(DioException e) {
    final status = e.response?.statusCode;
    final data = e.response?.data;

    String? backendMessage;
    if (data is Map && data["message"] != null) {
      backendMessage = data["message"].toString();
    }

    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.transformTimeout:
        return Exception(
          backendMessage ?? "Kết nối quá chậm, bạn thử lại nhé.",
        );
      case DioExceptionType.connectionError:
        return Exception(
          backendMessage ??
              "Không thể kết nối đến máy chủ. Kiểm tra mạng rồi thử lại.",
        );
      case DioExceptionType.badCertificate:
        return Exception("Chứng chỉ bảo mật không hợp lệ.");
      case DioExceptionType.cancel:
        return Exception("Yêu cầu đã bị huỷ.");
      case DioExceptionType.badResponse:
      case DioExceptionType.unknown:
        if (status == 401) {
          return Exception(
            backendMessage ?? "Email hoặc mật khẩu chưa đúng.",
          );
        }
        if (status == 403) {
          return Exception(backendMessage ?? "Bạn không có quyền truy cập.");
        }
        if (status == 404) {
          return Exception(backendMessage ?? "Không tìm thấy tài nguyên.");
        }
        if (status == 409) {
          return Exception(
            backendMessage ?? "Thông tin đã tồn tại trong hệ thống.",
          );
        }
        if (status != null && status >= 500) {
          return Exception(
            backendMessage ?? "Máy chủ đang bận, bạn thử lại sau nhé.",
          );
        }
        return Exception(backendMessage ?? "Đã có lỗi xảy ra, bạn thử lại.");
    }
  }
}
