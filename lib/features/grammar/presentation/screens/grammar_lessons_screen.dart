import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/vip_access_guard.dart';
import '../../../membership/providers/membership_provider.dart';
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
            } else {
              context.go('/grammar');
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

class _LessonCard extends ConsumerWidget {
  final GrammarLessonModel lesson;
  final int index;
  final VoidCallback onTap;

  const _LessonCard({
    required this.lesson,
    required this.index,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rawThumbnail = lesson.thumbnailUrl;
    final hasThumbnail = rawThumbnail != null && rawThumbnail.trim().isNotEmpty;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final membershipState = ref.watch(membershipNotifierProvider);
    final subscription = membershipState.currentSubscription;

    final isVip = VipAccessHelper.isVipLesson(lesson.allowedPackageIds);
    final hasAccess = VipAccessHelper.hasAccess(
      subscription: subscription,
      allowedPackageIds: lesson.allowedPackageIds,
    );
    final isLocked = isVip && !hasAccess;
    final requiredPackage = VipAccessHelper.getRequiredPackageName(lesson.allowedPackageIds);

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isLocked
              ? Colors.amber.withValues(alpha: 0.6)
              : (lesson.isCompleted
                  ? AppColors.success.withValues(alpha: 0.5)
                  : Theme.of(context).dividerColor.withValues(alpha: 0.7)),
          width: isLocked ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            if (isLocked) {
              VipAccessHelper.showVipLockedToast(
                context,
                requiredPackageName: requiredPackage,
              );
            } else if (lesson.hasQuiz) {
              onTap();
            }
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Banner Image
              if (hasThumbnail)
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Image.network(
                      _resolveImageUrl(rawThumbnail),
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => _buildDefaultBanner(),
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          color: AppColors.brandPrimary.withValues(alpha: 0.08),
                          child: const Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        );
                      },
                    ),
                  ),
                )
              else
                _buildDefaultBanner(),

              // Card Content Below
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Order number / Check / Lock Icon
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: isLocked
                                ? Colors.amber.withValues(alpha: 0.15)
                                : (lesson.isCompleted
                                    ? AppColors.success.withValues(alpha: 0.1)
                                    : AppColors.brandPrimary.withValues(alpha: 0.1)),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(
                            child: isLocked
                                ? const Icon(
                                    Icons.lock_rounded,
                                    color: Colors.amber,
                                    size: 18,
                                  )
                                : (lesson.isCompleted
                                    ? const Icon(
                                        Icons.check_rounded,
                                        color: AppColors.success,
                                        size: 20,
                                      )
                                    : Text(
                                        "${index + 1}",
                                        style: AppTypography.titleMedium.copyWith(
                                          color: AppColors.brandPrimary,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                        ),
                                      )),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Title & Description
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      lesson.title,
                                      style: AppTypography.titleMedium.copyWith(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                  if (isVip) ...[
                                    const SizedBox(width: 8),
                                    VipLockBadge(packageName: requiredPackage, compact: true),
                                  ],
                                ],
                              ),
                              if (lesson.shortDescription != null &&
                                  lesson.shortDescription!.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  lesson.shortDescription!,
                                  style: AppTypography.bodyMedium.copyWith(
                                    color: Theme.of(context).hintColor,
                                    height: 1.4,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Stars and Arrow Icon
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            if (lesson.isCompleted) ...[
                              GrammarStarRating(
                                stars: lesson.stars,
                                size: 16,
                              ),
                              const SizedBox(height: 4),
                            ],
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: AppColors.brandPrimary.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.arrow_forward_rounded,
                                size: 16,
                                color: lesson.hasQuiz
                                    ? AppColors.brandPrimary
                                    : Colors.grey[400],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDefaultBanner() {
    return Container(
      height: 140,
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: AppColors.brandGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: const Center(
        child: Icon(
          Icons.article_rounded,
          color: Colors.white,
          size: 48,
        ),
      ),
    );
  }

  static String _resolveImageUrl(String rawUrl) {
    String url = rawUrl.trim();
    if (url.isEmpty) return '';

    final apiBase = AppConfig.baseUrl;
    if (apiBase.contains('10.0.2.2')) {
      url = url.replaceAll('localhost', '10.0.2.2').replaceAll('127.0.0.1', '10.0.2.2');
    }

    if (url.startsWith('http://') || url.startsWith('https://')) {
      return url;
    }

    final origin = apiBase.endsWith('/api')
        ? apiBase.substring(0, apiBase.length - 4)
        : apiBase;

    if (url.startsWith('/')) {
      return '$origin$url';
    }
    return '$origin/$url';
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
