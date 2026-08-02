import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';
import '../../domain/models/membership_models.dart';

class MembershipApiService {
  final Dio _dio = DioClient.dio;

  /// Lấy danh sách gói đang active (trừ Free)
  Future<List<PackageModel>> getPackages() async {
    try {
      final response = await _dio.get('/packages');
      final data = response.data['data'];
      final List<dynamic> list = data is List ? data : [];
      return list
          .map((j) => PackageModel.fromJson(j as Map<String, dynamic>))
          .where((p) => !p.isFree) // Ẩn gói Free khỏi màn hình nâng cấp
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Lấy subscription hiện tại của user
  Future<Map<String, dynamic>> getMySubscription() async {
    try {
      final response = await _dio.get('/subscriptions/me');
      return (response.data['data'] as Map<String, dynamic>?) ?? {};
    } catch (_) {
      return {};
    }
  }

  /// Tạo đơn thanh toán — trả về URL redirect tới cổng thanh toán SePay
  Future<String?> checkout(String packageId) async {
    try {
      final response = await _dio.post('/subscriptions/checkout', data: {
        'packageId': packageId,
      });
      final data = response.data['data'];
      return (data['redirectUrl'] as String?)?.isNotEmpty == true
          ? data['redirectUrl'] as String
          : null;
    } catch (e) {
      rethrow;
    }
  }

  /// Refresh subscription sau khi thanh toán xong (deep link return)
  Future<Map<String, dynamic>> refreshSubscription() async {
    return getMySubscription();
  }
}
