import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../providers/grammar_quiz_provider.dart';
import '../widgets/grammar_progress_bar.dart';
import '../widgets/grammar_quiz_option_tile.dart';

/// Màn hình làm bài trắc nghiệm Grammar.
///
/// Flow:
/// 1. Load câu hỏi từ /quiz-play endpoint (không có isCorrect/explanation).
/// 2. Hiển thị câu hỏi từng lượt với progress bar.
/// 3. Cho phép back nhưng cảnh báo mất tiến trình.
/// 4. Nộp bài → chuyển sang Result screen.
class GrammarQuizScreen extends ConsumerStatefulWidget {
  final String lessonId;

  const GrammarQuizScreen({
    super.key,
    required this.lessonId,
  });

  @override
  ConsumerState<GrammarQuizScreen> createState() => _GrammarQuizScreenState();
}

class _GrammarQuizScreenState extends ConsumerState<GrammarQuizScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(quizProvider.notifier).initQuiz(widget.lessonId);
    });
  }

  Future<bool> _onWillPop() async {
    final quizState = ref.read(quizProvider);
    if (quizState.answeredCount > 0) {
      final shouldLeave = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Rời khỏi bài trắc nghiệm?"),
          content: const Text(
            "Bạn đã trả lời một số câu hỏi. Nếu rời đi, tiến trình sẽ bị mất.",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text("Ở lại"),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text("Rời đi"),
            ),
          ],
        ),
      );
      if (shouldLeave == true) {
        ref.read(quizProvider.notifier).resetAll();
        return true;
      }
      return false;
    }
    ref.read(quizProvider.notifier).resetAll();
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final quizState = ref.watch(quizProvider);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && context.mounted) {
          context.pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Trắc nghiệm"),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () async {
              final shouldPop = await _onWillPop();
              if (shouldPop && context.mounted && context.canPop()) {
                context.pop();
              }
            },
          ),
        ),
        body: _buildBody(context, quizState),
      ),
    );
  }

  Widget _buildBody(BuildContext context, QuizState quizState) {
    // Loading
    if (quizState.isSubmitting && quizState.questions.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text("Đang tải câu hỏi..."),
          ],
        ),
      );
    }

    // Error
    if (quizState.error != null && quizState.questions.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: AppColors.danger),
              const SizedBox(height: 16),
              Text(
                "Lỗi: ${quizState.error}",
                textAlign: TextAlign.center,
                style: AppTypography.bodyMedium,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  ref.read(quizProvider.notifier).initQuiz(widget.lessonId);
                },
                child: const Text("Thử lại"),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () {
                  ref.read(quizProvider.notifier).resetAll();
                  context.pop();
                },
                child: const Text("Quay lại"),
              ),
            ],
          ),
        ),
      );
    }

    // Empty quiz
    if (quizState.questions.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.quiz_outlined, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                "Bài trắc nghiệm này chưa có câu hỏi",
                style: AppTypography.bodyMedium.copyWith(
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => context.pop(),
                child: const Text("Quay lại"),
              ),
            ],
          ),
        ),
      );
    }

    return _QuizContent(
      quizState: quizState,
      lessonId: widget.lessonId,
    );
  }
}

class _QuizContent extends ConsumerWidget {
  final QuizState quizState;
  final String lessonId;

  const _QuizContent({
    required this.quizState,
    required this.lessonId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final question = quizState.currentQuestion;
    if (question == null) return const SizedBox.shrink();

    return Column(
      children: [
        // Progress bar
        Padding(
          padding: const EdgeInsets.all(16),
          child: GrammarQuizProgressBar(
            current: quizState.currentIndex + 1,
            total: quizState.totalQuestions,
          ),
        ),

        // Question
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Question number indicator
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.brandPrimary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        "Câu ${quizState.currentIndex + 1}",
                        style: AppTypography.labelMedium.copyWith(
                          color: AppColors.brandPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Question text
                Text(
                  question.questionText,
                  style: AppTypography.titleLarge,
                ),
                const SizedBox(height: 24),

                // Options
                ...question.options.asMap().entries.map((entry) {
                  final index = entry.key;
                  final option = entry.value;
                  final isSelected = quizState.currentSelectedOption == index;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: GrammarQuizOptionTile(
                      text: option.text,
                      index: index,
                      isSelected: isSelected,
                      onTap: () {
                        ref.read(quizProvider.notifier).selectAnswer(index);
                      },
                    ),
                  );
                }),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),

        // Navigation buttons
        _NavigationButtons(
          quizState: quizState,
          lessonId: lessonId,
        ),
      ],
    );
  }
}

class _NavigationButtons extends ConsumerWidget {
  final QuizState quizState;
  final String lessonId;

  const _NavigationButtons({
    required this.quizState,
    required this.lessonId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLast = quizState.currentIndex == quizState.totalQuestions - 1;
    final hasAnsweredCurrent = quizState.currentSelectedOption != null;
    final isSubmitting = quizState.isSubmitting;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).dividerColor,
          ),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Back button
            if (quizState.currentIndex > 0)
              Expanded(
                child: OutlinedButton(
                  onPressed: isSubmitting
                      ? null
                      : () {
                          ref.read(quizProvider.notifier).previousQuestion();
                        },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.arrow_back_rounded),
                      SizedBox(width: 4),
                      Text("Quay lại"),
                    ],
                  ),
                ),
              ),

            if (quizState.currentIndex > 0) const SizedBox(width: 12),

            // Next / Submit button
            Expanded(
              flex: 2,
              child: Container(
                decoration: BoxDecoration(
                  gradient: hasAnsweredCurrent || isLast
                      ? const LinearGradient(colors: AppColors.brandGradient)
                      : null,
                  color: hasAnsweredCurrent || isLast ? null : Colors.grey[400],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ElevatedButton(
                  onPressed: isSubmitting
                      ? null
                      : hasAnsweredCurrent
                          ? () async {
                              if (isLast) {
                                await ref.read(quizProvider.notifier).submitQuiz();
                                final newState = ref.read(quizProvider);
                                if (newState.result != null && context.mounted) {
                                  context.pushReplacement(
                                    "/grammar/lessons/$lessonId/result",
                                  );
                                }
                              } else {
                                ref.read(quizProvider.notifier).nextQuestion();
                              }
                            }
                          : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    disabledBackgroundColor: Colors.transparent,
                  ),
                  child: isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          isLast ? "Nộp bài" : "Tiếp theo",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
