import 'package:dio/dio.dart';

import '../../../core/network/dio_client.dart';
import '../models/grammar_models.dart';

/// API client cho Grammar feature.
///
/// Endpoint reference:
/// - GET  /api/grammar-topics/active                 -> danh sách chủ đề đang hoạt động
/// - GET  /api/grammar-topics/progress                -> danh sách chủ đề KÈM tiến độ học của user
/// - GET  /api/grammar-lessons/published              -> danh sách bài học đã publish
/// - GET  /api/grammar-lessons/topic/:topicId/active  -> bài học theo chủ đề (active)
/// - GET  /api/grammar-lessons/:id                    -> chi tiết 1 bài học
/// - GET  /api/grammar-lessons/:id/next               -> bài kế tiếp cùng topic
/// - GET  /api/grammar-lessons/:id/previous           -> bài trước đó cùng topic
/// - GET  /api/grammar/lessons/:lessonId/quiz-play   -> câu hỏi quiz (user, ẩn isCorrect/explanation)
/// - POST /api/grammar/lessons/:lessonId/quiz/submit   -> nộp bài, trả kết quả + XP/streak
class GrammarApi {
  GrammarApi({Dio? dio}) : _dio = dio ?? DioClient.dio;

  final Dio _dio;

  // ==================== Topics ====================

  /// Lấy danh sách chủ đề đang hoạt động (public, không cần login).
  Future<List<GrammarTopicModel>> getActiveTopics() async {
    try {
      final res = await _dio.get("/grammar-topics/active");
      final body = _getBody(res.data);
      final data = body["data"] as List<dynamic>? ?? [];
      return data.map((t) => GrammarTopicModel.fromJson(t as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw _translateError(e);
    }
  }

  /// Lấy danh sách chủ đề kèm tiến độ học của user (cần login).
  Future<List<GrammarTopicModel>> getTopicsWithProgress() async {
    try {
      final res = await _dio.get("/grammar-topics/progress");
      final body = _getBody(res.data);
      final data = body["data"] as List<dynamic>? ?? [];
      return data.map((t) => GrammarTopicModel.fromJson(t as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw _translateError(e);
    }
  }

  /// Lấy chi tiết một chủ đề.
  Future<GrammarTopicModel> getTopicById(String topicId) async {
    try {
      final res = await _dio.get("/grammar-topics/$topicId");
      final body = _getBody(res.data);
      final data = body["data"] as Map<String, dynamic>? ?? {};
      return GrammarTopicModel.fromJson(data);
    } on DioException catch (e) {
      throw _translateError(e);
    }
  }

  // ==================== Lessons ====================

  /// Lấy danh sách bài học theo chủ đề (active lessons).
  /// Backend trả về { topic, lessons } - cần trích xuất lessons.
  Future<List<GrammarLessonModel>> getLessonsByTopic(String topicId) async {
    try {
      final res = await _dio.get("/grammar-lessons/topic/$topicId/active");
      final body = _getBody(res.data);
      // Backend trả về { topic, lessons } - lấy lessons array
      final data = body["data"] as Map<String, dynamic>? ?? {};
      final lessons = data["lessons"] as List<dynamic>? ?? [];
      return lessons.map((l) => GrammarLessonModel.fromJson(l as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw _translateError(e);
    }
  }

  /// Lấy danh sách tất cả bài học đã publish.
  Future<List<GrammarLessonModel>> getPublishedLessons() async {
    try {
      final res = await _dio.get("/grammar-lessons/published");
      final body = _getBody(res.data);
      // Backend có thể trả về { lessons } hoặc lessons array
      final data = body["data"];
      List<dynamic> lessons;
      if (data is List) {
        lessons = data;
      } else if (data is Map<String, dynamic>) {
        lessons = data["lessons"] as List<dynamic>? ?? [];
      } else {
        lessons = [];
      }
      return lessons.map((l) => GrammarLessonModel.fromJson(l as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw _translateError(e);
    }
  }

  /// Lấy chi tiết một bài học (bao gồm htmlContent).
  Future<GrammarLessonModel> getLessonById(String lessonId) async {
    try {
      final res = await _dio.get("/grammar-lessons/$lessonId");
      final body = _getBody(res.data);
      final data = body["data"] as Map<String, dynamic>? ?? {};
      return GrammarLessonModel.fromJson(data);
    } on DioException catch (e) {
      throw _translateError(e);
    }
  }

  /// Lấy bài học kế tiếp trong cùng chủ đề.
  Future<GrammarLessonModel?> getNextLesson(String lessonId) async {
    try {
      final res = await _dio.get("/grammar-lessons/$lessonId/next");
      final body = _getBody(res.data);
      final data = body["data"];
      if (data == null) return null;
      return GrammarLessonModel.fromJson(data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      throw _translateError(e);
    }
  }

  /// Lấy bài học trước đó trong cùng chủ đề.
  Future<GrammarLessonModel?> getPreviousLesson(String lessonId) async {
    try {
      final res = await _dio.get("/grammar-lessons/$lessonId/previous");
      final body = _getBody(res.data);
      final data = body["data"];
      if (data == null) return null;
      return GrammarLessonModel.fromJson(data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      throw _translateError(e);
    }
  }

  // ==================== Quiz ====================

  /// Lấy câu hỏi quiz để user làm bài (KHÔNG có isCorrect và explanation).
  /// Cần login. Gọi route /quiz-play (không phải /quiz admin).
  Future<List<GrammarQuizQuestionModel>> getQuizQuestions(String lessonId) async {
    try {
      final res = await _dio.get("/grammar/lessons/$lessonId/quiz-play");
      final body = _getBody(res.data);
      final data = body["data"] as List<dynamic>? ?? [];
      return data.map((q) => GrammarQuizQuestionModel.fromJson(q as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw _translateError(e);
    }
  }

  /// Nộp bài trắc nghiệm.
  ///
  /// [answers] là danh sách {questionId, selectedOptionIndex}.
  /// Trả về kết quả bao gồm score, isPassed, xpEarned, streak info.
  Future<QuizSubmitResultModel> submitQuiz(
    String lessonId,
    List<Map<String, dynamic>> answers,
  ) async {
    try {
      final res = await _dio.post(
        "/grammar/lessons/$lessonId/quiz/submit",
        data: {"answers": answers},
      );
      final body = _getBody(res.data);
      final data = body["data"] as Map<String, dynamic>? ?? {};
      return QuizSubmitResultModel.fromJson(data);
    } on DioException catch (e) {
      throw _translateError(e);
    }
  }

  // ==================== Progress ====================

  /// Lấy tiến độ học của user với một bài học.
  Future<UserGrammarProgressModel?> getLessonProgress(String lessonId) async {
    try {
      final res = await _dio.get("/grammar/progress/$lessonId");
      final body = _getBody(res.data);
      final data = body["data"];
      if (data == null) return null;
      return UserGrammarProgressModel.fromJson(data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      throw _translateError(e);
    }
  }

  // ==================== Helpers ====================

  Map<String, dynamic> _getBody(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    return {};
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
    if (status == 401) {
      return Exception(backendMessage ?? 'Phiên đăng nhập đã hết hạn.');
    }
    if (status != null && status >= 500) {
      return Exception(backendMessage ?? 'Máy chủ đang bận.');
    }
    return Exception(backendMessage ?? 'Đã có lỗi xảy ra, bạn thử lại.');
  }
}
