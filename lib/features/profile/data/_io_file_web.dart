/// Stub cho web build — `dart:io` không khả dụng. Hàm này không bao giờ
/// được gọi vì `ProfileApi.uploadAvatar` kiểm tra `kIsWeb` trước và ném
/// exception. File này chỉ tồn tại để conditional import có stub tương
/// ứng trên web.
List<int> readFileBytes(String path) {
  throw UnsupportedError(
    'Đọc file native không hỗ trợ trên web. Hãy dùng XFile.readAsBytes().',
  );
}
