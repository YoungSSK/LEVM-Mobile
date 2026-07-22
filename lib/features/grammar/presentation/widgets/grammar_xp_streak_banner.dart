import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

/// Banner hiển thị XP và Streak mới nhận được sau khi hoàn thành quiz.
///
/// Pattern tái sử dụng từ level_up_dialog.dart và streak_freeze_dialog.dart.
/// Chỉ hiển thị khi:
/// - isFirstCompletionToday = true (streak mới)
/// - xpEarned > 0 (XP mới)
class GrammarXpStreakBanner extends StatelessWidget {
  final int xpEarned;
  final int? newStreak;
  final bool showStreakAnimation;
  final VoidCallback? onDismiss;

  const GrammarXpStreakBanner({
    super.key,
    required this.xpEarned,
    this.newStreak,
    this.showStreakAnimation = true,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: AppColors.brandGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.brandPrimary.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // XP badge
          _XpBadge(xpEarned: xpEarned),

          if (newStreak != null) ...[
            const SizedBox(width: 16),
            Container(
              width: 1,
              height: 40,
              color: Colors.white.withValues(alpha: 0.3),
            ),
            const SizedBox(width: 16),
            // Streak badge
            _StreakBadge(
              streak: newStreak!,
              animate: showStreakAnimation,
            ),
          ],

          if (onDismiss != null) ...[
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white70),
              onPressed: onDismiss,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: -0.2, end: 0);
  }
}

class _XpBadge extends StatelessWidget {
  final int xpEarned;

  const _XpBadge({required this.xpEarned});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.auto_awesome,
            color: AppColors.xp,
            size: 20,
          ),
          const SizedBox(width: 6),
          Text(
            "+$xpEarned XP",
            style: AppTypography.titleMedium.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    ).animate(onPlay: (controller) => controller.repeat(reverse: true))
        .scale(
          begin: const Offset(1, 1),
          end: const Offset(1.05, 1.05),
          duration: 1000.ms,
        );
  }
}

class _StreakBadge extends StatelessWidget {
  final int streak;
  final bool animate;

  const _StreakBadge({
    required this.streak,
    this.animate = true,
  });

  @override
  Widget build(BuildContext context) {
    Widget badge = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.local_fire_department_rounded,
            color: AppColors.streak,
            size: 20,
          ),
          const SizedBox(width: 6),
          Text(
            "$streak",
            style: AppTypography.titleMedium.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );

    if (animate) {
      badge = badge
          .animate(onPlay: (controller) => controller.repeat(reverse: true))
          .scale(
            begin: const Offset(1, 1),
            end: const Offset(1.1, 1.1),
            duration: 800.ms,
          );
    }

    return badge;
  }
}

/// Dialog hiển thị thông tin XP/Streak sau khi hoàn thành bài.
/// Dùng cho trường hợp cần hiển thị chi tiết hơn banner.
class GrammarXpStreakDialog extends StatelessWidget {
  final int xpEarned;
  final int? newStreak;
  final int? longestStreak;
  final int newLevel;
  final bool leveledUp;
  final VoidCallback onDismiss;

  const GrammarXpStreakDialog({
    super.key,
    required this.xpEarned,
    this.newStreak,
    this.longestStreak,
    this.newLevel = 1,
    this.leveledUp = false,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: AppColors.brandGradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: AppColors.brandPrimary.withValues(alpha: 0.5),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Trophy icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.emoji_events_rounded,
                color: AppColors.xp,
                size: 40,
              ),
            ).animate().scale(
                  begin: const Offset(0, 0),
                  end: const Offset(1, 1),
                  duration: 600.ms,
                  curve: Curves.elasticOut,
                ),
            const SizedBox(height: 16),
            Text(
              leveledUp ? "Bạn đã lên cấp!" : "Hoàn thành xuất sắc!",
              style: AppTypography.titleLarge.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ).animate().fadeIn(delay: 300.ms),
            if (leveledUp) ...[
              const SizedBox(height: 8),
              Text(
                "Cấp $newLevel",
                style: AppTypography.headlineMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ).animate().fadeIn(delay: 400.ms),
            ],
            const SizedBox(height: 24),
            // Stats row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                if (xpEarned > 0)
                  _StatItem(
                    icon: Icons.auto_awesome,
                    iconColor: AppColors.xp,
                    value: "+$xpEarned",
                    label: "XP",
                    animate: true,
                  ),
                if (newStreak != null)
                  _StatItem(
                    icon: Icons.local_fire_department_rounded,
                    iconColor: AppColors.streak,
                    value: "$newStreak",
                    label: "Streak",
                    animate: true,
                  ),
              ],
            ).animate().fadeIn(delay: 500.ms),
            if (longestStreak != null && newStreak != null && newStreak! > longestStreak!) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  "Kỷ lục streak mới!",
                  style: AppTypography.bodySmall.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ).animate().fadeIn(delay: 700.ms).scale(
                    begin: const Offset(0.8, 0.8),
                    end: const Offset(1, 1),
                  ),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onDismiss,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.brandPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  "Tiếp tục",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ).animate().fadeIn(delay: 800.ms),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;
  final bool animate;

  const _StatItem({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
    this.animate = false,
  });

  @override
  Widget build(BuildContext context) {
    Widget item = Column(
      children: [
        Icon(icon, color: iconColor, size: 32),
        const SizedBox(height: 8),
        Text(
          value,
          style: AppTypography.titleLarge.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: AppTypography.bodySmall.copyWith(
            color: Colors.white70,
          ),
        ),
      ],
    );

    if (animate) {
      item = item
          .animate(onPlay: (controller) => controller.repeat(reverse: true))
          .scale(
            begin: const Offset(1, 1),
            end: const Offset(1.1, 1.1),
            duration: 1000.ms,
          );
    }

    return item;
  }
}

void showGrammarXpStreakDialog(
  BuildContext context, {
  required int xpEarned,
  int? newStreak,
  int? longestStreak,
  int newLevel = 1,
  bool leveledUp = false,
}) {
  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierColor: Colors.black54,
    pageBuilder: (context, animation, secondaryAnimation) {
      return GrammarXpStreakDialog(
        xpEarned: xpEarned,
        newStreak: newStreak,
        longestStreak: longestStreak,
        newLevel: newLevel,
        leveledUp: leveledUp,
        onDismiss: () => Navigator.of(context).pop(),
      );
    },
  );
}
