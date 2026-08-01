import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/reading_repository.dart';
import '../../domain/models/reading_category.dart';
import '../../domain/models/reading_passage.dart';
import '../../domain/models/reading_question.dart';

final readingRepositoryProvider = Provider<ReadingRepository>((ref) {
  return ReadingRepository();
});

// Categories provider — always returns list (never throws)
final readingCategoriesProvider = FutureProvider<List<ReadingCategory>>((ref) async {
  try {
    final repository = ref.watch(readingRepositoryProvider);
    return await repository.getCategories();
  } catch (_) {
    return const [
      ReadingCategory(id: 'cat_1', title: 'Tất cả', slug: 'all'),
    ];
  }
});

// Filter state notifiers
class SelectedCategoryNotifier extends Notifier<String> {
  @override
  String build() => 'cat_1';
  void setCategory(String categoryId) => state = categoryId;
}

final selectedCategoryProvider =
    NotifierProvider<SelectedCategoryNotifier, String>(SelectedCategoryNotifier.new);

class SelectedCefrNotifier extends Notifier<String> {
  @override
  String build() => 'All';
  void setCefr(String cefr) => state = cefr;
}

final selectedCefrLevelProvider =
    NotifierProvider<SelectedCefrNotifier, String>(SelectedCefrNotifier.new);

class SearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';
  void setSearch(String query) => state = query;
}

final readingSearchQueryProvider =
    NotifierProvider<SearchQueryNotifier, String>(SearchQueryNotifier.new);

// Passages list provider — always returns list (never throws)
final readingPassagesProvider = FutureProvider<List<ReadingPassage>>((ref) async {
  try {
    final repository = ref.watch(readingRepositoryProvider);
    final categoryId = ref.watch(selectedCategoryProvider);
    final cefrLevel = ref.watch(selectedCefrLevelProvider);
    final search = ref.watch(readingSearchQueryProvider);

    return await repository.getPassages(
      categoryId: categoryId,
      cefrLevel: cefrLevel,
      search: search,
    );
  } catch (_) {
    return const [];
  }
});

// Single passage detail provider — always returns passage (never throws)
final readingPassageDetailProvider =
    FutureProvider.family<ReadingPassage, String>((ref, passageId) async {
  try {
    final repository = ref.watch(readingRepositoryProvider);
    return await repository.getPassageDetail(passageId);
  } catch (_) {
    return const ReadingPassage(
      id: 'fallback',
      categoryId: '',
      title: 'Không thể tải bài đọc',
      slug: 'fallback',
      description: 'Vui lòng kiểm tra kết nối mạng và thử lại.',
      htmlContent: '<p>Vui lòng kiểm tra kết nối mạng và thử lại.</p>',
    );
  }
});

// Passage questions provider — always returns list (never throws)
final readingQuestionsProvider =
    FutureProvider.family<List<ReadingQuestion>, String>((ref, passageId) async {
  try {
    final repository = ref.watch(readingRepositoryProvider);
    return await repository.getPassageQuestions(passageId);
  } catch (_) {
    return const [];
  }
});

// User settings state for reader (Font size, Theme)
enum ReaderThemeMode { light, dark, sepia }

class ReaderSettings {
  final double fontSize;
  final ReaderThemeMode themeMode;

  const ReaderSettings({
    this.fontSize = 16.0,
    this.themeMode = ReaderThemeMode.light,
  });

  ReaderSettings copyWith({
    double? fontSize,
    ReaderThemeMode? themeMode,
  }) {
    return ReaderSettings(
      fontSize: fontSize ?? this.fontSize,
      themeMode: themeMode ?? this.themeMode,
    );
  }
}

class ReaderSettingsNotifier extends Notifier<ReaderSettings> {
  @override
  ReaderSettings build() => const ReaderSettings();

  void setFontSize(double size) {
    state = state.copyWith(fontSize: size);
  }

  void setThemeMode(ReaderThemeMode mode) {
    state = state.copyWith(themeMode: mode);
  }
}

final readerSettingsProvider =
    NotifierProvider<ReaderSettingsNotifier, ReaderSettings>(ReaderSettingsNotifier.new);

// Quiz State Notifier
class QuizState {
  final int currentQuestionIndex;
  final Map<String, String> userAnswers;
  final int duration;
  final bool isSubmitting;

  const QuizState({
    this.currentQuestionIndex = 0,
    this.userAnswers = const {},
    this.duration = 0,
    this.isSubmitting = false,
  });

  QuizState copyWith({
    int? currentQuestionIndex,
    Map<String, String>? userAnswers,
    int? duration,
    bool? isSubmitting,
  }) {
    return QuizState(
      currentQuestionIndex: currentQuestionIndex ?? this.currentQuestionIndex,
      userAnswers: userAnswers ?? this.userAnswers,
      duration: duration ?? this.duration,
      isSubmitting: isSubmitting ?? this.isSubmitting,
    );
  }
}

class QuizNotifier extends Notifier<QuizState> {
  @override
  QuizState build() => const QuizState();

  void selectAnswer(String questionId, String optionKey) {
    final updated = Map<String, String>.from(state.userAnswers);
    updated[questionId] = optionKey;
    state = state.copyWith(userAnswers: updated);
  }

  void nextQuestion(int maxCount) {
    if (state.currentQuestionIndex < maxCount - 1) {
      state = state.copyWith(currentQuestionIndex: state.currentQuestionIndex + 1);
    }
  }

  void previousQuestion() {
    if (state.currentQuestionIndex > 0) {
      state = state.copyWith(currentQuestionIndex: state.currentQuestionIndex - 1);
    }
  }

  void updateDuration(int seconds) {
    state = state.copyWith(duration: seconds);
  }

  void reset() {
    state = const QuizState();
  }
}

final quizNotifierProvider =
    NotifierProvider<QuizNotifier, QuizState>(QuizNotifier.new);
