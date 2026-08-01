import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/models/reading_attempt.dart';

class ReadingResultScreen extends StatelessWidget {
  final String attemptId;

  const ReadingResultScreen({super.key, required this.attemptId});

  String _formatDuration(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return "${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}";
  }


  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final extra = GoRouterState.of(context).extra;
    final ReadingAttempt? attempt = extra is ReadingAttempt ? extra : null;

    final score = attempt?.score ?? 80;
    final correct = attempt?.correctAnswers ?? 0;
    final total = attempt?.totalQuestions ?? 0;
    final xp = attempt?.xpEarned ?? 15;
    final duration = attempt?.duration ?? 0;
    final isPassed = attempt?.isPassed ?? (score >= 70);


    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: const Text("Kết quả bài đọc"),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.close_rounded),
            onPressed: () => context.go('/reading/library'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 12),

            // ── Trophy / Result Icon ────────────────────────────────
            Container(
              width: 100, height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: (isPassed ? AppColors.brandPrimary : AppColors.danger)
                    .withValues(alpha: 0.12),
              ),
              child: Center(
                child: Icon(
                  isPassed
                      ? Icons.emoji_events_rounded
                      : Icons.sentiment_dissatisfied_rounded,
                  size: 56,
                  color: isPassed ? AppColors.brandPrimary : AppColors.danger,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // ── Headline ────────────────────────────────────────────
            Text(
              isPassed ? "Xuất sắc! Bạn đã vượt qua bài đọc! 🎉" : "Chưa đạt — Hãy thử lại!",
              textAlign: TextAlign.center,
              style: AppTypography.headlineSmall.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              isPassed
                  ? "Bạn đã hoàn thành xuất sắc bài kiểm tra đọc hiểu."
                  : "Đọc lại bài và làm câu hỏi để đạt điểm qua.",
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium.copyWith(
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              ),
            ),
            const SizedBox(height: 28),

            // ── Score Circle ────────────────────────────────────────
            Container(
              width: 120, height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isPassed ? AppColors.brandPrimary : AppColors.danger,
                  width: 6,
                ),
              ),
              child: Center(
                child: Text(
                  "$score%",
                  style: AppTypography.headlineLarge.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isPassed ? AppColors.brandPrimary : AppColors.danger,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // ── XP & Streak Row ─────────────────────────────────────
            Row(children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                  decoration: BoxDecoration(
                    color: AppColors.xp.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.xp.withValues(alpha: 0.3)),
                  ),
                  child: Column(children: [
                    const Icon(Icons.bolt_rounded, color: AppColors.xp, size: 32),
                    const SizedBox(height: 6),
                    Text("+$xp XP",
                        style: AppTypography.titleLarge.copyWith(
                          fontWeight: FontWeight.bold, color: AppColors.xp)),
                    const SizedBox(height: 2),
                    Text("Phần thưởng XP",
                        style: AppTypography.labelMedium.copyWith(
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)),
                  ]),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                  decoration: BoxDecoration(
                    color: AppColors.streak.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.streak.withValues(alpha: 0.3)),
                  ),
                  child: Column(children: [
                    const Icon(Icons.local_fire_department_rounded,
                        color: AppColors.streak, size: 32),
                    const SizedBox(height: 6),
                    Text("🔥 Streak",
                        style: AppTypography.titleLarge.copyWith(
                          fontWeight: FontWeight.bold, color: AppColors.streak)),
                    const SizedBox(height: 2),
                    Text("Duy trì liên tiếp",
                        style: AppTypography.labelMedium.copyWith(
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)),
                  ]),
                ),
              ),
            ]),
            const SizedBox(height: 20),

            // ── Score Detail Card ───────────────────────────────────
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
              ),
              child: Column(children: [
                _detailRow(isDark, "Điểm số đạt được", "$score%",
                    valueColor: isPassed ? AppColors.success : AppColors.danger),
                const Divider(height: 24),
                if (total > 0) ...[
                  _detailRow(isDark, "Số câu đúng", "$correct / $total câu"),
                  const SizedBox(height: 12),
                ],
                _detailRow(isDark, "Thời gian làm bài",
                    duration > 0 ? "${_formatDuration(duration)} phút" : "--"),
              ]),
            ),
            const SizedBox(height: 32),

            // ── CTA Buttons ─────────────────────────────────────────
            SizedBox(
              width: double.infinity, height: 52,
              child: ElevatedButton(
                onPressed: () => context.go('/reading/library'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.brandPrimary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: Text("Bài đọc tiếp theo",
                    style: AppTypography.titleMedium.copyWith(
                      fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity, height: 52,
              child: OutlinedButton(
                onPressed: () => context.pop(),
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  side: const BorderSide(color: AppColors.brandPrimary),
                ),
                child: Text("Xem lại bài đọc",
                    style: AppTypography.titleMedium.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.brandPrimary)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(bool isDark, String label, String value, {Color? valueColor}) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label,
          style: AppTypography.bodyMedium.copyWith(
            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
          )),
      Text(value,
          style: AppTypography.titleMedium.copyWith(
            fontWeight: FontWeight.bold,
            color: valueColor,
          )),
    ]);
  }
}
