import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:confetti/confetti.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../providers/xp_streak_provider.dart';
import '../../providers/study_session_provider.dart';
import '../../providers/vocabulary_providers.dart';

class LevelResultScreen extends ConsumerStatefulWidget {
  final String attemptId;

  const LevelResultScreen({super.key, required this.attemptId});

  @override
  ConsumerState<LevelResultScreen> createState() => _LevelResultScreenState();
}

class _LevelResultScreenState extends ConsumerState<LevelResultScreen> {
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _confettiController.play();
      ref.read(xpStreakProvider.notifier).loadXpAndStreak();
      _invalidateLessonCaches();
    });
  }

  /// Drop any cached lesson stats / detail so the next visit to the lesson
  /// detail screen reflects the latest server data (new stars, attempt count,
  /// completion flags, ...).
  void _invalidateLessonCaches() {
    final sessionState = ref.read(studySessionProvider);
    final result = sessionState.lastResult;
    final lessonId = result?.attempt.lessonId;
    if (lessonId == null || lessonId.isEmpty) return;

    ref.invalidate(lessonStatsProvider(lessonId));
    ref.invalidate(lessonDetailProvider(lessonId));
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final xpStreakState = ref.watch(xpStreakProvider);

    return Scaffold(
      body: Stack(
        children: [
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const Spacer(),
                  _buildResultContent(context, xpStreakState),
                  const Spacer(),
                  _buildActions(context),
                ],
              ),
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              numberOfParticles: 50,
              colors: const [
                AppColors.xp,
                AppColors.success,
                AppColors.brandPrimary,
                Colors.purple,
                Colors.pink,
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultContent(BuildContext context, XpStreakState xpStreakState) {
    final sessionState = ref.watch(studySessionProvider);
    final result = sessionState.lastResult;

    if (result == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final attempt = result.attempt;
    final xpResults = result.xpResults;
    final streakResult = result.streakResult;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildScoreCircle(attempt.score, attempt.stars)
            .animate()
            .scale(
              begin: const Offset(0, 0),
              end: const Offset(1, 1),
              duration: 600.ms,
              curve: Curves.elasticOut,
            ),
        const SizedBox(height: 32),
        Text(
          _getScoreMessage(attempt.score),
          style: AppTypography.headlineMedium.copyWith(
            fontWeight: FontWeight.bold,
          ),
        )
            .animate()
            .fadeIn(delay: 300.ms, duration: 400.ms)
            .slideY(begin: 0.3, end: 0),
        const SizedBox(height: 8),
        Text(
          "Cấp ${attempt.level}",
          style: AppTypography.titleMedium.copyWith(
            color: Theme.of(context).hintColor,
          ),
        )
            .animate()
            .fadeIn(delay: 400.ms, duration: 400.ms),
        const SizedBox(height: 32),
        _buildStatsRow(attempt, xpResults, streakResult)
            .animate()
            .fadeIn(delay: 500.ms, duration: 400.ms)
            .slideY(begin: 0.3, end: 0),
      ],
    );
  }

  Widget _buildScoreCircle(int score, int stars) {
    return CircularPercentIndicator(
      radius: 100,
      lineWidth: 12,
      percent: score / 100,
      center: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "$score%",
            style: AppTypography.displayMedium.copyWith(
              fontWeight: FontWeight.bold,
              color: _getScoreColor(score),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(3, (index) {
              return Icon(
                index < stars ? Icons.star_rounded : Icons.star_border_rounded,
                color: index < stars ? AppColors.xp : Colors.grey[400],
                size: 28,
              );
            }),
          ),
        ],
      ),
      progressColor: _getScoreColor(score),
      backgroundColor: _getScoreColor(score).withValues(alpha: 0.2),
      circularStrokeCap: CircularStrokeCap.round,
      animation: true,
      animationDuration: 1000,
    );
  }

  Widget _buildStatsRow(
    dynamic attempt,
    dynamic xpResults,
    dynamic streakResult,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        children: [
          _buildStatRow(
            Icons.check_circle_rounded,
            "${attempt.correctCount}/${attempt.totalCount}",
            "Câu đúng",
            AppColors.success,
          ),
          const Divider(height: 24),
          _buildStatRow(
            Icons.star_rounded,
            "+${xpResults?.totalXp ?? 0} XP",
            "XP nhận được",
            AppColors.xp,
          ),
          if (streakResult?.currentStreak != null && streakResult!.currentStreak > 0) ...[
            const Divider(height: 24),
            _buildStatRow(
              Icons.local_fire_department_rounded,
              "${streakResult.currentStreak} ngày",
              "Streak",
              AppColors.streak,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatRow(IconData icon, String value, String label, Color color) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            label,
            style: AppTypography.bodyMedium.copyWith(
              color: Theme.of(context).hintColor,
            ),
          ),
        ),
        Text(
          value,
          style: AppTypography.titleMedium.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildActions(BuildContext context) {
    final sessionState = ref.watch(studySessionProvider);
    final result = sessionState.lastResult;

    return Column(
      children: [
        if (result?.allLevelsComplete == true) ...[
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                context.go("/vocabulary/summary/${result!.attempt.lessonId}");
              },
              icon: const Icon(Icons.emoji_events_rounded),
              label: const Text("Xem tổng kết bài học"),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.xp,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  context.go("/home");
                },
                icon: const Icon(Icons.home_rounded),
                label: const Text("Về trang chủ"),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _restartLevel(result),
                icon: const Icon(Icons.replay_rounded),
                label: const Text("Học lại"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.brandPrimary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Re-launch the same level for the current lesson. Resets the study
  /// session state and navigates back into the matching level route, so the
  /// user gets a fresh attempt with the same lesson words.
  void _restartLevel(dynamic result) {
    if (result == null) return;

    final lessonId = result.attempt.lessonId as String;
    final level = result.attempt.level as int;

    // Reset session so the re-launched screen starts clean.
    ref.read(studySessionProvider.notifier).reset();

    final route = switch (level) {
      1 => '/vocabulary/lessons/$lessonId/flashcard',
      2 => '/vocabulary/lessons/$lessonId/recall',
      3 => '/vocabulary/lessons/$lessonId/spelling',
      _ => '/vocabulary/lessons/$lessonId',
    };

    context.go(route);
  }

  Color _getScoreColor(int score) {
    if (score >= 90) return AppColors.success;
    if (score >= 70) return AppColors.warning;
    if (score >= 50) return AppColors.info;
    return AppColors.danger;
  }

  String _getScoreMessage(int score) {
    if (score >= 90) return "Xuất sắc!";
    if (score >= 70) return "Tốt lắm!";
    if (score >= 50) return "Cố gắng hơn nhé!";
    return "Cần luyện tập thêm";
  }
}
