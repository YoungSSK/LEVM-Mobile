/// Plain enum mirroring the backend `role` field.
enum UserRole {
  user,
  admin;

  static UserRole fromString(String? raw) {
    switch (raw) {
      case "admin":
        return UserRole.admin;
      case "user":
      default:
        return UserRole.user;
    }
  }

  String get apiValue => name;

  String get displayLabel => switch (this) {
        UserRole.admin => "Quản trị viên",
        UserRole.user => "Thành viên",
      };
}
