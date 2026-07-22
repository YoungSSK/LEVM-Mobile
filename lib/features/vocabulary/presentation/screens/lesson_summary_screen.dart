import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:confetti/confetti.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../providers/vocabulary_providers.dart';
import '../../providers/xp_streak_provider.dart';

class LessonSummaryScreen extends ConsumerStatefulWidget {
  final String lessonId;

  const LessonSummaryScreen({super.key, required this.lessonId});

  @override
  ConsumerState<LessonSummaryScreen> createState() => _LessonSummaryScreenState();
}

class _LessonSummaryScreenState extends ConsumerState<LessonSummaryScreen> {
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 5));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _confettiController.play();
      ref.read(xpStreakProvider.notifier).loadXpAndStreak();
      // Force-refresh stats so the summary reflects the latest server data.
      ref.invalidate(lessonStatsProvider(widget.lessonId));
    });
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lessonAsync = ref.watch(lessonDetailProvider(widget.lessonId));
    final statsAsync = ref.watch(lessonStatsProvider(widget.lessonId));
    final xpStreakState = ref.watch(xpStreakProvider);

    return Scaffold(
      body: Stack(
        children: [
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const SizedBox(height: 24),
                  _buildHeader(context)
                      .animate()
                      .fadeIn(duration: 400.ms)
                      .slideY(begin: -0.3, end: 0),
                  const SizedBox(height: 32),
                  Expanded(
                    child: lessonAsync.when(
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (e, _) => Center(child: Text("Lỗi: $e")),
                      data: (lesson) => statsAsync.when(
                        loading: () => const Center(child: CircularProgressIndicator()),
                        error: (e, _) => Center(child: Text("Lỗi: $e")),
                        data: (stats) => _buildContent(context, lesson, stats, xpStreakState),
                      ),
                    ),
                  ),
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
              numberOfParticles: 100,
              colors: const [
                AppColors.xp,
                AppColors.success,
                AppColors.brandPrimary,
                Colors.purple,
                Colors.pink,
                Colors.orange,
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: AppColors.brandGradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.emoji_events_rounded,
            color: Colors.white,
            size: 40,
          ),
        )
            .animate()
            .scale(
              begin: const Offset(0, 0),
              end: const Offset(1, 1),
              duration: 600.ms,
              curve: Curves.elasticOut,
            ),
        const SizedBox(height: 16),
        Text(
          "Hoàn thành bài học!",
          style: AppTypography.headlineMedium.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "Chúc mừng bạn đã hoàn thành bài học này",
          style: AppTypography.bodyMedium.copyWith(
            color: Theme.of(context).hintColor,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildContent(
    BuildContext context,
    dynamic lesson,
    dynamic stats,
    XpStreakState xpStreakState,
  ) {
    final totalStars = stats?.totalStars ?? 0;
    final maxStars = 9;

    return SingleChildScrollView(
      child: Column(
        children: [
          _buildTotalStarsSection(context, totalStars, maxStars)
              .animate()
              .fadeIn(delay: 200.ms, duration: 400.ms)
              .slideY(begin: 0.3, end: 0),
          const SizedBox(height: 24),
          _buildXpSection(context, xpStreakState)
              .animate()
              .fadeIn(delay: 400.ms, duration: 400.ms)
              .slideY(begin: 0.3, end: 0),
          const SizedBox(height: 24),
          _buildStreakSection(context, xpStreakState)
              .animate()
              .fadeIn(delay: 500.ms, duration: 400.ms)
              .slideY(begin: 0.3, end: 0),
          const SizedBox(height: 24),
          _buildLevelProgressSection(context, stats)
              .animate()
              .fadeIn(delay: 600.ms, duration: 400.ms)
              .slideY(begin: 0.3, end: 0),
        ],
      ),
    );
  }

  Widget _buildTotalStarsSection(BuildContext context, int totalStars, int maxStars) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        children: [
          Text(
            "Tổng sao đạt được",
            style: AppTypography.titleMedium,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(maxStars, (index) {
              final isFilled = index < totalStars;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Icon(
                  isFilled ? Icons.star_rounded : Icons.star_border_rounded,
                  color: isFilled ? AppColors.xp : Colors.grey[400],
                  size: 32,
                ),
              );
            }),
          ),
          const SizedBox(height: 16),
          Text(
            "$totalStars / $maxStars sao",
            style: AppTypography.headlineSmall.copyWith(
              color: AppColors.xp,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildXpSection(BuildContext context, XpStreakState xpStreakState) {
    final xpInfo = xpStreakState.xpInfo;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.xp.withValues(alpha: 0.2),
            AppColors.xp.withValues(alpha: 0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.xp.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.star_rounded, color: AppColors.xp, size: 32),
              const SizedBox(width: 8),
              Text(
                "Cấp ${xpInfo?.currentLevel ?? 1}",
                style: AppTypography.titleLarge.copyWith(
                  color: AppColors.xp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          CircularPercentIndicator(
            radius: 60,
            lineWidth: 8,
            percent: xpInfo?.progressInLevel ?? 0,
            center: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "${xpInfo?.totalXp ?? 0}",
                  style: AppTypography.headlineSmall.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  "XP",
                  style: AppTypography.bodySmall.copyWith(
                    color: Theme.of(context).hintColor,
                  ),
                ),
              ],
            ),
            progressColor: AppColors.xp,
            backgroundColor: AppColors.xp.withValues(alpha: 0.2),
            circularStrokeCap: CircularStrokeCap.round,
            animation: true,
          ),
          const SizedBox(height: 16),
          Text(
            "Còn ${xpInfo?.xpToNextLevel ?? 100} XP để lên cấp ${(xpInfo?.currentLevel ?? 1) + 1}",
            style: AppTypography.bodySmall.copyWith(
              color: Theme.of(context).hintColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStreakSection(BuildContext context, XpStreakState xpStreakState) {
    final streakInfo = xpStreakState.streakInfo;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.streak.withValues(alpha: 0.2),
            AppColors.streak.withValues(alpha: 0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.streak.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.local_fire_department_rounded, color: AppColors.streak, size: 32),
              const SizedBox(width: 8),
              Text(
                "${streakInfo?.currentStreak ?? 0} ngày",
                style: AppTypography.titleLarge.copyWith(
                  color: AppColors.streak,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            "Kỷ lục: ${streakInfo?.longestStreak ?? 0} ngày",
            style: AppTypography.bodyMedium.copyWith(
              color: Theme.of(context).hintColor,
            ),
          ),
          if (streakInfo?.studiedToday == true) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    "Đã học hôm nay",
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.success,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLevelProgressSection(BuildContext context, dynamic stats) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Tiến độ các cấp độ",
            style: AppTypography.titleMedium,
          ),
          const SizedBox(height: 16),
          _buildLevelProgressItem(context, 1, "Ghi nhớ", Icons.style_rounded, stats),
          const SizedBox(height: 12),
          _buildLevelProgressItem(context, 2, "Ghép từ", Icons.grid_view_rounded, stats),
          const SizedBox(height: 12),
          _buildLevelProgressItem(context, 3, "Chính tả", Icons.keyboard_rounded, stats),
        ],
      ),
    );
  }

  Widget _buildLevelProgressItem(
    BuildContext context,
    int level,
    String name,
    IconData icon,
    dynamic stats,
  ) {
    final levelStats = stats?.levelStats?[level];
    final completed = levelStats?.completed ?? false;
    final bestScore = levelStats?.bestScore ?? 0;
    final bestStars = levelStats?.bestStars ?? 0;

    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: completed
                ? _getLevelColor(level).withValues(alpha: 0.15)
                : Colors.grey[200],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: completed ? _getLevelColor(level) : Colors.grey[500],
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: AppTypography.bodyMedium),
              if (completed) ...[
                const SizedBox(height: 4),
                Row(
                  children: List.generate(3, (index) {
                    return Icon(
                      index < bestStars ? Icons.star_rounded : Icons.star_border_rounded,
                      color: index < bestStars ? AppColors.xp : Colors.grey[400],
                      size: 16,
                    );
                  }),
                ),
              ],
            ],
          ),
        ),
        if (completed)
          Text(
            "$bestScore%",
            style: AppTypography.titleMedium.copyWith(
              color: _getLevelColor(level),
              fontWeight: FontWeight.bold,
            ),
          )
        else
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              "Chưa học",
              style: AppTypography.bodySmall.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ),
      ],
    );
  }

  Color _getLevelColor(int level) {
    switch (level) {
      case 1:
        return AppColors.success;
      case 2:
        return AppColors.warning;
      case 3:
        return AppColors.danger;
      default:
        return AppColors.brandPrimary;
    }
  }

  Widget _buildActions(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              context.go("/home");
            },
            icon: const Icon(Icons.home_rounded),
            label: const Text("Về trang chủ"),
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
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
              context.go("/vocabulary/lessons/${widget.lessonId}");
            },
            icon: const Icon(Icons.replay_rounded),
            label: const Text("Học lại"),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
