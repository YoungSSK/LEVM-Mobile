import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// Placeholder badge grid — purely visual; no API yet.
/// TODO(backend): hook up to /achievements or /badges endpoint when ready.
class BadgeStrip extends StatelessWidget {
  final int totalEarned;

  const BadgeStrip({super.key, this.totalEarned = 3});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.emoji_events, color: AppColors.brandSecondary),
              const SizedBox(width: 8),
              Text(
                "Thành tích",
                style: AppTypography.headlineMedium.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const Spacer(),
              // Mock upcoming-data hint.
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.brandPrimary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  "$totalEarned/8",
                  style: AppTypography.labelMedium.copyWith(
                    color: AppColors.brandPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(8, (i) {
              final earned = i < totalEarned;
              return Tooltip(
                message: earned ? "Huy hiệu mở khoá" : "Chưa mở khoá",
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: earned
                        ? AppColors.brandSecondary.withValues(alpha: 0.18)
                        : Theme.of(context).colorScheme.surfaceContainerHighest,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: earned
                          ? AppColors.brandSecondary
                          : Theme.of(context).dividerColor,
                    ),
                  ),
                  child: Icon(
                    earned ? Icons.workspace_premium : Icons.lock_outline,
                    size: 18,
                    color: earned
                        ? AppColors.brandSecondary
                        : Theme.of(context).hintColor,
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
