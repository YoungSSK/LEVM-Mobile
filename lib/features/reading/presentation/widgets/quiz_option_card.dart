import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

class QuizOptionCard extends StatelessWidget {
  final String optionKey; // A, B, C, D
  final String optionText;
  final bool isSelected;
  final bool isSubmitted;
  final bool isCorrect;
  final VoidCallback onTap;

  const QuizOptionCard({
    super.key,
    required this.optionKey,
    required this.optionText,
    required this.isSelected,
    this.isSubmitted = false,
    this.isCorrect = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    Color backgroundColor = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    Color textColor = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;

    if (isSelected) {
      borderColor = AppColors.brandPrimary;
      backgroundColor = AppColors.brandPrimary.withValues(alpha: 0.08);
    }

    if (isSubmitted) {
      if (isCorrect) {
        borderColor = AppColors.success;
        backgroundColor = AppColors.success.withValues(alpha: 0.12);
      } else if (isSelected) {
        borderColor = AppColors.danger;
        backgroundColor = AppColors.danger.withValues(alpha: 0.12);
      }
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: isSubmitted ? null : onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderColor, width: isSelected || isSubmitted ? 2 : 1),
            ),
            child: Row(
              children: [
                // Option Key Circle (A, B, C, D)
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected ? AppColors.brandPrimary : (isDark ? AppColors.darkSurfaceAlt : AppColors.lightSurfaceAlt),
                  ),
                  child: Center(
                    child: Text(
                      optionKey,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isSelected ? Colors.white : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                // Option Text
                Expanded(
                  child: Text(
                    optionText,
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: textColor,
                    ),
                  ),
                ),
                // Icon Feedback
                if (isSubmitted) ...[
                  if (isCorrect)
                    const Icon(Icons.check_circle_rounded, color: AppColors.success)
                  else if (isSelected)
                    const Icon(Icons.cancel_rounded, color: AppColors.danger),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
