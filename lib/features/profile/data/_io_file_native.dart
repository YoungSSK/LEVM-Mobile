import 'dart:io';

/// Hàm shim cho phép đọc file native thông qua `dart:io`. Conditional
/// import đảm bảo file này chỉ được load trên các platform có `dart:io`
/// (Android / iOS / desktop). Trên web, `profile_api.dart` không bao giờ
/// gọi tới helper này vì đã kiểm tra `kIsWeb` trước.
List<int> readFileBytes(String path) => File(path).readAsBytesSync();
