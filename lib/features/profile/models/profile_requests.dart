/// Payload cho PATCH /users/me — chỉ gửi các field thay đổi.
///
/// Lưu ý: avatar KHÔNG được gửi qua đây. Avatar phải upload riêng qua
/// endpoint `PATCH /users/avatar` (multipart/form-data) để backend đẩy lên
/// Cloudinary và trả về `{ publicId, secureUrl }`.
class UpdateProfileRequest {
  final String? displayName;
  final String? bio;
  final String? occupationId;
  final String? occupationCategoryId;

  const UpdateProfileRequest({
    this.displayName,
    this.bio,
    this.occupationId,
    this.occupationCategoryId,
  });

  bool get isEmpty =>
      displayName == null &&
      bio == null &&
      occupationId == null &&
      occupationCategoryId == null;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (displayName != null) map["displayName"] = displayName;
    if (bio != null) map["bio"] = bio;
    if (occupationId != null) map["occupationId"] = occupationId;
    if (occupationCategoryId != null) {
      map["occupationCategoryId"] = occupationCategoryId;
    }
    return map;
  }
}

/// Payload cho PATCH /users/change-password.
class ChangePasswordRequest {
  final String oldPassword;
  final String newPassword;
  final String confirmPassword;

  const ChangePasswordRequest({
    required this.oldPassword,
    required this.newPassword,
    required this.confirmPassword,
  });

  Map<String, dynamic> toJson() => {
        "oldPassword": oldPassword,
        "newPassword": newPassword,
        "confirmPassword": confirmPassword,
      };
}

/// Response trả về từ endpoint upload avatar (`PATCH /users/avatar`).
class UploadedAvatar {
  final String publicId;
  final String secureUrl;

  const UploadedAvatar({required this.publicId, required this.secureUrl});

  factory UploadedAvatar.fromJson(Map<String, dynamic> json) {
    return UploadedAvatar(
      publicId: (json["publicId"] ?? "").toString(),
      secureUrl: (json["secureUrl"] ?? "").toString(),
    );
  }
}