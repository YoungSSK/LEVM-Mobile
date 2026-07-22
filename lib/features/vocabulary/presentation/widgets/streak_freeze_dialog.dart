import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

class StreakFreezeDialog extends StatelessWidget {
  final int currentStreak;
  final int freezeCount;
  final VoidCallback onStudyNow;
  final VoidCallback onUseFreeze;
  final VoidCallback onDismiss;

  const StreakFreezeDialog({
    super.key,
    required this.currentStreak,
    required this.freezeCount,
    required this.onStudyNow,
    required this.onUseFreeze,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.streak.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.local_fire_department_rounded,
                color: AppColors.streak,
                size: 32,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              "Cảnh báo streak!",
              style: AppTypography.titleLarge.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Bạn sắp mất chuỗi $currentStreak ngày!",
              style: AppTypography.bodyMedium.copyWith(
                color: Theme.of(context).hintColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              "Học 1 bài ngay hoặc dùng lượt đóng băng streak.",
              style: AppTypography.bodySmall.copyWith(
                color: Theme.of(context).hintColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            if (freezeCount > 0)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.info.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.ac_unit_rounded,
                      color: AppColors.info,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "Bạn còn $freezeCount lượt đóng băng",
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.info,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onDismiss,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text("Để sau"),
                  ),
                ),
                if (freezeCount > 0) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onUseFreeze,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.info,
                        side: const BorderSide(color: AppColors.info),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text("Dùng freeze"),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onStudyNow,
                icon: const Icon(Icons.school_rounded),
                label: const Text("Học ngay"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.streak,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void showStreakFreezeDialog(
  BuildContext context, {
  required int currentStreak,
  required int freezeCount,
  required VoidCallback onStudyNow,
  required VoidCallback onUseFreeze,
}) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => StreakFreezeDialog(
      currentStreak: currentStreak,
      freezeCount: freezeCount,
      onStudyNow: () {
        Navigator.of(context).pop();
        onStudyNow();
      },
      onUseFreeze: () {
        Navigator.of(context).pop();
        onUseFreeze();
      },
      onDismiss: () => Navigator.of(context).pop(),
    ),
  );
}
