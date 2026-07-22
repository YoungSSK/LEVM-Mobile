import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/grammar_api.dart';
import '../models/grammar_models.dart';
import 'grammar_providers.dart';

/// State cho Quiz đang làm.
class QuizState {
  final String lessonId;
  final List<GrammarQuizQuestionModel> questions;
  final Map<String, int> answers; // questionId -> selectedOptionIndex
  final int currentIndex;
  final bool isSubmitting;
  final QuizSubmitResultModel? result;
  final String? error;

  const QuizState({
    required this.lessonId,
    this.questions = const [],
    this.answers = const {},
    this.currentIndex = 0,
    this.isSubmitting = false,
    this.result,
    this.error,
  });

  /// Số câu đã trả lời.
  int get answeredCount => answers.length;

  /// Tổng số câu.
  int get totalQuestions => questions.length;

  /// Tiến độ (0.0 - 1.0).
  double get progress =>
      totalQuestions > 0 ? answeredCount / totalQuestions : 0.0;

  /// Câu hỏi hiện tại.
  GrammarQuizQuestionModel? get currentQuestion =>
      questions.isNotEmpty && currentIndex < questions.length
          ? questions[currentIndex]
          : null;

  /// Đã trả lời hết chưa.
  bool get allAnswered => answeredCount == totalQuestions && totalQuestions > 0;

  /// Lựa chọn đã chọn cho câu hiện tại.
  int? get currentSelectedOption =>
      currentQuestion != null ? answers[currentQuestion!.id] : null;

  QuizState copyWith({
    String? lessonId,
    List<GrammarQuizQuestionModel>? questions,
    Map<String, int>? answers,
    int? currentIndex,
    bool? isSubmitting,
    QuizSubmitResultModel? result,
    String? error,
    bool clearError = false,
    bool clearResult = false,
  }) {
    return QuizState(
      lessonId: lessonId ?? this.lessonId,
      questions: questions ?? this.questions,
      answers: answers ?? this.answers,
      currentIndex: currentIndex ?? this.currentIndex,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      result: clearResult ? null : (result ?? this.result),
      error: clearError ? null : (error ?? this.error),
    );
  }
}

/// Notifier quản lý state của quiz.
class QuizNotifier extends Notifier<QuizState> {
  @override
  QuizState build() => const QuizState(lessonId: "");

  GrammarApi get _api => ref.read(grammarApiProvider);

  /// Khởi tạo quiz với lessonId và load câu hỏi.
  Future<void> initQuiz(String lessonId) async {
    state = QuizState(lessonId: lessonId, isSubmitting: true);

    try {
      final questions = await _api.getQuizQuestions(lessonId);
      state = state.copyWith(
        questions: questions,
        isSubmitting: false,
        answers: {},
        currentIndex: 0,
        clearError: true,
      );
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        error: e.toString(),
      );
    }
  }

  /// Chọn một đáp án cho câu hiện tại.
  void selectAnswer(int optionIndex) {
    final question = state.currentQuestion;
    if (question == null) return;

    final newAnswers = Map<String, int>.from(state.answers);
    newAnswers[question.id] = optionIndex;

    state = state.copyWith(answers: newAnswers);
  }

  /// Chuyển đến câu tiếp theo.
  void nextQuestion() {
    if (state.currentIndex < state.totalQuestions - 1) {
      state = state.copyWith(currentIndex: state.currentIndex + 1);
    }
  }

  /// Quay lại câu trước.
  void previousQuestion() {
    if (state.currentIndex > 0) {
      state = state.copyWith(currentIndex: state.currentIndex - 1);
    }
  }

  /// Nhảy đến câu cụ thể.
  void goToQuestion(int index) {
    if (index >= 0 && index < state.totalQuestions) {
      state = state.copyWith(currentIndex: index);
    }
  }

  /// Nộp bài quiz.
  ///
  /// Sau khi submit thành công:
  /// - result chứa score, stars, isPassed, xpEarned, streak info
  /// - isFirstCompletionToday / alreadyPassed được dùng để hiển thị dialog phù hợp
  Future<void> submitQuiz() async {
    if (!state.allAnswered) {
      state = state.copyWith(
        error: "Bạn phải trả lời tất cả các câu hỏi trước khi nộp bài.",
      );
      return;
    }

    state = state.copyWith(isSubmitting: true, clearError: true);

    try {
      final answersList = state.answers.entries
          .map((e) => {
                "questionId": e.key,
                "selectedOptionIndex": e.value,
              })
          .toList();

      final result = await _api.submitQuiz(state.lessonId, answersList);

      state = state.copyWith(
        result: result,
        isSubmitting: false,
      );
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        error: e.toString(),
      );
    }
  }

  /// Reset quiz để làm lại (giữ nguyên lessonId, không clear result để có thể xem lại).
  void resetQuiz() {
    state = state.copyWith(
      answers: {},
      currentIndex: 0,
      clearError: true,
      clearResult: true,
    );
  }

  /// Reset hoàn toàn để bắt đầu quiz mới.
  void resetAll() {
    state = const QuizState(lessonId: "");
  }

  /// Xóa lỗi.
  void clearError() {
    state = state.copyWith(clearError: true);
  }
}

/// Provider cho QuizState.
final quizProvider = NotifierProvider<QuizNotifier, QuizState>(
  QuizNotifier.new,
);
