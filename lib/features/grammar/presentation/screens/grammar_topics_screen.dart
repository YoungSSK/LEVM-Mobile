import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
        title: const Text("Ngữ pháp"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            }
          },
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
  final int lessonCount;
  final int completedLessons;
  final double progress;
  final VoidCallback onTap;

  const _TopicCard({
    required this.name,
    this.description,
    required this.lessonCount,
    required this.completedLessons,
    required this.progress,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isCompleted = completedLessons >= lessonCount && lessonCount > 0;

    return Material(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(20),
      elevation: 0,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
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
              // Topic icon
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: AppColors.brandGradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  isCompleted ? Icons.check_circle_rounded : Icons.book_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: AppTypography.titleMedium,
                    ),
                    if (description != null && description!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        description!,
                        style: AppTypography.bodySmall.copyWith(
                          color: Theme.of(context).hintColor,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 12),
                    // Progress
                    GrammarProgressBar(
                      progress: progress,
                      showLabel: true,
                      label: "$completedLessons / $lessonCount bài",
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Icon(
                Icons.chevron_right_rounded,
                color: AppColors.brandPrimary,
              ),
            ],
          ),
        ),
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
