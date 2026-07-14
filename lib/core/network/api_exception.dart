/// Thrown by repositories when a backend call returns
/// `{ success: false, message: "..." }` or a network failure happens.
///
/// Carries the friendly Vietnamese message so screens can show it directly.
class ApiException implements Exception {
  final String message;
  final int? statusCode;

  const ApiException(this.message, {this.statusCode});

  @override
  String toString() => "ApiException($statusCode): $message";
}

/// Used internally by the interceptor to signal that token refresh failed
/// and the request should be rejected (and the user redirected to /login).
class AuthExpiredException extends ApiException {
  const AuthExpiredException([
    super.message = "Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.",
  ]) : super(statusCode: 401);
}
