import 'package:dio/dio.dart';

import '../../../core/network/dio_client.dart';
import '../models/vocabulary_models.dart';
import '../models/study_models.dart';
import '../models/xp_models.dart';

class VocabularyApi {
  VocabularyApi({Dio? dio}) : _dio = dio ?? DioClient.dio;

  final Dio _dio;

  // ==================== Topics ====================

  Future<List<VocabularyTopicModel>> getTopics() async {
    try {
      final res = await _dio.get("/vocabulary-topics");
      final body = _getBody(res.data);
      final data = body["data"] as Map<String, dynamic>? ?? {};
      final topics = data["topics"] as List<dynamic>? ?? [];
      return topics.map((t) => VocabularyTopicModel.fromJson(t)).toList();
    } on DioException catch (e) {
      throw _translateError(e);
    }
  }

  Future<VocabularyTopicModel> getTopicById(String topicId) async {
    try {
      final res = await _dio.get("/vocabulary-topics/$topicId");
      final body = _getBody(res.data);
      final data = body["data"] as Map<String, dynamic>? ?? {};
      return VocabularyTopicModel.fromJson(data);
    } on DioException catch (e) {
      throw _translateError(e);
    }
  }

  // ==================== Lessons ====================

  Future<List<VocabularyLessonModel>> getLessonsByTopic(String topicId) async {
    try {
      final res = await _dio.get("/vocabulary-topics/$topicId/lessons");
      final body = _getBody(res.data);
      final data = body["data"] as List<dynamic>? ?? [];
      return data.map((l) => VocabularyLessonModel.fromJson(l)).toList();
    } on DioException catch (e) {
      throw _translateError(e);
    }
  }

  Future<VocabularyLessonModel> getLessonById(String lessonId) async {
    try {
      final res = await _dio.get("/vocabulary-lessons/$lessonId");
      final body = _getBody(res.data);
      final data = body["data"] as Map<String, dynamic>? ?? {};
      return VocabularyLessonModel.fromJson(data);
    } on DioException catch (e) {
      throw _translateError(e);
    }
  }

  Future<LessonStudyData> getStudyWords(String lessonId) async {
    try {
      final res = await _dio.get("/vocabulary-lessons/$lessonId/study-words");
      final body = _getBody(res.data);
      final data = body["data"] as Map<String, dynamic>? ?? {};
      return LessonStudyData.fromJson(data);
    } on DioException catch (e) {
      throw _translateError(e);
    }
  }

  // ==================== Attempts ====================

  Future<LessonAttemptModel> createAttempt(String lessonId, int level) async {
    try {
      final res = await _dio.post("/attempts", data: {
        "lessonId": lessonId,
        "level": level,
      });
      final body = _getBody(res.data);
      final data = body["data"] as Map<String, dynamic>? ?? {};
      return LessonAttemptModel.fromJson(data);
    } on DioException catch (e) {
      throw _translateError(e);
    }
  }

  Future<LessonAttemptModel> getAttempt(String attemptId) async {
    try {
      final res = await _dio.get("/attempts/$attemptId");
      final body = _getBody(res.data);
      final data = body["data"] as Map<String, dynamic>? ?? {};
      return LessonAttemptModel.fromJson(data);
    } on DioException catch (e) {
      throw _translateError(e);
    }
  }

  Future<Map<String, dynamic>> submitAnswer(
    String attemptId, {
    required String wordId,
    required String userAnswer,
    bool isCorrect = false,
    int timeSpent = 0,
  }) async {
    try {
      final res = await _dio.patch("/attempts/$attemptId", data: {
        "wordId": wordId,
        "userAnswer": userAnswer,
        "isCorrect": isCorrect,
        "timeSpent": timeSpent,
      });
      final body = _getBody(res.data);
      return body["data"] as Map<String, dynamic>? ?? {};
    } on DioException catch (e) {
      throw _translateError(e);
    }
  }

  Future<CompleteAttemptResult> completeAttempt(String attemptId) async {
    try {
      final res = await _dio.post("/attempts/$attemptId/complete");
      final body = _getBody(res.data);
      final data = body["data"] as Map<String, dynamic>? ?? {};
      return CompleteAttemptResult.fromJson(data);
    } on DioException catch (e) {
      throw _translateError(e);
    }
  }

  Future<List<LessonAttemptModel>> getLessonAttempts(String lessonId) async {
    try {
      final res = await _dio.get("/attempts/lesson/$lessonId");
      final body = _getBody(res.data);
      final data = body["data"] as List<dynamic>? ?? [];
      return data.map((a) => LessonAttemptModel.fromJson(a)).toList();
    } on DioException catch (e) {
      throw _translateError(e);
    }
  }

  Future<LessonStatsModel> getLessonStats(String lessonId) async {
    try {
      final res = await _dio.get("/attempts/lesson/$lessonId/stats");
      final body = _getBody(res.data);
      final data = body["data"] as Map<String, dynamic>? ?? {};
      return LessonStatsModel.fromJson(data);
    } on DioException catch (e) {
      throw _translateError(e);
    }
  }

  // ==================== Spelling ====================

  Future<Map<String, dynamic>> verifySpelling(
    String userAnswer,
    String correctAnswer,
  ) async {
    try {
      final res = await _dio.post("/spelling/verify", data: {
        "userAnswer": userAnswer,
        "correctAnswer": correctAnswer,
      });
      final body = _getBody(res.data);
      return body["data"] as Map<String, dynamic>? ?? {};
    } on DioException catch (e) {
      throw _translateError(e);
    }
  }

  // ==================== XP & Streak ====================

  Future<XpInfoModel> getXpInfo() async {
    try {
      final res = await _dio.get("/xp");
      final body = _getBody(res.data);
      final data = body["data"] as Map<String, dynamic>? ?? {};
      return XpInfoModel.fromJson(data);
    } on DioException catch (e) {
      throw _translateError(e);
    }
  }

  Future<List<XpHistoryItemModel>> getXpHistory({int limit = 50, int skip = 0}) async {
    try {
      final res = await _dio.get("/xp/history", queryParameters: {
        "limit": limit,
        "skip": skip,
      });
      final body = _getBody(res.data);
      final data = body["data"] as Map<String, dynamic>? ?? {};
      final transactions = data["transactions"] as List<dynamic>? ?? [];
      return transactions.map((t) => XpHistoryItemModel.fromJson(t)).toList();
    } on DioException catch (e) {
      throw _translateError(e);
    }
  }

  Future<XpSummaryModel> getXpSummary() async {
    try {
      final res = await _dio.get("/xp/summary");
      final body = _getBody(res.data);
      final data = body["data"] as Map<String, dynamic>? ?? {};
      return XpSummaryModel.fromJson(data);
    } on DioException catch (e) {
      throw _translateError(e);
    }
  }

  Future<StreakInfoModel> getStreakInfo() async {
    try {
      final res = await _dio.get("/streak");
      final body = _getBody(res.data);
      final data = body["data"] as Map<String, dynamic>? ?? {};
      return StreakInfoModel.fromJson(data);
    } on DioException catch (e) {
      throw _translateError(e);
    }
  }

  Future<StreakCalendarModel> getStreakCalendar({int days = 30}) async {
    try {
      final res = await _dio.get("/streak/calendar", queryParameters: {
        "days": days,
      });
      final body = _getBody(res.data);
      final data = body["data"] as Map<String, dynamic>? ?? {};
      return StreakCalendarModel.fromJson(data);
    } on DioException catch (e) {
      throw _translateError(e);
    }
  }

  Future<int> useStreakFreeze() async {
    try {
      final res = await _dio.post("/streak/freeze");
      final body = _getBody(res.data);
      final data = body["data"] as Map<String, dynamic>? ?? {};
      return data["freezeCount"] as int? ?? 0;
    } on DioException catch (e) {
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
