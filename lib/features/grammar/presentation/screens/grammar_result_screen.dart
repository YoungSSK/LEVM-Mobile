import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:confetti/confetti.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../models/grammar_models.dart';
import '../../providers/grammar_providers.dart';
import '../../providers/grammar_quiz_provider.dart';
import '../widgets/grammar_star_rating.dart';
import '../widgets/grammar_xp_streak_banner.dart';

/// Màn hình hiển thị kết quả sau khi nộp bài trắc nghiệm.
///
/// Hiển thị:
/// - Điểm số % (vòng tròn)
/// - Số câu đúng / tổng số câu
/// - Pass/Fail status
/// - 3 sao animate
/// - XP/Streak banner nếu có reward mới
/// - Thông báo nếu đã hoàn thành trước đó
class GrammarResultScreen extends ConsumerStatefulWidget {
  final String lessonId;

  const GrammarResultScreen({
    super.key,
    required this.lessonId,
  });

  @override
  ConsumerState<GrammarResultScreen> createState() => _GrammarResultScreenState();
}

class _GrammarResultScreenState extends ConsumerState<GrammarResultScreen> {
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final result = ref.read(quizProvider).result;
      if (result != null && result.isPassed) {
        _confettiController.play();
      }
    });
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final quizState = ref.watch(quizProvider);
    final result = quizState.result;

    // Error case
    if (quizState.error != null && result == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("Kết quả"),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: AppColors.danger),
              const SizedBox(height: 16),
              Text("Lỗi: ${quizState.error}"),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => context.go("/grammar/topics"),
                child: const Text("Quay về danh sách"),
              ),
            ],
          ),
        ),
      );
    }

    if (result == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Kết quả")),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          _ResultContent(
            result: result,
            lessonId: widget.lessonId,
          ),
          // Confetti for passed
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              numberOfParticles: 50,
              maxBlastForce: 30,
              minBlastForce: 10,
              gravity: 0.2,
              colors: const [
                Colors.white,
                AppColors.xp,
                Colors.pink,
                Colors.purple,
                Colors.orange,
                AppColors.success,
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultContent extends ConsumerWidget {
  final QuizSubmitResultModel result;
  final String lessonId;

  const _ResultContent({
    required this.result,
    required this.lessonId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPassed = result.isPassed;
    final alreadyPassed = result.alreadyPassed;
    final hasXpReward = result.xpEarned > 0;
    final hasStreakReward = result.streakUpdated && result.newStreak != null;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 24),

            // Score circle
            _ScoreCircle(
              score: result.score,
              isPassed: isPassed,
            ).animate().scale(
                  begin: const Offset(0, 0),
                  end: const Offset(1, 1),
                  duration: 600.ms,
                  curve: Curves.elasticOut,
                ),

            const SizedBox(height: 24),

            // Status text
            _StatusText(
              isPassed: isPassed,
              alreadyPassed: alreadyPassed,
            ).animate().fadeIn(delay: 300.ms),

            const SizedBox(height: 16),

            // Stars
            GrammarStarRatingAnimated(
              stars: result.stars,
              size: 48,
              staggerDelay: const Duration(milliseconds: 400),
            ).animate().fadeIn(delay: 500.ms),

            const SizedBox(height: 24),

            // XP/Streak banner
            if (hasXpReward || hasStreakReward)
              GrammarXpStreakBanner(
                xpEarned: result.xpEarned,
                newStreak: result.newStreak,
                showStreakAnimation: true,
              ).animate().fadeIn(delay: 700.ms).slideY(begin: 0.2, end: 0),

            // Already passed notice
            if (alreadyPassed) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.info.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.info.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      color: AppColors.info,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "Bạn đã hoàn thành bài này trước đó, kết quả chỉ để tham khảo.",
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.info,
                        ),
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 800.ms),
            ],

            const SizedBox(height: 32),

            // Stats card
            _StatsCard(result: result)
                .animate()
                .fadeIn(delay: 600.ms)
                .slideY(begin: 0.2, end: 0),

            const SizedBox(height: 32),

            // Action buttons
            _ActionButtons(
              isPassed: isPassed,
              alreadyPassed: alreadyPassed,
              lessonId: lessonId,
            ).animate().fadeIn(delay: 800.ms),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _ScoreCircle extends StatelessWidget {
  final double score;
  final bool isPassed;

  const _ScoreCircle({
    required this.score,
    required this.isPassed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 180,
      height: 180,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: isPassed
              ? [AppColors.success, AppColors.success.withValues(alpha: 0.7)]
              : [AppColors.danger, AppColors.danger.withValues(alpha: 0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: (isPassed ? AppColors.success : AppColors.danger)
                .withValues(alpha: 0.3),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "${score.toInt()}%",
              style: AppTypography.displayLarge.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              isPassed ? "Đạt!" : "Chưa đạt",
              style: AppTypography.titleMedium.copyWith(
                color: Colors.white.withValues(alpha: 0.9),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusText extends StatelessWidget {
  final bool isPassed;
  final bool alreadyPassed;

  const _StatusText({
    required this.isPassed,
    required this.alreadyPassed,
  });

  @override
  Widget build(BuildContext context) {
    String message;
    IconData icon;
    Color color;

    if (alreadyPassed) {
      message = "Bài đã hoàn thành trước đó";
      icon = Icons.history_rounded;
      color = AppColors.info;
    } else if (isPassed) {
      message = "Chúc mừng bạn đã vượt qua!";
      icon = Icons.celebration_rounded;
      color = AppColors.success;
    } else {
      message = "Cố gắng hơn lần sau nhé!";
      icon = Icons.emoji_events_outlined;
      color = AppColors.warning;
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(width: 8),
        Text(
          message,
          style: AppTypography.titleMedium.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _StatsCard extends StatelessWidget {
  final QuizSubmitResultModel result;

  const _StatsCard({required this.result});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(context).dividerColor,
        ),
      ),
      child: Column(
        children: [
          Text(
            "Chi tiết kết quả",
            style: AppTypography.titleMedium.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _StatItem(
                value: "${result.correctCount}",
                label: "Câu đúng",
                icon: Icons.check_circle_rounded,
                color: AppColors.success,
              ),
              Container(
                width: 1,
                height: 40,
                color: Theme.of(context).dividerColor,
              ),
              _StatItem(
                value: "${result.totalQuestions - result.correctCount}",
                label: "Câu sai",
                icon: Icons.cancel_rounded,
                color: AppColors.danger,
              ),
              Container(
                width: 1,
                height: 40,
                color: Theme.of(context).dividerColor,
              ),
              _StatItem(
                value: "${result.totalQuestions}",
                label: "Tổng cộng",
                icon: Icons.quiz_rounded,
                color: AppColors.brandPrimary,
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Ngưỡng đạt",
                style: AppTypography.bodyMedium.copyWith(
                  color: Theme.of(context).hintColor,
                ),
              ),
              Text(
                "${result.passThreshold}%",
                style: AppTypography.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          if (result.stars > 0) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Số sao đạt được",
                  style: AppTypography.bodyMedium.copyWith(
                    color: Theme.of(context).hintColor,
                  ),
                ),
                Row(
                  children: [
                    GrammarStarRating(stars: result.stars, size: 18),
                    const SizedBox(width: 4),
                    Text(
                      "${result.stars}/3",
                      style: AppTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color color;

  const _StatItem({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: AppTypography.titleLarge.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: AppTypography.bodySmall.copyWith(
            color: Theme.of(context).hintColor,
          ),
        ),
      ],
    );
  }
}

class _ActionButtons extends ConsumerWidget {
  final bool isPassed;
  final bool alreadyPassed;
  final String lessonId;

  const _ActionButtons({
    required this.isPassed,
    required this.alreadyPassed,
    required this.lessonId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        // Continue button
        SizedBox(
          width: double.infinity,
          child: Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: AppColors.brandGradient,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: ElevatedButton(
              onPressed: () async {
                // Reset quiz state
                ref.read(quizProvider.notifier).resetAll();
                context.go("/grammar/topics");
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.home_rounded, color: Colors.white),
                  const SizedBox(width: 8),
                  Text(
                    "Về danh sách bài học",
                    style: AppTypography.titleMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        if (!isPassed) ...[
          const SizedBox(height: 12),

          // Retry buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    ref.read(quizProvider.notifier).resetQuiz();
                    context.pushReplacement("/grammar/lessons/$lessonId/quiz");
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.refresh_rounded),
                      SizedBox(width: 4),
                      Text("Làm lại"),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    ref.read(quizProvider.notifier).resetAll();
                    context.pushReplacement("/grammar/lessons/$lessonId/theory");
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.menu_book_rounded),
                      SizedBox(width: 4),
                      Text("Đọc lại"),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],

        if (isPassed && !alreadyPassed) ...[
          const SizedBox(height: 12),
          // Try next lesson
          _TryNextLessonButton(lessonId: lessonId),
        ],
      ],
    );
  }
}

class _TryNextLessonButton extends ConsumerWidget {
  final String lessonId;

  const _TryNextLessonButton({required this.lessonId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nextLessonAsync = ref.watch(grammarNextLessonProvider(lessonId));

    return nextLessonAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (e, s) => const SizedBox.shrink(),
      data: (nextLesson) {
        if (nextLesson == null) return const SizedBox.shrink();

        return SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () {
              ref.read(quizProvider.notifier).resetAll();
              context.pushReplacement("/grammar/lessons/${nextLesson.id}/theory");
            },
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.arrow_forward_rounded),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    "Bài tiếp theo: ${nextLesson.title}",
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
