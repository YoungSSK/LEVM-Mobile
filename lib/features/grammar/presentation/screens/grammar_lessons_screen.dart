import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../models/grammar_models.dart';
import '../../providers/grammar_providers.dart';
import '../widgets/grammar_star_rating.dart';

/// Màn hình danh sách bài học Grammar trong một chủ đề.
///
/// Pattern tham chiếu: VocabularyLessonsScreen
/// - Dùng /grammar-lessons/topic/:topicId/active endpoint.
/// - Mỗi card hiển thị: số thứ tự, tên bài, thời gian ước tính,
///   trạng thái hoàn thành (tick xanh) và số sao đạt được.
/// - Không có cơ chế khoá bài học tuần tự (tuỳ chọn).
class GrammarLessonsScreen extends ConsumerWidget {
  final String topicId;

  const GrammarLessonsScreen({
    super.key,
    required this.topicId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lessonsAsync = ref.watch(grammarLessonsProvider(topicId));

    return Scaffold(
      appBar: AppBar(
        title: const Text("Bài học ngữ pháp"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            }
          },
        ),
      ),
      body: lessonsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _ErrorWidget(
          error: error.toString(),
          onRetry: () => ref.refresh(grammarLessonsProvider(topicId)),
        ),
        data: (lessons) {
          if (lessons.isEmpty) {
            return const _EmptyWidget();
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(grammarLessonsProvider(topicId));
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: lessons.length,
              itemBuilder: (context, index) {
                final lesson = lessons[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _LessonCard(
                    lesson: lesson,
                    index: index,
                    onTap: () {
                      context.push("/grammar/lessons/${lesson.id}/theory");
                    },
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _LessonCard extends StatelessWidget {
  final GrammarLessonModel lesson;
  final int index;
  final VoidCallback onTap;

  const _LessonCard({
    required this.lesson,
    required this.index,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(20),
      elevation: 0,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: lesson.hasQuiz ? onTap : null,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: lesson.isCompleted
                  ? AppColors.success.withValues(alpha: 0.5)
                  : Theme.of(context).dividerColor,
            ),
          ),
          child: Row(
            children: [
              // Order number
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: lesson.isCompleted
                      ? AppColors.success.withValues(alpha: 0.1)
                      : AppColors.brandPrimary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: lesson.isCompleted
                      ? const Icon(
                          Icons.check_rounded,
                          color: AppColors.success,
                          size: 24,
                        )
                      : Text(
                          "${index + 1}",
                          style: AppTypography.titleMedium.copyWith(
                            color: AppColors.brandPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 16),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lesson.title,
                      style: AppTypography.titleMedium,
                    ),
                    if (lesson.shortDescription != null &&
                        lesson.shortDescription!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        lesson.shortDescription!,
                        style: AppTypography.bodySmall.copyWith(
                          color: Theme.of(context).hintColor,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        if (lesson.estimatedTime > 0) ...[
                          _InfoChip(
                            icon: Icons.timer_outlined,
                            label: "${lesson.estimatedTime} phút",
                          ),
                          const SizedBox(width: 8),
                        ],
                        _InfoChip(
                          icon: Icons.star_rounded,
                          label: "+${lesson.xpReward} XP",
                          color: AppColors.xp,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Stars and status
              Column(
                children: [
                  if (lesson.isCompleted) ...[
                    GrammarStarRating(
                      stars: lesson.stars,
                      size: 18,
                    ),
                    const SizedBox(height: 4),
                  ],
                  Icon(
                    Icons.chevron_right_rounded,
                    color: lesson.hasQuiz
                        ? AppColors.brandPrimary
                        : Colors.grey[400],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;

  const _InfoChip({
    required this.icon,
    required this.label,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final chipColor = color ?? Colors.grey[600]!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: chipColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: chipColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTypography.bodySmall.copyWith(
              color: chipColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorWidget extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const _ErrorWidget({
    required this.error,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: AppColors.danger),
          const SizedBox(height: 16),
          Text(
            "Lỗi: $error",
            textAlign: TextAlign.center,
            style: AppTypography.bodyMedium,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: onRetry,
            child: const Text("Thử lại"),
          ),
        ],
      ),
    );
  }
}

class _EmptyWidget extends StatelessWidget {
  const _EmptyWidget();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.article_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            "Chưa có bài học nào",
            style: AppTypography.titleMedium.copyWith(
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}
