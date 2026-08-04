import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../models/vocabulary_models.dart';
import '../../providers/vocabulary_providers.dart';

import '../../../../core/widgets/vip_access_guard.dart';
import '../../../membership/providers/membership_provider.dart';

class VocabularyLessonsScreen extends ConsumerWidget {
  final String topicId;

  const VocabularyLessonsScreen({
    super.key,
    required this.topicId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lessonsAsync = ref.watch(vocabularyLessonsProvider(topicId));

    return Scaffold(
      appBar: AppBar(
        title: const Text("Danh sách bài học"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: lessonsAsync.when(
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
                onPressed: () => ref.refresh(vocabularyLessonsProvider(topicId)),
                child: const Text("Thử lại"),
              ),
            ],
          ),
        ),
        data: (lessons) {
          if (lessons.isEmpty) {
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

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(vocabularyLessonsProvider(topicId));
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: lessons.length,
              itemBuilder: (context, index) {
                final lesson = lessons[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _LessonCard(lesson: lesson),
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
  final VocabularyLessonModel lesson;

  const _LessonCard({required this.lesson});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rawThumbnail = lesson.thumbnail;
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
              : Theme.of(context).dividerColor.withValues(alpha: 0.7),
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
            } else {
              context.push("/vocabulary/lessons/${lesson.id}");
            }
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Image Banner
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
                        Expanded(
                          child: Row(
                            children: [
                              Flexible(
                                child: Text(
                                  lesson.title,
                                  style: AppTypography.titleMedium.copyWith(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 17,
                                  ),
                                ),
                              ),
                              if (isVip) ...[
                                const SizedBox(width: 8),
                                VipLockBadge(packageName: requiredPackage, compact: true),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppColors.brandPrimary.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.arrow_forward_rounded,
                            size: 18,
                            color: AppColors.brandPrimary,
                          ),
                        ),
                      ],
                    ),
                    if (lesson.description != null && lesson.description!.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        lesson.description!,
                        style: AppTypography.bodyMedium.copyWith(
                          color: Theme.of(context).hintColor,
                          height: 1.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        _InfoChip(
                          icon: Icons.text_fields_rounded,
                          label: "${lesson.wordCount} từ vựng",
                        ),
                        if (lesson.estimatedTime > 0) ...[
                          const SizedBox(width: 10),
                          _InfoChip(
                            icon: Icons.timer_outlined,
                            label: "${lesson.estimatedTime} phút học",
                          ),
                        ],
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

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.grey[600]),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTypography.bodySmall.copyWith(
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
