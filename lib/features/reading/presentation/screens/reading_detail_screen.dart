import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../vocabulary/providers/xp_streak_provider.dart';
import '../../data/api/reading_api_service.dart';
import '../../domain/models/reading_attempt.dart';
import '../../domain/models/reading_passage.dart';
import '../../domain/models/reading_question.dart';
import '../widgets/cefr_level_badge.dart';

class ReadingDetailScreen extends ConsumerStatefulWidget {
  final String passageId;

  const ReadingDetailScreen({super.key, required this.passageId});

  @override
  ConsumerState<ReadingDetailScreen> createState() => _ReadingDetailScreenState();
}

class _ReadingDetailScreenState extends ConsumerState<ReadingDetailScreen> {
  final _api = ReadingApiService();
  ReadingPassage? _passage;
  List<ReadingQuestion> _questions = [];
  bool _loading = true;
  bool _submitting = false;
  bool _isBookmarked = false;
  double _fontSize = 16.0;

  /// questionId → selected option key (e.g. "A")
  final Map<String, String> _answers = {};

  /// Timer
  final Stopwatch _stopwatch = Stopwatch();

  bool _isValidUrl(String? url) {
    if (url == null || url.trim().isEmpty) return false;
    final t = url.trim().toLowerCase();
    return t.startsWith('http://') || t.startsWith('https://');
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final passage = await _api.getPassageDetail(widget.passageId);
      final questions = await _api.getPassageQuestions(widget.passageId);
      if (mounted) {
        setState(() {
          _passage = passage;
          _questions = questions;
          _loading = false;
        });
        _stopwatch.start();
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _toPlainText(String html, String fallback) {
    final source = html.isNotEmpty ? html : fallback;
    return source
        .replaceAll(RegExp(r'<br\s*/?>'), '\n')
        .replaceAll(RegExp(r'</p>'), '\n\n')
        .replaceAll(RegExp(r'</h[1-6]>'), '\n\n')
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll(RegExp(r'\n{3,}'), '\n\n')
        .trim();
  }

  bool get _allAnswered =>
      _questions.isNotEmpty && _answers.length == _questions.length;

  Future<void> _submit() async {
    if (!_allAnswered || _submitting) return;
    setState(() => _submitting = true);
    _stopwatch.stop();

    ReadingAttempt? attempt;
    try {
      attempt = await _api.submitAttempt(
        passageId: widget.passageId,
        userAnswers: _answers,
        duration: _stopwatch.elapsed.inSeconds,
      );
    } catch (_) {
      // fallback: build local attempt result
      int correct = 0;
      for (final q in _questions) {
        if (_answers[q.id] == q.correctAnswer) correct++;
      }
      final total = _questions.length;
      final score = total > 0 ? (correct / total * 100).round() : 0;
      attempt = ReadingAttempt(
        id: 'local_${widget.passageId}',
        userId: '',
        passageId: widget.passageId,
        totalQuestions: total,
        correctAnswers: correct,
        wrongAnswers: total - correct,
        score: score,
        isPassed: score >= 70,
        xpEarned: score >= 70 ? (_passage?.xpReward ?? 15) : 0,
        duration: _stopwatch.elapsed.inSeconds,
      );
    }

    if (mounted) {
      ref.read(xpStreakProvider.notifier).loadXpAndStreak();
      context.pushReplacement(
        '/reading/result/${attempt.id}',
        extra: attempt,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: const Text("Đọc hiểu"),
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/reading/library');
            }
          },
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
              color: _isBookmarked ? AppColors.brandPrimary : null,
            ),
            onPressed: () {
              setState(() => _isBookmarked = !_isBookmarked);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(_isBookmarked ? 'Đã lưu bài đọc!' : 'Đã bỏ lưu bài đọc.'),
                duration: const Duration(seconds: 1),
              ));
            },
          ),
          IconButton(
            icon: const Icon(Icons.text_fields_rounded),
            onPressed: () {
              showDialog(
                context: context,
                builder: (dialogContext) => AlertDialog(
                  title: const Text("Cỡ chữ"),
                  content: StatefulBuilder(
                    builder: (ctx, setLocal) => Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text("${_fontSize.toInt()}sp",
                            style: AppTypography.titleMedium),
                        Slider(
                          value: _fontSize,
                          min: 13,
                          max: 24,
                          divisions: 11,
                          onChanged: (v) {
                            setLocal(() {});
                            setState(() => _fontSize = v);
                          },
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      child: const Text("Đóng"),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _passage == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: AppColors.danger),
                      const SizedBox(height: 12),
                      const Text("Không thể tải bài đọc"),
                      const SizedBox(height: 12),
                      ElevatedButton(onPressed: _load, child: const Text("Thử lại")),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Cover Image ─────────────────────────────────
                      if (_isValidUrl(_passage!.thumbnail))
                        ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: SizedBox(
                            width: double.infinity,
                            height: 180,
                            child: Image.network(
                              _passage!.thumbnail,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => const SizedBox.shrink(),
                            ),
                          ),
                        ),
                      if (_isValidUrl(_passage!.thumbnail)) const SizedBox(height: 16),

                      // ── Meta Row ────────────────────────────────────
                      Row(children: [
                        CefrLevelBadge(level: _passage!.cefrLevel),
                        const SizedBox(width: 10),
                        Text("⏱ ${_passage!.estimatedTime} phút",
                            style: AppTypography.bodySmall.copyWith(
                              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                            )),
                        const SizedBox(width: 10),
                        Text("📝 ${_passage!.wordCount} từ",
                            style: AppTypography.bodySmall.copyWith(
                              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                            )),
                        const Spacer(),
                        Text("+${_passage!.xpReward} XP",
                            style: AppTypography.labelMedium.copyWith(
                              color: AppColors.xp, fontWeight: FontWeight.bold,
                            )),
                      ]),
                      const SizedBox(height: 12),

                      // ── Title ───────────────────────────────────────
                      Text(_passage!.title,
                          style: AppTypography.headlineSmall.copyWith(
                            fontWeight: FontWeight.bold, height: 1.25)),
                      if (_passage!.description.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(_passage!.description,
                            style: AppTypography.bodyMedium.copyWith(
                              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                              fontStyle: FontStyle.italic, height: 1.4,
                            )),
                      ],
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 16),

                      // ── Reading Passage Content ─────────────────────
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: SelectableText(
                          _toPlainText(_passage!.htmlContent, _passage!.plainText),
                          style: TextStyle(
                            fontSize: _fontSize,
                            height: 1.75,
                            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                          ),
                        ),
                      ),

                      // ── Quiz Section ────────────────────────────────
                      if (_questions.isNotEmpty) ...[
                        const SizedBox(height: 28),
                        Row(children: [
                          Container(
                            width: 4, height: 24,
                            decoration: BoxDecoration(
                              color: AppColors.brandPrimary,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text("Câu hỏi kiểm tra",
                              style: AppTypography.titleLarge.copyWith(
                                fontWeight: FontWeight.bold,
                              )),
                          const Spacer(),
                          Text(
                            "${_answers.length}/${_questions.length} câu",
                            style: AppTypography.labelMedium.copyWith(
                              color: _allAnswered ? AppColors.success : AppColors.darkTextSecondary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ]),
                        const SizedBox(height: 16),

                        // Progress bar
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: _questions.isEmpty
                                ? 0
                                : _answers.length / _questions.length,
                            backgroundColor: isDark
                                ? AppColors.darkSurface
                                : AppColors.lightSurface,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                                AppColors.brandPrimary),
                            minHeight: 6,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Questions
                        ..._questions.asMap().entries.map((entry) {
                          final idx = entry.key;
                          final q = entry.value;
                          final selected = _answers[q.id];

                          return Container(
                            key: ValueKey('q_${q.id}'),
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: selected != null
                                    ? AppColors.brandPrimary.withValues(alpha: 0.4)
                                    : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Question header
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: 28, height: 28,
                                      decoration: BoxDecoration(
                                        color: selected != null
                                            ? AppColors.brandPrimary
                                            : AppColors.brandPrimary.withValues(alpha: 0.12),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Center(
                                        child: Text(
                                          "${idx + 1}",
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            color: selected != null
                                                ? Colors.white
                                                : AppColors.brandPrimary,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(q.questionText,
                                          style: AppTypography.bodyMedium.copyWith(
                                            fontWeight: FontWeight.w600,
                                            height: 1.45,
                                          )),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 14),

                                // Options
                                ...q.options.map((opt) {
                                  final isSelected = selected == opt.key;
                                  return GestureDetector(
                                    onTap: () {
                                      setState(() => _answers[q.id] = opt.key);
                                    },
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 180),
                                      margin: const EdgeInsets.only(bottom: 8),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 14, vertical: 12),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? AppColors.brandPrimary.withValues(alpha: 0.1)
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: isSelected
                                              ? AppColors.brandPrimary
                                              : (isDark
                                                  ? AppColors.darkBorder
                                                  : AppColors.lightBorder),
                                          width: isSelected ? 2 : 1,
                                        ),
                                      ),
                                      child: Row(children: [
                                        Container(
                                          width: 26, height: 26,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: isSelected
                                                ? AppColors.brandPrimary
                                                : Colors.transparent,
                                            border: Border.all(
                                              color: isSelected
                                                  ? AppColors.brandPrimary
                                                  : (isDark
                                                      ? AppColors.darkBorder
                                                      : AppColors.lightBorder),
                                            ),
                                          ),
                                          child: Center(
                                            child: Text(
                                              opt.key,
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                color: isSelected
                                                    ? Colors.white
                                                    : (isDark
                                                        ? AppColors.darkTextSecondary
                                                        : AppColors.lightTextSecondary),
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(opt.text,
                                              style: AppTypography.bodyMedium.copyWith(
                                                color: isSelected
                                                    ? AppColors.brandPrimary
                                                    : null,
                                                fontWeight: isSelected
                                                    ? FontWeight.w600
                                                    : FontWeight.normal,
                                              )),
                                        ),
                                        if (isSelected)
                                          const Icon(Icons.check_circle_rounded,
                                              size: 18,
                                              color: AppColors.brandPrimary),
                                      ]),
                                    ),
                                  );
                                }),
                              ],
                            ),
                          );
                        }),

                        // ── Submit Button ─────────────────────────────
                        const SizedBox(height: 8),
                        AnimatedOpacity(
                          opacity: _allAnswered ? 1.0 : 0.35,
                          duration: const Duration(milliseconds: 300),
                          child: SizedBox(
                            width: double.infinity,
                            height: 54,
                            child: ElevatedButton.icon(
                              onPressed: _allAnswered ? _submit : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.brandPrimary,
                                foregroundColor: Colors.white,
                                disabledBackgroundColor:
                                    AppColors.brandPrimary.withValues(alpha: 0.5),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 0,
                              ),
                              icon: _submitting
                                  ? const SizedBox(
                                      width: 18, height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2, color: Colors.white))
                                  : const Icon(Icons.send_rounded),
                              label: Text(
                                _submitting ? "Đang nộp bài..." : "Nộp bài",
                                style: AppTypography.titleMedium.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                        if (!_allAnswered)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Center(
                              child: Text(
                                "Trả lời tất cả ${_questions.length} câu hỏi để nộp bài",
                                style: AppTypography.bodySmall.copyWith(
                                  color: isDark
                                      ? AppColors.darkTextSecondary
                                      : AppColors.lightTextSecondary,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ],
                  ),
                ),
    );
  }
}
