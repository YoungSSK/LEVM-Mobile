import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';
import '../../domain/models/listening_models.dart';

class ListeningApiService {
  final Dio _dio = DioClient.dio;

  Future<List<ListeningSet>> getListeningSets({int? part}) async {
    try {
      final Map<String, dynamic> queryParams = {'status': 'published'};
      if (part != null) queryParams['part'] = part;

      final response = await _dio.get('/listening/sets', queryParameters: queryParams);
      final data = response.data['data'];
      if (data is List) {
        return data.map((json) => ListeningSet.fromJson(json)).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<ListeningPlayPayload> getPlayPayload(String setId) async {
    final response = await _dio.get('/listening/sets/$setId/play');
    final data = response.data['data'];
    return ListeningPlayPayload.fromJson(data);
  }

  Future<ListeningSubmitResult> submitAttempt({
    required String setId,
    required int durationSeconds,
    required List<Map<String, String>> answers,
  }) async {
    final response = await _dio.post(
      '/listening/attempts/submit',
      data: {
        'setId': setId,
        'durationSeconds': durationSeconds,
        'answers': answers,
      },
    );
    final data = response.data['data'];
    return ListeningSubmitResult.fromJson(data);
  }
}
