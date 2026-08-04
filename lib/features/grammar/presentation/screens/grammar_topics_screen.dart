import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../providers/grammar_providers.dart';
import '../widgets/grammar_progress_bar.dart';

/// Màn hình danh sách chủ đề Grammar.
///
/// Pattern tham chiếu: VocabularyTopicsScreen
/// - Dùng /grammar-topics/progress endpoint để lấy tiến độ học của user.
/// - Mỗi card hiển thị: icon, tên, mô tả, progress bar (% bài đã hoàn thành).
class GrammarTopicsScreen extends ConsumerWidget {
  const GrammarTopicsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final topicsAsync = ref.watch(grammarTopicsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Chủ đề ngữ pháp"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: topicsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _ErrorWidget(
          error: error.toString(),
          onRetry: () => ref.refresh(grammarTopicsProvider),
        ),
        data: (topics) {
          if (topics.isEmpty) {
            return _EmptyWidget();
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(grammarTopicsProvider);
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: topics.length,
              itemBuilder: (context, index) {
                final topic = topics[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _TopicCard(
                    name: topic.name,
                    description: topic.description,
                    thumbnailUrl: topic.thumbnailUrl,
                    lessonCount: topic.lessonCount,
                    completedLessons: topic.completedLessons,
                    progress: topic.progressPercent,
                    onTap: () {
                      context.push(
                        AppRoutes.grammarLessons.replaceFirst(":topicId", topic.id),
                      );
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

class _TopicCard extends StatelessWidget {
  final String name;
  final String? description;
  final String? thumbnailUrl;
  final int lessonCount;
  final int completedLessons;
  final double progress;
  final VoidCallback onTap;

  const _TopicCard({
    required this.name,
    this.description,
    this.thumbnailUrl,
    required this.lessonCount,
    required this.completedLessons,
    required this.progress,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final rawThumbnail = thumbnailUrl;
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
          onTap: onTap,
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
                            name,
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
                    if (description != null && description!.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        description!,
                        style: AppTypography.bodyMedium.copyWith(
                          color: Theme.of(context).hintColor,
                          height: 1.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 14),
                    GrammarProgressBar(
                      progress: progress,
                      showLabel: true,
                      label: "$completedLessons / $lessonCount bài",
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
          Icons.menu_book_rounded,
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
  @override
  Widget build(BuildContext context) {
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
            "Chưa có chủ đề ngữ pháp nào",
            style: AppTypography.titleMedium.copyWith(
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}
