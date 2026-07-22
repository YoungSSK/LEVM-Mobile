import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/grammar_api.dart';
import '../models/grammar_models.dart';

/// Provider cho GrammarApi instance.
final grammarApiProvider = Provider<GrammarApi>((ref) => GrammarApi());

  // ==================== Topics Providers ====================

  /// Lấy danh sách chủ đề Grammar kèm tiến độ học của user.
  /// Dùng /progress endpoint để lấy completedLessons.
  /// Backend trả về { totalLessons, completedLessons, progressPercent, ...topic }
  final grammarTopicsProvider = FutureProvider<List<GrammarTopicModel>>((ref) async {
    final api = ref.read(grammarApiProvider);
    return api.getTopicsWithProgress();
  });

  /// Lấy chi tiết một chủ đề theo ID.
  final grammarTopicDetailProvider = FutureProvider.family<GrammarTopicModel, String>(
    (ref, topicId) async {
      final api = ref.read(grammarApiProvider);
      return api.getTopicById(topicId);
    },
  );

  // ==================== Lessons Providers ====================

  /// Lấy danh sách bài học Grammar theo topic.
  /// Backend trả về { topic, lessons } - lấy lessons.
  final grammarLessonsProvider = FutureProvider.family<List<GrammarLessonModel>, String>(
    (ref, topicId) async {
      final api = ref.read(grammarApiProvider);
      return api.getLessonsByTopic(topicId);
    },
  );

  /// Lấy danh sách tất cả bài học đã publish.
  final allGrammarLessonsProvider = FutureProvider<List<GrammarLessonModel>>((ref) async {
    final api = ref.read(grammarApiProvider);
    return api.getPublishedLessons();
  });

  /// Lấy chi tiết một bài học Grammar.
  final grammarLessonDetailProvider = FutureProvider.family<GrammarLessonModel, String>(
    (ref, lessonId) async {
      final api = ref.read(grammarApiProvider);
      return api.getLessonById(lessonId);
    },
  );

  /// Lấy bài kế tiếp trong cùng topic.
  final grammarNextLessonProvider = FutureProvider.family<GrammarLessonModel?, String>(
    (ref, lessonId) async {
      final api = ref.read(grammarApiProvider);
      return api.getNextLesson(lessonId);
    },
  );

  /// Lấy bài trước đó trong cùng topic.
  final grammarPreviousLessonProvider = FutureProvider.family<GrammarLessonModel?, String>(
    (ref, lessonId) async {
      final api = ref.read(grammarApiProvider);
      return api.getPreviousLesson(lessonId);
    },
  );

  // ==================== Quiz Provider ====================

  /// Lấy câu hỏi quiz của một bài học.
  final grammarQuizQuestionsProvider = FutureProvider.family<List<GrammarQuizQuestionModel>, String>(
    (ref, lessonId) async {
      final api = ref.read(grammarApiProvider);
      return api.getQuizQuestions(lessonId);
    },
  );
