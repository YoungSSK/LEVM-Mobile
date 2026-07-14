import 'package:dio/dio.dart';

import '../../../core/network/dio_client.dart';
import '../models/occupation_models.dart';

class OccupationApi {
  OccupationApi({Dio? dio}) : _dio = dio ?? DioClient.dio;

  final Dio _dio;

  /// `GET /api/occupation-categories` - Lấy tất cả nhóm ngành (public).
  Future<List<OccupationCategoryModel>> getCategories() async {
    try {
      final res = await _dio.get('/occupation-categories');
      final body = res.data;
      final raw = body is Map && body['data'] is List
          ? body['data'] as List
          : (body is List ? body : <dynamic>[]);
      return raw
          .whereType<Map<String, dynamic>>()
          .map(OccupationCategoryModel.fromJson)
          .toList(growable: false);
    } on DioException catch (e) {
      throw _translateError(e);
    }
  }

  /// `GET /api/occupations` - Lấy tất cả occupation (public).
  Future<List<OccupationModel>> getOccupations() async {
    try {
      final res = await _dio.get('/occupations');
      final body = res.data;
      final raw = body is Map && body['data'] is List
          ? body['data'] as List
          : (body is List ? body : <dynamic>[]);
      return raw
          .whereType<Map<String, dynamic>>()
          .map(OccupationModel.fromJson)
          .toList(growable: false);
    } on DioException catch (e) {
      throw _translateError(e);
    }
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
    if (status != null && status >= 500) {
      return Exception(backendMessage ?? 'Máy chủ đang bận.');
    }
    return Exception(backendMessage ?? 'Không tải được danh sách nghề nghiệp.');
  }
}