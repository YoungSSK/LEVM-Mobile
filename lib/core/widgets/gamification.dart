import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// Big "flame" streak counter. Slight pulsing animation if streak is alive.
class StreakBadge extends StatefulWidget {
  final int streak;

  const StreakBadge({super.key, required this.streak});

  @override
  State<StreakBadge> createState() => _StreakBadgeState();
}

class _StreakBadgeState extends State<StreakBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _scale = Tween(begin: 0.97, end: 1.03).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pulse = widget.streak > 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: AppColors.streakGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.streak.withValues(alpha: 0.35),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          ScaleTransition(
            scale: pulse ? _scale : const AlwaysStoppedAnimation(1),
            child: const Icon(
              Icons.local_fire_department,
              color: Colors.white,
              size: 30,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "${widget.streak}",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.displayMedium.copyWith(
                    color: Colors.white,
                    fontSize: 26,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.streak == 0
                      ? "Bắt đầu streak!"
                      : "ngày liên tiếp",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodySmall.copyWith(
                    color: Colors.white.withValues(alpha: 0.95),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Progress bar towards the next level.
/// Level rule (UI-only): every 100 XP = 1 level.
class XpProgressBar extends StatelessWidget {
  final int xp;
  final int xpPerLevel;

  const XpProgressBar({
    super.key,
    required this.xp,
    this.xpPerLevel = 100,
  });

  @override
  Widget build(BuildContext context) {
    final level = (xp ~/ xpPerLevel) + 1;
    final inLevel = xp % xpPerLevel;
    final progress = inLevel / xpPerLevel;
    final toNext = xpPerLevel - inLevel;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(context).dividerColor,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.xp.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star_rounded,
                          size: 16, color: AppColors.xp),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          "Cấp $level",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.labelMedium.copyWith(
                            color: AppColors.xp,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                "$xp XP",
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.titleMedium.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: progress.clamp(0.0, 1.0)),
            duration: const Duration(milliseconds: 700),
            curve: Curves.easeOut,
            builder: (_, value, _) => ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: value,
                minHeight: 12,
                backgroundColor: AppColors.xp.withValues(alpha: 0.12),
                valueColor: const AlwaysStoppedAnimation(AppColors.xp),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Còn $toNext XP nữa để lên cấp ${level + 1}",
            style: AppTypography.bodySmall.copyWith(
              color: Theme.of(context).hintColor,
            ),
          ),
        ],
      ),
    );
  }
}

/// Mini 7-day streak calendar (Mon-Sun) — fills days equal to `streak % 7`.
/// This is a pure visual cue; backend only stores total streak count.
class StreakCalendar extends StatelessWidget {
  final int streak;

  const StreakCalendar({super.key, required this.streak});

  @override
  Widget build(BuildContext context) {
    final filled = (streak % 7);
    final days = ["T2", "T3", "T4", "T5", "T6", "T7", "CN"];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(7, (i) {
        final active = i < filled;
        return Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: active
                    ? AppColors.streak
                    : Theme.of(context).colorScheme.surfaceContainerHighest,
              ),
              child: active
                  ? const Icon(Icons.local_fire_department,
                      color: Colors.white, size: 16)
                  : null,
            ),
            const SizedBox(height: 4),
            Text(
              days[i],
              style: AppTypography.bodySmall.copyWith(
                color: Theme.of(context).hintColor,
              ),
            ),
          ],
        );
      }),
    );
  }
}
