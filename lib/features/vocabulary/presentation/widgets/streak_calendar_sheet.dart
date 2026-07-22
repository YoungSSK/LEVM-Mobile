import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../providers/xp_streak_provider.dart';

class StreakCalendarSheet extends ConsumerWidget {
  const StreakCalendarSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final xpStreakState = ref.watch(xpStreakProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(24),
            ),
          ),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: xpStreakState.streakInfo == null
                    ? const Center(child: CircularProgressIndicator())
                    : _buildCalendarContent(context, xpStreakState),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCalendarContent(BuildContext context, XpStreakState state) {
    final streakInfo = state.streakInfo!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            "Lịch học tập",
            style: AppTypography.titleLarge.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _StatColumn(
                value: "${streakInfo.currentStreak}",
                label: "Streak hiện tại",
                icon: Icons.local_fire_department_rounded,
                color: AppColors.streak,
              ),
              _StatColumn(
                value: "${streakInfo.longestStreak}",
                label: "Kỷ lục",
                icon: Icons.emoji_events_rounded,
                color: AppColors.xp,
              ),
              _StatColumn(
                value: "${streakInfo.freezeCount}",
                label: "Lượt freeze",
                icon: Icons.ac_unit_rounded,
                color: AppColors.info,
              ),
            ],
          ),
          const SizedBox(height: 32),
          if (streakInfo.studiedToday)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.success.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.check_circle_rounded,
                    color: AppColors.success,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "Hôm nay bạn đã học rồi!",
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.success,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.warning.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.warning_rounded,
                    color: AppColors.warning,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "Hôm nay bạn chưa học!",
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.warning,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 32),
          _buildWeekView(context),
          const SizedBox(height: 24),
          Text(
            "Mẹo: Học mỗi ngày để duy trì streak!",
            style: AppTypography.bodySmall.copyWith(
              color: Theme.of(context).hintColor,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildWeekView(BuildContext context) {
    final now = DateTime.now();
    final days = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
    final today = now.weekday;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Tuần này",
          style: AppTypography.titleMedium.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(7, (index) {
            final dayNumber = index + 1;
            final isToday = dayNumber == today;
            final isPast = dayNumber < today;

            return Column(
              children: [
                Text(
                  days[index],
                  style: AppTypography.bodySmall.copyWith(
                    color: Theme.of(context).hintColor,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isPast
                        ? AppColors.streak.withValues(alpha: 0.8)
                        : isToday
                            ? AppColors.streak
                            : Colors.grey[200],
                    border: isToday
                        ? Border.all(
                            color: AppColors.streak,
                            width: 3,
                          )
                        : null,
                  ),
                  child: Center(
                    child: isPast
                        ? const Icon(
                            Icons.check_rounded,
                            color: Colors.white,
                            size: 20,
                          )
                        : Text(
                            "$dayNumber",
                            style: AppTypography.bodySmall.copyWith(
                              color: isToday ? Colors.white : Colors.grey[600],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ],
            );
          }),
        ),
      ],
    );
  }
}

class _StatColumn extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color color;

  const _StatColumn({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 28),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: AppTypography.titleLarge.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: AppTypography.bodySmall.copyWith(
            color: Theme.of(context).hintColor,
          ),
        ),
      ],
    );
  }
}

void showStreakCalendar(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => const StreakCalendarSheet(),
  );
}
