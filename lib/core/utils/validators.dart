/// Mirrors server-side validation rules from the backend `User` model.
///
/// Keeping these in one place ensures we never round-trip a request just to
/// have it bounce off a Zod / Mongoose validator.
class Validators {
  Validators._();

  // --- username ----------------------------------------------------------
  static const int usernameMinLength = 3;
  static const int usernameMaxLength = 30;

  static String? username(String? value, {bool allowEmpty = false}) {
    final trimmed = (value ?? "").trim();
    if (allowEmpty && trimmed.isEmpty) return null;
    if (trimmed.isEmpty) return "Vui lòng nhập tên đăng nhập.";
    if (trimmed.length < usernameMinLength) {
      return "Tên đăng nhập phải có ít nhất $usernameMinLength ký tự.";
    }
    if (trimmed.length > usernameMaxLength) {
      return "Tên đăng nhập tối đa $usernameMaxLength ký tự.";
    }
    if (!RegExp(r"^[a-zA-Z0-9_.]+$").hasMatch(trimmed)) {
      return "Chỉ dùng chữ cái, số, dấu chấm và gạch dưới.";
    }
    return null;
  }

  // --- email -------------------------------------------------------------
  static final RegExp _emailRegExp = RegExp(
    r"^[a-zA-Z0-9_.+-]+@[a-zA-Z0-9-]+\.[a-zA-Z0-9-.]+$",
  );

  static String? email(String? value, {bool allowEmpty = false}) {
    final trimmed = (value ?? "").trim();
    if (allowEmpty && trimmed.isEmpty) return null;
    if (trimmed.isEmpty) return "Vui lòng nhập email.";
    if (!_emailRegExp.hasMatch(trimmed)) {
      return "Email chưa đúng định dạng.";
    }
    return null;
  }

  // --- password ----------------------------------------------------------
  static const int passwordMinLength = 6;

  /// Mirrors backend: >=6 chars AND at least 1 uppercase AND 1 digit.
  static String? password(String? value, {bool allowEmpty = false}) {
    final v = value ?? "";
    if (allowEmpty && v.isEmpty) return null;
    if (v.isEmpty) return "Vui lòng nhập mật khẩu.";
    if (v.length < passwordMinLength) {
      return "Mật khẩu phải có ít nhất $passwordMinLength ký tự.";
    }
    if (!RegExp(r"[A-Z]").hasMatch(v)) {
      return "Mật khẩu phải có ít nhất 1 chữ hoa.";
    }
    if (!RegExp(r"[0-9]").hasMatch(v)) {
      return "Mật khẩu phải có ít nhất 1 chữ số.";
    }
    return null;
  }

  static String? confirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) return "Vui lòng xác nhận mật khẩu.";
    if (value != password) return "Mật khẩu xác nhận chưa khớp.";
    return null;
  }

  static String? newPasswordDifferent({
    required String oldPassword,
    required String newPassword,
  }) {
    if (oldPassword == newPassword) {
      return "Mật khẩu mới phải khác mật khẩu hiện tại.";
    }
    return null;
  }

  // --- profile -----------------------------------------------------------
  static const int displayNameMinLength = 2;
  static const int displayNameMaxLength = 50;
  static const int bioMaxLength = 200;

  static String? displayName(String? value) {
    final trimmed = (value ?? "").trim();
    if (trimmed.isEmpty) return "Vui lòng nhập tên hiển thị.";
    if (trimmed.length < displayNameMinLength) {
      return "Tên hiển thị phải có ít nhất $displayNameMinLength ký tự.";
    }
    if (trimmed.length > displayNameMaxLength) {
      return "Tên hiển thị tối đa $displayNameMaxLength ký tự.";
    }
    return null;
  }

  static String? bio(String? value) {
    final v = value ?? "";
    if (v.length > bioMaxLength) {
      return "Giới thiệu tối đa $bioMaxLength ký tự.";
    }
    return null;
  }

  static String? avatarUrl(String? value) {
    final v = (value ?? "").trim();
    if (v.isEmpty) return null;
    final uri = Uri.tryParse(v);
    if (uri == null || !(uri.isScheme("http") || uri.isScheme("https"))) {
      return "URL avatar không hợp lệ (phải bắt đầu bằng http/https).";
    }
    return null;
  }
}
