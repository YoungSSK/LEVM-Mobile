/// Payload for POST /auth/login.
class LoginRequest {
  final String email;
  final String password;

  const LoginRequest({required this.email, required this.password});

  Map<String, dynamic> toJson() => {
        "email": email,
        "password": password,
      };
}

/// Response from POST /auth/login.
class LoginResponse {
  final String accessToken;
  final String refreshToken;
  final String role;
  final String message;

  const LoginResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.role,
    required this.message,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    final access = (json["accessToken"] ?? "").toString();
    final refresh =
        (json["refreshToken"] ?? json["refresh_token"] ?? "").toString();
    return LoginResponse(
      accessToken: access,
      refreshToken: refresh,
      role: (json["role"] ?? "user").toString(),
      message: (json["message"] ?? "").toString(),
    );
  }
}

/// Payload for POST /auth/register.
class RegisterRequest {
  final String username;
  final String email;
  final String password;

  const RegisterRequest({
    required this.username,
    required this.email,
    required this.password,
  });

  Map<String, dynamic> toJson() => {
        "username": username,
        "email": email,
        "password": password,
      };
}

/// Response from POST /auth/register (201, message-only).
class RegisterResponse {
  final String message;
  final int statusCode;

  const RegisterResponse({required this.message, required this.statusCode});

  factory RegisterResponse.fromJson(
    Map<String, dynamic> json, {
    int statusCode = 201,
  }) {
    return RegisterResponse(
      message: (json["message"] ?? "Đăng ký thành công").toString(),
      statusCode: statusCode,
    );
  }
}

/// Response from POST /auth/refresh.
class RefreshResponse {
  final String accessToken;

  const RefreshResponse({required this.accessToken});

  factory RefreshResponse.fromJson(Map<String, dynamic> json) {
    return RefreshResponse(
      accessToken: (json["accessToken"] ?? "").toString(),
    );
  }
}

/// Generic success/error envelope used across auth & user endpoints.
class ApiMessage {
  final String message;
  final int? statusCode;

  const ApiMessage({required this.message, this.statusCode});

  factory ApiMessage.fromJson(
    Map<String, dynamic> json, {
    int? statusCode,
  }) {
    return ApiMessage(
      message: (json["message"] ?? "").toString(),
      statusCode: statusCode,
    );
  }
}
