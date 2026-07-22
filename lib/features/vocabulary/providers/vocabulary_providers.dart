import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/vocabulary_api.dart';
import '../models/vocabulary_models.dart';
import '../models/study_models.dart';

final vocabularyApiProvider = Provider<VocabularyApi>((ref) => VocabularyApi());

final vocabularyTopicsProvider = FutureProvider<List<VocabularyTopicModel>>((ref) async {
  final api = ref.read(vocabularyApiProvider);
  return api.getTopics();
});

final vocabularyLessonsProvider = FutureProvider.family<List<VocabularyLessonModel>, String>(
  (ref, topicId) async {
    final api = ref.read(vocabularyApiProvider);
    return api.getLessonsByTopic(topicId);
  },
);

final lessonDetailProvider = FutureProvider.family<VocabularyLessonModel, String>(
  (ref, lessonId) async {
    final api = ref.read(vocabularyApiProvider);
    return api.getLessonById(lessonId);
  },
);

final studyWordsProvider = FutureProvider.family<LessonStudyData, String>(
  (ref, lessonId) async {
    final api = ref.read(vocabularyApiProvider);
    return api.getStudyWords(lessonId);
  },
);

final lessonStatsProvider = FutureProvider.family<LessonStatsModel, String>(
  (ref, lessonId) async {
    final api = ref.read(vocabularyApiProvider);
    return api.getLessonStats(lessonId);
  },
);
