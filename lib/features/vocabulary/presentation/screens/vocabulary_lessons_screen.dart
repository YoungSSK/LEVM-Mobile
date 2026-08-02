import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../models/vocabulary_models.dart';
import '../../providers/vocabulary_providers.dart';

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

class _LessonCard extends StatelessWidget {
  final VocabularyLessonModel lesson;

  const _LessonCard({required this.lesson});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(20),
      elevation: 0,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          context.push("/vocabulary/lessons/${lesson.id}");
        },
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Theme.of(context).dividerColor,
            ),
          ),
          child: Row(
            children: [
              _buildLessonIcon(lesson),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lesson.title,
                      style: AppTypography.titleMedium,
                    ),
                    if (lesson.description != null && lesson.description!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        lesson.description!,
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
                        _InfoChip(
                          icon: Icons.text_fields_rounded,
                          label: "${lesson.wordCount} từ",
                        ),
                        if (lesson.estimatedTime > 0) ...[
                          const SizedBox(width: 12),
                          _InfoChip(
                            icon: Icons.timer_outlined,
                            label: "${lesson.estimatedTime} phút",
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.brandPrimary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLessonIcon(VocabularyLessonModel lesson) {
    final rawThumbnail = lesson.thumbnail;
    final hasThumbnail = rawThumbnail != null && rawThumbnail.trim().isNotEmpty;

    final defaultIcon = Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: AppColors.brandPrimary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Icon(
        Icons.article_rounded,
        color: AppColors.brandPrimary,
        size: 28,
      ),
    );

    if (!hasThumbnail) return defaultIcon;

    final resolvedUrl = _resolveImageUrl(rawThumbnail);

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        width: 56,
        height: 56,
        child: Image.network(
          resolvedUrl,
          width: 56,
          height: 56,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => defaultIcon,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.brandPrimary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            );
          },
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
