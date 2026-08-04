import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../models/vocabulary_models.dart';
import '../../providers/vocabulary_providers.dart';

class VocabularyTopicsScreen extends ConsumerWidget {
  const VocabularyTopicsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final topicsAsync = ref.watch(vocabularyTopicsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Chủ đề từ vựng"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: topicsAsync.when(
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
                onPressed: () => ref.refresh(vocabularyTopicsProvider),
                child: const Text("Thử lại"),
              ),
            ],
          ),
        ),
        data: (topics) {
          if (topics.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.library_books_outlined,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Chưa có chủ đề nào",
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
              ref.invalidate(vocabularyTopicsProvider);
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: topics.length,
              itemBuilder: (context, index) {
                final topic = topics[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _TopicCard(topic: topic),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _TopicCard extends StatelessWidget {
  final VocabularyTopicModel topic;

  const _TopicCard({required this.topic});

  @override
  Widget build(BuildContext context) {
    final rawThumbnail = topic.thumbnail;
    final hasThumbnail = rawThumbnail != null && rawThumbnail.trim().isNotEmpty;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.7),
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
            context.push(AppRoutes.vocabularyLessons.replaceFirst(":topicId", topic.id));
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Image Banner (Full Width)
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
                          child: Text(
                            topic.name,
                            style: AppTypography.titleMedium.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 17,
                            ),
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
                    if (topic.description != null && topic.description!.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        topic.description!,
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
                          icon: Icons.school_rounded,
                          label: "${topic.lessonCount} bài",
                        ),
                        const SizedBox(width: 10),
                        _InfoChip(
                          icon: Icons.text_fields_rounded,
                          label: "${topic.wordCount} từ",
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
          Icons.book_rounded,
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
        color: AppColors.brandPrimary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.brandPrimary),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.brandPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
