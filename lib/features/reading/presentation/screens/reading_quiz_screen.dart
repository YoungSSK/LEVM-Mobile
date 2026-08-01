import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../providers/reading_providers.dart';
import '../widgets/quiz_option_card.dart';

class ReadingQuizScreen extends ConsumerStatefulWidget {
  final String passageId;

  const ReadingQuizScreen({
    super.key,
    required this.passageId,
  });

  @override
  ConsumerState<ReadingQuizScreen> createState() => _ReadingQuizScreenState();
}

class _ReadingQuizScreenState extends ConsumerState<ReadingQuizScreen> {
  bool _isSubmittedCurrent = false;

  void _showPassagePeekBottomSheet(BuildContext context, String passageTitle) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Container(
          height: MediaQuery.of(context).size.height * 0.75,
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[400],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                "Đoạn văn bài đọc",
                style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              const Divider(),
              Expanded(
                child: SingleChildScrollView(
                  child: Consumer(
                    builder: (context, ref, _) {
                      final passageAsync = ref.watch(readingPassageDetailProvider(passageTitle));
                      return passageAsync.when(
                        data: (p) => Text(
                          p.plainText.isNotEmpty ? p.plainText : p.description,
                          style: AppTypography.bodyMedium.copyWith(height: 1.6),
                        ),
                        loading: () => const Center(child: CircularProgressIndicator()),
                        error: (_, _) => const Text("Không thể tải nội dung bài đọc."),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final questionsAsync = ref.watch(readingQuestionsProvider(widget.passageId));
    final quizState = ref.watch(quizNotifierProvider);
    final quizNotifier = ref.read(quizNotifierProvider.notifier);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: const Text("Bài tập đọc hiểu"),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => context.pop(),
        ),
        actions: [
          TextButton.icon(
            onPressed: () => _showPassagePeekBottomSheet(context, widget.passageId),
            icon: const Icon(Icons.import_contacts_rounded, size: 18),
            label: const Text("Xem bài đọc"),
          ),
        ],
      ),
      body: questionsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text("Lỗi: $err")),
        data: (questions) {
          if (questions.isEmpty) {
            return const Center(child: Text("Bài đọc này chưa có câu hỏi kiểm tra."));
          }

          final currentIdx = quizState.currentQuestionIndex;
          final currentQuestion = questions[currentIdx];
          final selectedOption = quizState.userAnswers[currentQuestion.id];
          final isLastQuestion = currentIdx == questions.length - 1;

          return Column(
            children: [
              // Segmented Progress Bar Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Câu ${currentIdx + 1} / ${questions.length}",
                          style: AppTypography.titleMedium.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.brandPrimary,
                          ),
                        ),
                        Text(
                          "${((currentIdx + 1) / questions.length * 100).toInt()}% hoàn thành",
                          style: AppTypography.labelMedium.copyWith(
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: (currentIdx + 1) / questions.length,
                        backgroundColor: AppColors.brandPrimary.withValues(alpha: 0.12),
                        valueColor: const AlwaysStoppedAnimation<Color>(AppColors.brandPrimary),
                        minHeight: 8,
                      ),
                    ),
                  ],
                ),
              ),

              // Question Card & Options
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Question Text Box
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: Text(
                          currentQuestion.questionText,
                          style: AppTypography.titleMedium.copyWith(
                            fontWeight: FontWeight.bold,
                            height: 1.35,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      Text(
                        "Chọn 1 đáp án đúng:",
                        style: AppTypography.labelMedium.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Options List
                      ...currentQuestion.options.map((option) {
                        final isSelected = selectedOption == option.key;
                        final isCorrectOpt = option.key == currentQuestion.correctAnswer;

                        return QuizOptionCard(
                          optionKey: option.key,
                          optionText: option.text,
                          isSelected: isSelected,
                          isSubmitted: _isSubmittedCurrent,
                          isCorrect: isCorrectOpt,
                          onTap: () {
                            quizNotifier.selectAnswer(currentQuestion.id, option.key);
                          },
                        );
                      }),
                    ],
                  ),
                ),
              ),

              // Bottom Action Button Bar
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 12,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: selectedOption == null
                        ? null
                        : () async {
                            if (!_isSubmittedCurrent) {
                              setState(() {
                                _isSubmittedCurrent = true;
                              });
                            } else {
                              if (isLastQuestion) {
                                // Submit attempt to repository & navigate to result screen
                                final repo = ref.read(readingRepositoryProvider);
                                final attempt = await repo.submitAttempt(
                                  passageId: widget.passageId,
                                  userAnswers: quizState.userAnswers,
                                  duration: 120,
                                );
                                if (context.mounted) {
                                  context.pushReplacement('/reading/result/${attempt.id}');
                                }
                              } else {
                                setState(() {
                                  _isSubmittedCurrent = false;
                                });
                                quizNotifier.nextQuestion(questions.length);
                              }
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.brandPrimary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      !_isSubmittedCurrent
                          ? "Kiểm tra đáp án"
                          : (isLastQuestion ? "Hoàn thành & Xem kết quả" : "Câu tiếp theo ➔"),
                      style: AppTypography.titleMedium.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
