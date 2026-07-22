import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../providers/vocabulary_providers.dart';

class LessonDetailScreen extends ConsumerStatefulWidget {
  final String lessonId;

  const LessonDetailScreen({
    super.key,
    required this.lessonId,
  });

  @override
  ConsumerState<LessonDetailScreen> createState() => _LessonDetailScreenState();
}

class _LessonDetailScreenState extends ConsumerState<LessonDetailScreen> {
  @override
  void initState() {
    super.initState();
    // Always refetch stats whenever the screen is freshly mounted so the
    // displayed stars / attempts always reflect the latest server state
    // (e.g. after completing a level and coming back).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.invalidate(lessonStatsProvider(widget.lessonId));
      ref.invalidate(lessonDetailProvider(widget.lessonId));
    });
  }

  @override
  Widget build(BuildContext context) {
    final lessonAsync = ref.watch(lessonDetailProvider(widget.lessonId));
    final statsAsync = ref.watch(lessonStatsProvider(widget.lessonId));

    return Scaffold(
      appBar: AppBar(
        title: const Text("Chi tiết bài học"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: lessonAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.danger),
              const SizedBox(height: 16),
              Text("Lỗi: $error"),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.refresh(lessonDetailProvider(widget.lessonId)),
                child: const Text("Thử lại"),
              ),
            ],
          ),
        ),
        data: (lesson) {
          return statsAsync.when(
            loading: () => _buildContent(context, lesson, null),
            error: (_, __) => _buildContent(context, lesson, null),
            data: (stats) => _buildContent(context, lesson, stats),
          );
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context, dynamic lesson, dynamic stats) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _LessonHeader(lesson: lesson),
          const SizedBox(height: 24),
          Text(
            "Chọn cấp độ học",
            style: AppTypography.titleMedium,
          ),
          const SizedBox(height: 16),
          _LevelCard(
            level: 1,
            title: "Ghi nhớ",
            description: "Xem flashcard, nghe phát âm",
            icon: Icons.style_rounded,
            lessonId: widget.lessonId,
            isUnlocked: true,
            bestStars: stats?.getLevelBestStars(1) ?? 0,
          ),
          const SizedBox(height: 12),
          _LevelCard(
            level: 2,
            title: "Ghép từ",
            description: "Nhìn nghĩa, ghép chữ cái",
            icon: Icons.grid_view_rounded,
            lessonId: widget.lessonId,
            isUnlocked: true,
            bestStars: stats?.getLevelBestStars(2) ?? 0,
          ),
          const SizedBox(height: 12),
          _LevelCard(
            level: 3,
            title: "Chính tả",
            description: "Nghe và gõ từ chính xác",
            icon: Icons.keyboard_rounded,
            lessonId: widget.lessonId,
            isUnlocked: true,
            bestStars: stats?.getLevelBestStars(3) ?? 0,
          ),
          const SizedBox(height: 24),
          if (stats != null && stats.totalAttempts > 0) ...[
            Text(
              "Thống kê của bạn",
              style: AppTypography.titleMedium,
            ),
            const SizedBox(height: 16),
            _StatsCard(stats: stats),
          ],
        ],
      ),
    );
  }
}

class _LessonHeader extends StatelessWidget {
  final dynamic lesson;

  const _LessonHeader({required this.lesson});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: AppColors.brandGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.article_rounded,
                color: Colors.white,
                size: 32,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lesson.title,
                      style: AppTypography.titleLarge.copyWith(
                        color: Colors.white,
                      ),
                    ),
                    if (lesson.topicName != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        lesson.topicName!,
                        style: AppTypography.bodySmall.copyWith(
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (lesson.description != null && lesson.description!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              lesson.description!,
              style: AppTypography.bodyMedium.copyWith(
                color: Colors.white.withValues(alpha: 0.9),
              ),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              _HeaderChip(
                icon: Icons.text_fields_rounded,
                label: "${lesson.wordCount} từ",
              ),
              const SizedBox(width: 12),
              if (lesson.estimatedTime > 0)
                _HeaderChip(
                  icon: Icons.timer_outlined,
                  label: "${lesson.estimatedTime} phút",
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeaderChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _HeaderChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTypography.bodySmall.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _LevelCard extends StatelessWidget {
  final int level;
  final String title;
  final String description;
  final IconData icon;
  final String lessonId;
  final bool isUnlocked;
  final int bestStars;

  const _LevelCard({
    required this.level,
    required this.title,
    required this.description,
    required this.icon,
    required this.lessonId,
    required this.isUnlocked,
    required this.bestStars,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isUnlocked
          ? Theme.of(context).colorScheme.surface
          : Colors.grey[200],
      borderRadius: BorderRadius.circular(20),
      elevation: 0,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: isUnlocked ? () => _onLevelTap(context) : null,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isUnlocked
                  ? Theme.of(context).dividerColor
                  : Colors.grey[300]!,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: isUnlocked
                      ? _getLevelColor(level).withValues(alpha: 0.15)
                      : Colors.grey[300],
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  isUnlocked ? icon : Icons.lock_rounded,
                  color: isUnlocked ? _getLevelColor(level) : Colors.grey[500],
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: _getLevelColor(level).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            "Cấp $level",
                            style: AppTypography.bodySmall.copyWith(
                              color: _getLevelColor(level),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          title,
                          style: AppTypography.titleMedium.copyWith(
                            color: isUnlocked ? null : Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: AppTypography.bodySmall.copyWith(
                        color: isUnlocked
                            ? Theme.of(context).hintColor
                            : Colors.grey[500],
                      ),
                    ),
                    if (bestStars > 0) ...[
                      const SizedBox(height: 8),
                      _StarRating(stars: bestStars, size: 18),
                    ],
                  ],
                ),
              ),
              if (isUnlocked)
                Icon(
                  Icons.chevron_right_rounded,
                  color: _getLevelColor(level),
                ),
            ],
          ),
        ),
      ),
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

  void _onLevelTap(BuildContext context) {
    final route = _getRouteForLevel(level);
    context.push(route.replaceFirst(":lessonId", lessonId));
  }

  String _getRouteForLevel(int level) {
    switch (level) {
      case 1:
        return "/vocabulary/lessons/:lessonId/flashcard";
      case 2:
        return "/vocabulary/lessons/:lessonId/recall";
      case 3:
        return "/vocabulary/lessons/:lessonId/spelling";
      default:
        return "/vocabulary/lessons/:lessonId/flashcard";
    }
  }
}

class _StarRating extends StatelessWidget {
  final int stars;
  final double size;

  const _StarRating({required this.stars, this.size = 24});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        final isFilled = index < stars;
        return Icon(
          isFilled ? Icons.star_rounded : Icons.star_border_rounded,
          color: isFilled ? AppColors.xp : Colors.grey[400],
          size: size,
        );
      }),
    );
  }
}

class _StatsCard extends StatelessWidget {
  final dynamic stats;

  const _StatsCard({required this.stats});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatItem(
            value: "${stats.totalAttempts}",
            label: "Lượt học",
            icon: Icons.replay_rounded,
            color: AppColors.brandPrimary,
          ),
          _StatItem(
            value: "${stats.bestScore}%",
            label: "Điểm cao nhất",
            icon: Icons.emoji_events_rounded,
            color: AppColors.xp,
          ),
          _StatItem(
            value: "${stats.totalStars}/9",
            label: "Tổng sao",
            icon: Icons.star_rounded,
            color: AppColors.warning,
          ),
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
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: AppTypography.titleMedium.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
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
