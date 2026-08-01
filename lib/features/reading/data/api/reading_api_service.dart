import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';
import '../../domain/models/reading_category.dart';
import '../../domain/models/reading_passage.dart';
import '../../domain/models/reading_question.dart';
import '../../domain/models/reading_attempt.dart';

class ReadingApiService {
  final Dio _dio = DioClient.dio;

  /// Fetch list of reading categories
  Future<List<ReadingCategory>> getCategories() async {
    try {
      final response = await _dio.get('/reading-categories');
      final data = response.data['data'] ?? response.data;
      final List<dynamic> categoriesJson = data['categories'] ?? (data is List ? data : []);
      if (categoriesJson.isNotEmpty) {
        final apiCats = categoriesJson.map((json) => ReadingCategory.fromJson(json)).toList();
        return [
          const ReadingCategory(id: 'cat_1', title: 'Tất cả', slug: 'all'),
          ...apiCats,
        ];
      }
      return const [
        ReadingCategory(id: 'cat_1', title: 'Tất cả', slug: 'all'),
      ];
    } catch (_) {
      return const [
        ReadingCategory(id: 'cat_1', title: 'Tất cả', slug: 'all'),
      ];
    }
  }

  /// Fetch reading passages with search, category, and CEFR filter
  Future<List<ReadingPassage>> getPassages({
    String? categoryId,
    String? cefrLevel,
    String? search,
  }) async {
    try {
      final Map<String, dynamic> queryParams = {
        'status': 'published',
      };
      if (categoryId != null && categoryId.isNotEmpty && categoryId != 'cat_1') {
        queryParams['categoryId'] = categoryId;
      }
      if (cefrLevel != null && cefrLevel.isNotEmpty && cefrLevel != 'All') {
        queryParams['cefrLevel'] = cefrLevel;
      }
      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }

      Response response;
      try {
        response = await _dio.get('/reading-passages/published', queryParameters: queryParams);
      } catch (_) {
        response = await _dio.get('/reading-passages', queryParameters: queryParams);
      }

      final data = response.data['data'] ?? response.data;
      List<dynamic> passagesJson = [];

      if (data is Map && data.containsKey('passages')) {
        passagesJson = data['passages'] as List<dynamic>? ?? [];
      } else if (data is List) {
        passagesJson = data;
      }

      if (passagesJson.isNotEmpty) {
        final apiPassages = passagesJson
            .map((json) => ReadingPassage.fromJson(json as Map<String, dynamic>))
            .toList();
        return _filterPassages(apiPassages, categoryId: categoryId, cefrLevel: cefrLevel, search: search);
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  /// Fetch single reading passage detail
  Future<ReadingPassage> getPassageDetail(String passageId) async {
    final response = await _dio.get('/reading-passages/$passageId');
    final data = response.data['data'] ?? response.data;
    return ReadingPassage.fromJson(data);
  }

  /// Fetch quiz questions for a passage (Mobile — no correctAnswer from server)
  Future<List<ReadingQuestion>> getPassageQuestions(String passageId) async {
    try {
      final response = await _dio.get('/reading-questions/passage/$passageId');
      final body = response.data;
      final data = body['data'] ?? body;

      List<dynamic> questionsJson = [];
      if (data is Map && data.containsKey('questions')) {
        questionsJson = data['questions'] as List<dynamic>? ?? [];
      } else if (data is List) {
        questionsJson = data;
      }

      if (questionsJson.isNotEmpty) {
        return questionsJson
            .map((json) => ReadingQuestion.fromJson(json as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  /// Submit quiz attempt using backend 2-step flow:
  /// 1. POST /reading-attempts/start → get attemptId
  /// 2. POST /reading-attempts/:attemptId/submit → get result
  Future<ReadingAttempt> submitAttempt({
    required String passageId,
    required Map<String, String> userAnswers,
    required int duration,
    String? questionSetId,
  }) async {
    try {
      // Step 1: Get questionSetId if not provided
      String setId = questionSetId ?? '';
      if (setId.isEmpty) {
        final setsResponse = await _dio.get('/reading-questions/passage/$passageId/sets');
        final setsData = setsResponse.data['data'] ?? setsResponse.data;
        final List<dynamic> sets = setsData is List ? setsData : [];
        if (sets.isNotEmpty) {
          setId = (sets.first['_id'] ?? sets.first['id'] ?? '').toString();
        }
      }

      // Step 2: Start attempt
      final startResponse = await _dio.post('/reading-attempts/start', data: {
        'passageId': passageId,
        'questionSetId': setId,
      });
      final startData = startResponse.data['data'] ?? startResponse.data;
      final attemptId = (startData['attemptId'] ?? startData['_id'] ?? startData['id'] ?? '').toString();
      if (attemptId.isEmpty) throw Exception('Không lấy được attemptId');

      // Step 3: Build answers array
      final answers = userAnswers.entries.map((e) {
        final questionId = e.key;
        final selectedKey = e.value;
        return {
          'questionId': questionId,
          'userAnswer': {'selectedKey': selectedKey},
          'timeSpent': 0,
        };
      }).toList();

      // Step 4: Submit
      final submitResponse = await _dio.post(
        '/reading-attempts/$attemptId/submit',
        data: {'answers': answers, 'duration': duration},
      );
      final submitData = submitResponse.data['data'] ?? submitResponse.data;
      return ReadingAttempt.fromJson(submitData is Map<String, dynamic>
          ? submitData
          : <String, dynamic>{});
    } catch (_) {
      // Fallback: local scoring
      return ReadingAttempt(
        id: 'local_${DateTime.now().millisecondsSinceEpoch}',
        userId: '',
        passageId: passageId,
        totalQuestions: userAnswers.length,
        correctAnswers: 0,
        wrongAnswers: userAnswers.length,
        score: 0,
        isPassed: false,
        xpEarned: 0,
        duration: duration,
        status: 'completed',
        submittedAt: DateTime.now(),
      );
    }
  }

  /// Lookup word definition
  Future<Map<String, dynamic>> lookupWord(String word) async {
    try {
      final response = await _dio.get('/words/search', queryParameters: {'q': word});
      final data = response.data['data'] ?? response.data;
      return data is Map<String, dynamic> ? data : {'word': word};
    } catch (_) {
      final clean = word.replaceAll(RegExp(r'[^\w]'), '');
      return {'word': clean};
    }
  }

  List<ReadingPassage> _filterPassages(
    List<ReadingPassage> passages, {
    String? categoryId,
    String? cefrLevel,
    String? search,
  }) {
    return passages.where((p) {
      if (categoryId != null && categoryId.isNotEmpty && categoryId != 'cat_1') {
        if (p.categoryId != categoryId) return false;
      }
      if (cefrLevel != null && cefrLevel.isNotEmpty && cefrLevel != 'All') {
        if (p.cefrLevel.toUpperCase() != cefrLevel.toUpperCase()) return false;
      }
      if (search != null && search.isNotEmpty) {
        final q = search.toLowerCase();
        final matchTitle = p.title.toLowerCase().contains(q);
        final matchDesc = p.description.toLowerCase().contains(q);
        if (!matchTitle && !matchDesc) return false;
      }
      return true;
    }).toList();
  }
}
