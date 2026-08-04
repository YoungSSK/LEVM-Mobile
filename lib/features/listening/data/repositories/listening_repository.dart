import '../api/listening_api_service.dart';
import '../../domain/models/listening_models.dart';

class ListeningRepository {
  final ListeningApiService _apiService;

  ListeningRepository({ListeningApiService? apiService})
      : _apiService = apiService ?? ListeningApiService();

  Future<List<ListeningSet>> getListeningSets({int? part}) async {
    return await _apiService.getListeningSets(part: part);
  }

  Future<ListeningPlayPayload> getPlayPayload(String setId) async {
    return await _apiService.getPlayPayload(setId);
  }

  Future<ListeningSubmitResult> submitAttempt({
    required String setId,
    required int durationSeconds,
    required List<Map<String, String>> answers,
  }) async {
    return await _apiService.submitAttempt(
      setId: setId,
      durationSeconds: durationSeconds,
      answers: answers,
    );
  }
}
