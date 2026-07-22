import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../models/grammar_models.dart';
import '../../providers/grammar_providers.dart';
import '../widgets/grammar_star_rating.dart';

/// Màn hình hiển thị lý thuyết Grammar (HTML content).
///
/// - AppBar có tên bài học + thời gian đọc ước tính.
/// - Nội dung htmlContent được render bằng flutter_html.
/// - Nút CTA "Bắt đầu trắc nghiệm" cố định ở đáy màn hình.
/// - Nếu đã hoàn thành, hiển thị số sao đã đạt được.
/// - Nếu không có quiz (hasQuiz = false), ẩn nút trắc nghiệm.
class GrammarTheoryScreen extends ConsumerWidget {
  final String lessonId;

  const GrammarTheoryScreen({
    super.key,
    required this.lessonId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lessonAsync = ref.watch(grammarLessonDetailProvider(lessonId));

    return lessonAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Scaffold(
        appBar: AppBar(
          title: const Text("Lý thuyết"),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
            if (context.canPop()) {
              context.pop();
            }
          },
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.danger),
              const SizedBox(height: 16),
              Text("Lỗi: $error"),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.refresh(grammarLessonDetailProvider(lessonId)),
                child: const Text("Thử lại"),
              ),
            ],
          ),
        ),
      ),
      data: (lesson) => _TheoryScreenContent(lesson: lesson),
    );
  }
}

class _TheoryScreenContent extends ConsumerStatefulWidget {
  final GrammarLessonModel lesson;

  const _TheoryScreenContent({required this.lesson});

  @override
  ConsumerState<_TheoryScreenContent> createState() => _TheoryScreenContentState();
}

class _TheoryScreenContentState extends ConsumerState<_TheoryScreenContent> {
  final ScrollController _scrollController = ScrollController();
  bool _hasScrolledToEnd = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_hasScrolledToEnd) return;

    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 50) {
      setState(() {
        _hasScrolledToEnd = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final lesson = widget.lesson;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PopScope(
      canPop: true,
      child: Scaffold(
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                lesson.title,
                style: AppTypography.titleMedium,
              ),
              if (lesson.estimatedTime > 0)
                Text(
                  "${lesson.estimatedTime} phút đọc",
                  style: AppTypography.bodySmall.copyWith(
                    color: Theme.of(context).hintColor,
                  ),
                ),
            ],
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
            if (context.canPop()) {
              context.pop();
            }
          },
          ),
          actions: [
            if (lesson.isCompleted)
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Center(
                  child: GrammarStarRating(
                    stars: lesson.stars,
                    size: 18,
                  ),
                ),
              ),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                child: _HtmlContent(
                  htmlContent: lesson.htmlContent ?? lesson.plainTextContent ?? "",
                  isDark: isDark,
                ),
              ),
            ),
            // Sticky CTA button
            if (lesson.hasQuiz)
              _QuizCtaButton(
                lesson: lesson,
                enabled: _hasScrolledToEnd,
                onPressed: () {
                  context.push("/grammar/lessons/${lesson.id}/quiz");
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _HtmlContent extends StatelessWidget {
  final String htmlContent;
  final bool isDark;

  const _HtmlContent({
    required this.htmlContent,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    if (htmlContent.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              Icon(
                Icons.article_outlined,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                "Chưa có nội dung lý thuyết",
                style: AppTypography.bodyMedium.copyWith(
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Html(
      data: htmlContent,
      style: {
        "body": Style(
          margin: Margins.zero,
          padding: HtmlPaddings.zero,
          fontSize: FontSize(16),
          lineHeight: const LineHeight(1.6),
          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
        ),
        "h1": Style(
          fontSize: FontSize(24),
          fontWeight: FontWeight.bold,
          margin: Margins.only(top: 16, bottom: 8),
          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
        ),
        "h2": Style(
          fontSize: FontSize(20),
          fontWeight: FontWeight.bold,
          margin: Margins.only(top: 14, bottom: 6),
          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
        ),
        "h3": Style(
          fontSize: FontSize(18),
          fontWeight: FontWeight.w600,
          margin: Margins.only(top: 12, bottom: 4),
          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
        ),
        "p": Style(
          margin: Margins.only(bottom: 12),
        ),
        "ul": Style(
          margin: Margins.only(left: 16, bottom: 12),
        ),
        "ol": Style(
          margin: Margins.only(left: 16, bottom: 12),
        ),
        "li": Style(
          margin: Margins.only(bottom: 4),
        ),
        "blockquote": Style(
          margin: Margins.only(left: 16, top: 8, bottom: 8),
          padding: HtmlPaddings.only(left: 12),
          border: Border(
            left: BorderSide(
              color: AppColors.brandPrimary,
              width: 3,
            ),
          ),
          fontStyle: FontStyle.italic,
          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
        ),
        "code": Style(
          backgroundColor: isDark
              ? AppColors.darkSurfaceAlt
              : AppColors.lightSurfaceAlt,
          padding: HtmlPaddings.symmetric(horizontal: 4, vertical: 2),
          fontFamily: "monospace",
          fontSize: FontSize(14),
        ),
        "pre": Style(
          backgroundColor: isDark
              ? AppColors.darkSurfaceAlt
              : AppColors.lightSurfaceAlt,
          padding: HtmlPaddings.all(12),
          margin: Margins.only(bottom: 12),
        ),
        "table": Style(
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
        "th": Style(
          backgroundColor: isDark
              ? AppColors.darkSurfaceAlt
              : AppColors.lightSurfaceAlt,
          fontWeight: FontWeight.bold,
          padding: HtmlPaddings.all(8),
        ),
        "td": Style(
          padding: HtmlPaddings.all(8),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
        "strong": Style(
          fontWeight: FontWeight.bold,
        ),
        "em": Style(
          fontStyle: FontStyle.italic,
        ),
        "a": Style(
          color: AppColors.brandPrimary,
          textDecoration: TextDecoration.underline,
        ),
      },
    );
  }
}

class _QuizCtaButton extends StatelessWidget {
  final GrammarLessonModel lesson;
  final bool enabled;
  final VoidCallback onPressed;

  const _QuizCtaButton({
    required this.lesson,
    required this.enabled,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).dividerColor,
          ),
        ),
      ),
      child: SafeArea(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: enabled
                  ? AppColors.brandGradient
                  : [Colors.grey[400]!, Colors.grey[500]!],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: enabled
                ? [
                    BoxShadow(
                      color: AppColors.brandPrimary.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: ElevatedButton(
            onPressed: onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.quiz_rounded, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  lesson.isCompleted ? "Làm lại bài trắc nghiệm" : "Bắt đầu trắc nghiệm",
                  style: AppTypography.titleMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
