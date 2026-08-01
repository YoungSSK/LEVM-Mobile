import '../api/reading_api_service.dart';
import '../../domain/models/reading_category.dart';
import '../../domain/models/reading_passage.dart';
import '../../domain/models/reading_question.dart';
import '../../domain/models/reading_attempt.dart';

class ReadingRepository {
  final ReadingApiService _apiService;

  ReadingRepository({ReadingApiService? apiService})
      : _apiService = apiService ?? ReadingApiService();

  Future<List<ReadingCategory>> getCategories() async {
    return await _apiService.getCategories();
  }

  Future<List<ReadingPassage>> getPassages({
    String? categoryId,
    String? cefrLevel,
    String? search,
  }) async {
    return await _apiService.getPassages(
      categoryId: categoryId,
      cefrLevel: cefrLevel,
      search: search,
    );
  }

  Future<ReadingPassage> getPassageDetail(String passageId) async {
    return await _apiService.getPassageDetail(passageId);
  }

  Future<List<ReadingQuestion>> getPassageQuestions(String passageId) async {
    return await _apiService.getPassageQuestions(passageId);
  }

  Future<ReadingAttempt> submitAttempt({
    required String passageId,
    required Map<String, String> userAnswers,
    required int duration,
  }) async {
    return await _apiService.submitAttempt(
      passageId: passageId,
      userAnswers: userAnswers,
      duration: duration,
    );
  }

  Future<Map<String, dynamic>> lookupWord(String word) async {
    return await _apiService.lookupWord(word);
  }
}
