import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart' show XFile;

import '../../../core/network/dio_client.dart';
import '../models/profile_requests.dart';
import '../models/user_model.dart';
import '_io_file_native.dart' if (dart.library.html) '_io_file_web.dart'
    as io_file;

class ProfileApi {
  ProfileApi({Dio? dio}) : _dio = dio ?? DioClient.dio;

  final Dio _dio;

  Future<UserModel> getMe() async {
    try {
      final res = await _dio.get("/users/me");
      final body = (res.data is Map<String, dynamic>)
          ? res.data as Map<String, dynamic>
          : <String, dynamic>{};
      // Accept both `data` envelope and a raw user object.
      final data = body["data"] is Map<String, dynamic>
          ? body["data"] as Map<String, dynamic>
          : body;
      return UserModel.fromJson(data);
    } on DioException catch (e) {
      throw _translateError(e);
    }
  }

  Future<UserModel> updateMe(UpdateProfileRequest payload) async {
    if (payload.isEmpty) {
      throw Exception("Bạn chưa thay đổi thông tin nào.");
    }
    try {
      final res = await _dio.patch("/users/me", data: payload.toJson());
      final body = (res.data is Map<String, dynamic>)
          ? res.data as Map<String, dynamic>
          : <String, dynamic>{};
      final data = body["data"] is Map<String, dynamic>
          ? body["data"] as Map<String, dynamic>
          : body;
      return UserModel.fromJson(data);
    } on DioException catch (e) {
      throw _translateError(e);
    }
  }

  /// Upload avatar lên Cloudinary qua `PATCH /users/avatar` (multipart).
  /// Backend trả về `{ avatar: { publicId, secureUrl } }`.
  ///
  /// Chấp nhận cả `XFile` (từ `ImagePicker`) lẫn `String filePath` để giữ
  /// tương thích với code cũ. Trên Flutter web, `XFile.path` trả về
  /// `blob:http://...` nên bắt buộc phải dùng `readAsBytes()` +
  /// `MultipartFile.fromBytes()` thay vì `MultipartFile.fromFile()` (CORS /
  /// file-system error).
  Future<UploadedAvatar> uploadAvatar(dynamic fileOrPath) async {
    try {
      final List<int> bytes;
      final String filename;

      if (fileOrPath is XFile) {
        bytes = await fileOrPath.readAsBytes();
        filename = fileOrPath.name.isNotEmpty
            ? fileOrPath.name
            : 'avatar.jpg';
      } else if (fileOrPath is String) {
        if (kIsWeb) {
          throw Exception(
            'Trên web cần truyền XFile từ ImagePicker, không truyền path.',
          );
        }
        bytes = io_file.readFileBytes(fileOrPath);
        filename = fileOrPath.split('/').last;
      } else {
        throw Exception('Tham số uploadAvatar không hợp lệ.');
      }

      final form = FormData.fromMap({
        // Field name phải trùng với `uploadAvatar.single("avatar")` ở backend.
        'avatar': MultipartFile.fromBytes(
          bytes,
          filename: filename,
          contentType: _guessContentType(filename),
        ),
      });
      final res = await _dio.patch(
        '/users/avatar',
        data: form,
        options: Options(
          headers: {
            // Để Dio tự set Content-Type kèm boundary cho multipart.
            'Content-Type': 'multipart/form-data',
          },
        ),
      );
      final body = (res.data is Map<String, dynamic>)
          ? res.data as Map<String, dynamic>
          : <String, dynamic>{};
      final data = body['data'] is Map<String, dynamic>
          ? body['data'] as Map<String, dynamic>
          : body;
      // Có 2 shape: { data: { avatar: { publicId, secureUrl } } } hoặc
      // { data: { publicId, secureUrl } } (tuỳ phiên bản controller).
      final avatarMap = data['avatar'] is Map<String, dynamic>
          ? data['avatar'] as Map<String, dynamic>
          : data;
      return UploadedAvatar.fromJson(avatarMap);
    } on DioException catch (e) {
      throw _translateError(e);
    }
  }

  Future<String> changePassword({
    required String oldPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    try {
      final res = await _dio.patch(
        '/users/change-password',
        data: {
          'oldPassword': oldPassword,
          'newPassword': newPassword,
          'confirmPassword': confirmPassword,
        },
      );
      final body = (res.data is Map<String, dynamic>)
          ? res.data as Map<String, dynamic>
          : <String, dynamic>{};
      return (body['message'] ?? 'Đổi mật khẩu thành công!').toString();
    } on DioException catch (e) {
      throw _translateError(e);
    }
  }

  /// Đoán MIME type từ đuôi file để backend multer nhận đúng.
  DioMediaType _guessContentType(String filename) {
    final lower = filename.toLowerCase();
    if (lower.endsWith('.png')) return DioMediaType('image', 'png');
    if (lower.endsWith('.webp')) return DioMediaType('image', 'webp');
    if (lower.endsWith('.gif')) return DioMediaType('image', 'gif');
    if (lower.endsWith('.heic') || lower.endsWith('.heif')) {
      return DioMediaType('image', 'heic');
    }
    return DioMediaType('image', 'jpeg');
  }

  Exception _translateError(DioException e) {
    final status = e.response?.statusCode;
    final data = e.response?.data;
    String? backendMessage;
    if (data is Map && data['message'] != null) {
      backendMessage = data['message'].toString();
    }
    if (e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return Exception(backendMessage ?? 'Mạng chưa ổn, bạn thử lại nhé.');
    }
    if (status == 401) {
      return Exception(
        backendMessage ?? 'Phiên đăng nhập đã hết hạn.',
      );
    }
    if (status == 413) {
      return Exception('Ảnh quá lớn, vui lòng chọn ảnh dưới 5MB.');
    }
    if (status != null && status >= 500) {
      return Exception(backendMessage ?? 'Máy chủ đang bận.');
    }
    return Exception(backendMessage ?? 'Đã có lỗi xảy ra, bạn thử lại.');
  }
}

