import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/vocabulary_api.dart';
import '../models/vocabulary_models.dart';
import '../models/study_models.dart';
import '../../profile/providers/profile_providers.dart';
import 'vocabulary_providers.dart';

enum StudyLevel {
  flashcard(1, "Ghi nhớ", "Nhìn từ, nhớ nghĩa"),
  wordRecall(2, "Ghép từ", "Nhìn nghĩa, chọn chữ cái"),
  spelling(3, "Chính tả", "Nghe và gõ từ");

  final int value;
  final String name;
  final String description;

  const StudyLevel(this.value, this.name, this.description);

  static StudyLevel fromValue(int value) {
    return StudyLevel.values.firstWhere(
      (e) => e.value == value,
      orElse: () => StudyLevel.flashcard,
    );
  }
}

class StudySessionState {
  final VocabularyLessonModel? lesson;
  final LessonStudyData? studyData;
  final int currentLevel;
  final int currentWordIndex;
  final LessonAttemptModel? attempt;
  final Map<String, AnswerModel> answers;
  final bool isLoading;
  final bool isSubmitting;
  final CompleteAttemptResult? lastResult;
  final String? error;

  const StudySessionState({
    this.lesson,
    this.studyData,
    this.currentLevel = 1,
    this.currentWordIndex = 0,
    this.attempt,
    this.answers = const {},
    this.isLoading = false,
    this.isSubmitting = false,
    this.lastResult,
    this.error,
  });

  StudyWordModel? get currentWord {
    if (studyData == null || studyData!.words.isEmpty) return null;
    if (currentWordIndex >= studyData!.words.length) return null;
    return studyData!.words[currentWordIndex];
  }

  int get totalWords => studyData?.words.length ?? 0;

  bool get hasMoreWords => currentWordIndex < totalWords;

  AnswerModel? get currentAnswer =>
      currentWord != null ? answers[currentWord!.wordId] : null;

  StudySessionState copyWith({
    VocabularyLessonModel? lesson,
    LessonStudyData? studyData,
    int? currentLevel,
    int? currentWordIndex,
    LessonAttemptModel? attempt,
    Map<String, AnswerModel>? answers,
    bool? isLoading,
    bool? isSubmitting,
    CompleteAttemptResult? lastResult,
    String? error,
    bool clearAttempt = false,
    bool clearResult = false,
    bool clearError = false,
  }) {
    return StudySessionState(
      lesson: lesson ?? this.lesson,
      studyData: studyData ?? this.studyData,
      currentLevel: currentLevel ?? this.currentLevel,
      currentWordIndex: currentWordIndex ?? this.currentWordIndex,
      attempt: clearAttempt ? null : (attempt ?? this.attempt),
      answers: answers ?? this.answers,
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      lastResult: clearResult ? null : (lastResult ?? this.lastResult),
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class StudySessionNotifier extends Notifier<StudySessionState> {
  @override
  StudySessionState build() => const StudySessionState();

  VocabularyApi get _api => ref.read(vocabularyApiProvider);

  Future<void> loadLesson(String lessonId, int level) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final studyData = await _api.getStudyWords(lessonId);
      final attempt = await _api.createAttempt(lessonId, level);

      state = state.copyWith(
        studyData: studyData,
        lesson: studyData.lesson,
        currentLevel: level,
        currentWordIndex: 0,
        attempt: attempt,
        answers: {},
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> submitAnswer({
    required String wordId,
    required String userAnswer,
    required bool isCorrect,
    int timeSpent = 0,
  }) async {
    if (state.attempt == null) return;

    state = state.copyWith(isSubmitting: true);

    try {
      await _api.submitAnswer(
        state.attempt!.id,
        wordId: wordId,
        userAnswer: userAnswer,
        isCorrect: isCorrect,
        timeSpent: timeSpent,
      );

      final newAnswers = Map<String, AnswerModel>.from(state.answers);
      newAnswers[wordId] = AnswerModel(
        wordId: wordId,
        userAnswer: userAnswer,
        isCorrect: isCorrect,
        timeSpent: timeSpent,
      );

      state = state.copyWith(
        answers: newAnswers,
        isSubmitting: false,
      );
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        error: e.toString(),
      );
    }
  }

  void nextWord() {
    if (state.currentWordIndex < state.totalWords) {
      state = state.copyWith(currentWordIndex: state.currentWordIndex + 1);
    }
  }

  void previousWord() {
    if (state.currentWordIndex > 0) {
      state = state.copyWith(currentWordIndex: state.currentWordIndex - 1);
    }
  }

  Future<CompleteAttemptResult?> completeLevel() async {
    if (state.attempt == null) return null;

    state = state.copyWith(isSubmitting: true);

    try {
      final result = await _api.completeAttempt(state.attempt!.id);
      state = state.copyWith(
        lastResult: result,
        isSubmitting: false,
      );
      // Refresh user data to update streak & XP
      ref.read(currentUserProvider.notifier).refreshUserData();
      return result;
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        error: e.toString(),
      );
      return null;
    }
  }

  void reset() {
    state = const StudySessionState();
  }
}

final studySessionProvider =
    NotifierProvider<StudySessionNotifier, StudySessionState>(
  StudySessionNotifier.new,
);
