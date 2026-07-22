import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/profile_api.dart';
import '../models/profile_requests.dart';
import '../models/user_model.dart';

final profileApiProvider = Provider<ProfileApi>((ref) => ProfileApi());

/// User đang đăng nhập hiện tại. `null` cho tới khi fetch xong.
class CurrentUserNotifier extends AsyncNotifier<UserModel?> {
  @override
  Future<UserModel?> build() async {
    try {
      final api = ref.read(profileApiProvider);
      return await api.getMe();
    } catch (_) {
      // Trả null thay vì error để UI hiển thị state empty thân thiện.
      return null;
    }
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final api = ref.read(profileApiProvider);
      return api.getMe();
    });
  }

  Future<UserModel> updateProfile(UpdateProfileRequest payload) async {
    final api = ref.read(profileApiProvider);
    final updated = await api.updateMe(payload);
    state = AsyncData(updated);
    return updated;
  }

  /// Upload file ảnh lên Cloudinary thông qua backend `PATCH /users/avatar`.
  /// Trả về UserModel đã được cập nhật (kèm avatar mới).
  ///
  /// Chấp nhận cả `XFile` (từ `ImagePicker`) lẫn `String filePath` cho các
  /// nơi gọi cũ. Khi chạy trên Flutter web phải truyền `XFile` vì
  /// `XFile.path` là `blob:` URL không đọc được bằng `dart:io`.
  Future<UserModel> uploadAvatar(dynamic fileOrPath) async {
    final api = ref.read(profileApiProvider);
    final result = await api.uploadAvatar(fileOrPath);
    final current = state.value;
    final updated = (current ?? const _EmptyUser()).copyWith(
      avatarUrl: result.secureUrl,
      avatarPublicId: result.publicId,
      clearAvatar: false,
    );
    state = AsyncData(updated);
    return updated;
  }

  Future<String> changePassword({
    required String oldPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    final api = ref.read(profileApiProvider);
    return api.changePassword(
      oldPassword: oldPassword,
      newPassword: newPassword,
      confirmPassword: confirmPassword,
    );
  }

  /// Optimistic update (vd: set avatar ngay khi user chọn ảnh trước khi
  /// upload xong).
  void patchLocal(UserModel Function(UserModel) updater) {
    final AsyncValue<UserModel?> s = state;
    final current = s.value;
    if (current == null) return;
    state = AsyncData(updater(current));
  }

  /// Refresh user data (gọi sau khi hoàn thành bài học để cập nhật streak/XP).
  Future<void> refreshUserData() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final api = ref.read(profileApiProvider);
      return api.getMe();
    });
  }
}

final currentUserProvider =
    AsyncNotifierProvider<CurrentUserNotifier, UserModel?>(
  CurrentUserNotifier.new,
);

/// Fallback rỗng chỉ dùng nội bộ trong `uploadAvatar` khi state chưa có user.
class _EmptyUser extends UserModel {
  const _EmptyUser()
      : super(
          id: '',
          username: '',
          email: '',
          displayName: '',
        );
}