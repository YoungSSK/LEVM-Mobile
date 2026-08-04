import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/listening_repository.dart';
import '../../domain/models/listening_models.dart';

final listeningRepositoryProvider = Provider<ListeningRepository>((ref) {
  return ListeningRepository();
});

final listeningSetsProvider =
    FutureProvider.family<List<ListeningSet>, int?>((ref, part) async {
  final repository = ref.watch(listeningRepositoryProvider);
  return repository.getListeningSets(part: part);
});

class ListeningSessionState {
  final ListeningPlayPayload? payload;
  final bool isLoading;
  final String? errorMessage;
  final Map<String, String> selectedAnswers; // questionId -> selectedKey
  final int currentQuestionIndex;
  final int durationSeconds;
  final ListeningSubmitResult? submitResult;
  final bool isSubmitting;

  const ListeningSessionState({
    this.payload,
    this.isLoading = false,
    this.errorMessage,
    this.selectedAnswers = const {},
    this.currentQuestionIndex = 0,
    this.durationSeconds = 0,
    this.submitResult,
    this.isSubmitting = false,
  });

  ListeningSessionState copyWith({
    ListeningPlayPayload? payload,
    bool? isLoading,
    String? errorMessage,
    Map<String, String>? selectedAnswers,
    int? currentQuestionIndex,
    int? durationSeconds,
    ListeningSubmitResult? submitResult,
    bool? isSubmitting,
  }) {
    return ListeningSessionState(
      payload: payload ?? this.payload,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      selectedAnswers: selectedAnswers ?? this.selectedAnswers,
      currentQuestionIndex: currentQuestionIndex ?? this.currentQuestionIndex,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      submitResult: submitResult ?? this.submitResult,
      isSubmitting: isSubmitting ?? this.isSubmitting,
    );
  }
}

class ListeningSessionNotifier extends Notifier<ListeningSessionState> {
  @override
  ListeningSessionState build() => const ListeningSessionState();

  ListeningRepository get _repository => ref.read(listeningRepositoryProvider);

  Future<void> loadSession(String setId) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final payload = await _repository.getPlayPayload(setId);
      state = state.copyWith(
        payload: payload,
        isLoading: false,
        selectedAnswers: {},
        currentQuestionIndex: 0,
        durationSeconds: 0,
        submitResult: null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Lỗi tải bài nghe: ${e.toString()}',
      );
    }
  }

  void selectAnswer(String questionId, String key) {
    final updated = Map<String, String>.from(state.selectedAnswers);
    updated[questionId] = key;
    state = state.copyWith(selectedAnswers: updated);
  }

  void setQuestionIndex(int index) {
    state = state.copyWith(currentQuestionIndex: index);
  }

  void incrementDuration() {
    state = state.copyWith(durationSeconds: state.durationSeconds + 1);
  }

  Future<ListeningSubmitResult?> submitQuizWithDuration(int durationSeconds) async {
    if (state.payload == null) return null;
    state = state.copyWith(isSubmitting: true);

    try {
      final answersList = state.selectedAnswers.entries
          .map((e) => {'questionId': e.key, 'selectedKey': e.value})
          .toList();

      final result = await _repository.submitAttempt(
        setId: state.payload!.set.id,
        durationSeconds: durationSeconds,
        answers: answersList,
      );

      state = state.copyWith(
        isSubmitting: false,
        submitResult: result,
      );
      return result;
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: 'Lỗi nộp bài: ${e.toString()}',
      );
      return null;
    }
  }

  Future<ListeningSubmitResult?> submitQuiz() async {
    return submitQuizWithDuration(state.durationSeconds);
  }
}

final listeningSessionProvider =
    NotifierProvider<ListeningSessionNotifier, ListeningSessionState>(
        ListeningSessionNotifier.new);
