import 'user_role.dart';

/// Mirrors the MongoDB `User` document — backend never returns `hashPassword`.
///
/// We accept both the full server payload and partial payloads (PATCH /me only
/// echoes the changed fields). Optional fields default to null.
class UserModel {
  final String id;
  final String username;
  final String email;
  final String displayName;

  /// URL Cloudinary trả về từ endpoint upload avatar. `null` nếu user chưa
  /// upload avatar. Backend lưu trong `avatar.secureUrl`.
  final String? avatarUrl;

  /// Cloudinary public_id — cần thiết để xóa file cũ khi user upload lại.
  final String? avatarPublicId;

  final String? bio;
  final String? occupationId;
  final String? occupationName; // optional — populated when /me returns it
  final String? occupationCategoryId;
  final String? occupationCategoryName;
  final int streak;
  final int xp;
  final UserRole role;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const UserModel({
    required this.id,
    required this.username,
    required this.email,
    required this.displayName,
    this.avatarUrl,
    this.avatarPublicId,
    this.bio,
    this.occupationId,
    this.occupationName,
    this.occupationCategoryId,
    this.occupationCategoryName,
    this.streak = 0,
    this.xp = 0,
    this.role = UserRole.user,
    this.createdAt,
    this.updatedAt,
  });

  /// Returns the two-letter initials from displayName / username.
  String get initials {
    final source = (displayName.isNotEmpty ? displayName : username).trim();
    final parts = source.split(RegExp(r"\s+")).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return "?";
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }

  bool get hasAvatar => avatarUrl != null && avatarUrl!.isNotEmpty;

  /// Backward-compatible alias — các widget cũ vẫn đọc `user.avatar`.
  String? get avatar => avatarUrl;

  UserModel copyWith({
    String? id,
    String? username,
    String? email,
    String? displayName,
    String? avatarUrl,
    bool clearAvatar = false,
    String? avatarPublicId,
    String? bio,
    bool clearBio = false,
    String? occupationId,
    bool clearOccupationId = false,
    String? occupationName,
    String? occupationCategoryId,
    bool clearOccupationCategoryId = false,
    String? occupationCategoryName,
    int? streak,
    int? xp,
    UserRole? role,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      avatarUrl: clearAvatar ? null : (avatarUrl ?? this.avatarUrl),
      avatarPublicId:
          clearAvatar ? null : (avatarPublicId ?? this.avatarPublicId),
      bio: clearBio ? null : (bio ?? this.bio),
      occupationId:
          clearOccupationId ? null : (occupationId ?? this.occupationId),
      occupationName: occupationName ?? this.occupationName,
      occupationCategoryId: clearOccupationCategoryId
          ? null
          : (occupationCategoryId ?? this.occupationCategoryId),
      occupationCategoryName:
          occupationCategoryName ?? this.occupationCategoryName,
      streak: streak ?? this.streak,
      xp: xp ?? this.xp,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final id = (json["_id"] ?? json["id"] ?? "").toString();
    final username = (json["username"] ?? "").toString();
    final email = (json["email"] ?? "").toString();
    final displayName = (json["displayName"] ?? username).toString();

    String? readString(Object? value) {
      if (value == null) return null;
      final str = value.toString();
      if (str.startsWith("Instance of")) return null;
      return str.isEmpty ? null : str;
    }

    // Backend lưu avatar dưới dạng { publicId, secureUrl }.
    String? avatarUrl;
    String? avatarPublicId;
    final rawAvatar = json["avatar"];
    if (rawAvatar is Map) {
      avatarUrl = readString(rawAvatar["secureUrl"]);
      avatarPublicId = readString(rawAvatar["publicId"]);
    } else if (rawAvatar is String && rawAvatar.isNotEmpty) {
      // Fallback nếu backend trả thẳng string (chỉ dành cho seed/test).
      avatarUrl = rawAvatar;
    }

    int readInt(Object? v) {
      if (v is int) return v;
      return int.tryParse((v ?? "0").toString()) ?? 0;
    }

    return UserModel(
      id: id,
      username: username,
      email: email,
      displayName: displayName,
      avatarUrl: avatarUrl,
      avatarPublicId: avatarPublicId,
      bio: readString(json["bio"]),
      occupationId: readString(json["occupationId"]),
      occupationName: readString(json["occupationName"]),
      occupationCategoryId: readString(json["occupationCategoryId"]),
      occupationCategoryName: readString(json["occupationCategoryName"]),
      streak: readInt(json["streak"]),
      xp: readInt(json["xp"]),
      role: UserRole.fromString(json["role"]?.toString()),
      createdAt: DateTime.tryParse(json["createdAt"]?.toString() ?? ""),
      updatedAt: DateTime.tryParse(json["updatedAt"]?.toString() ?? ""),
    );
  }

  Map<String, dynamic> toJson() => {
        "_id": id,
        "username": username,
        "email": email,
        "displayName": displayName,
        if (avatarUrl != null || avatarPublicId != null)
          "avatar": {
            if (avatarPublicId != null) "publicId": avatarPublicId,
            if (avatarUrl != null) "secureUrl": avatarUrl,
          },
        if (bio != null) "bio": bio,
        if (occupationId != null) "occupationId": occupationId,
        if (occupationName != null) "occupationName": occupationName,
        if (occupationCategoryId != null)
          "occupationCategoryId": occupationCategoryId,
        if (occupationCategoryName != null)
          "occupationCategoryName": occupationCategoryName,
        "streak": streak,
        "xp": xp,
        "role": role.apiValue,
        if (createdAt != null) "createdAt": createdAt!.toIso8601String(),
        if (updatedAt != null) "updatedAt": updatedAt!.toIso8601String(),
      };
}