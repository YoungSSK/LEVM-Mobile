import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';

/// Widget hiển thị một lựa chọn trong câu hỏi trắc nghiệm.
///
/// State:
/// - Default: viền xám, nền surface
/// - Selected: viền brandPrimary, nền brandPrimary/10%
/// - Correct (sau khi submit): viền xanh success
/// - Incorrect (sau khi submit): viền đỏ danger
///
/// UX: KHÔNG hiện đúng/sai ngay lúc chọn (vì backend chỉ trả kết quả
/// sau khi submit toàn bộ).
class GrammarQuizOptionTile extends StatelessWidget {
  final String text;
  final int index;
  final bool isSelected;
  final bool? isCorrect;
  final bool showResult;
  final VoidCallback? onTap;

  const GrammarQuizOptionTile({
    super.key,
    required this.text,
    required this.index,
    this.isSelected = false,
    this.isCorrect,
    this.showResult = false,
    this.onTap,
  });

  /// Convert index (0-3) sang letter (A, B, C, D).
  String get _optionLetter {
    return String.fromCharCode(65 + index); // A, B, C, D...
  }

  Color _getBackgroundColor(BuildContext context) {
    if (showResult) {
      if (isCorrect == true) {
        return AppColors.success.withValues(alpha: 0.1);
      }
      if (isSelected && isCorrect == false) {
        return AppColors.danger.withValues(alpha: 0.1);
      }
    }
    if (isSelected) {
      return AppColors.brandPrimary.withValues(alpha: 0.1);
    }
    return Theme.of(context).colorScheme.surface;
  }

  Color _getBorderColor(BuildContext context) {
    if (showResult) {
      if (isCorrect == true) {
        return AppColors.success;
      }
      if (isSelected && isCorrect == false) {
        return AppColors.danger;
      }
    }
    if (isSelected) {
      return AppColors.brandPrimary;
    }
    return Theme.of(context).dividerColor;
  }

  Color _getLetterBackgroundColor() {
    if (showResult) {
      if (isCorrect == true) {
        return AppColors.success;
      }
      if (isSelected && isCorrect == false) {
        return AppColors.danger;
      }
    }
    if (isSelected) {
      return AppColors.brandPrimary;
    }
    return AppColors.brandPrimary.withValues(alpha: 0.1);
  }

  Color _getLetterTextColor() {
    if (showResult) {
      if (isCorrect == true || (isSelected && isCorrect == false)) {
        return Colors.white;
      }
    }
    if (isSelected) {
      return Colors.white;
    }
    return AppColors.brandPrimary;
  }

  Color _getTextColor(BuildContext context) {
    if (showResult) {
      if (isCorrect == false && !isSelected) {
        return Theme.of(context).hintColor;
      }
    }
    return Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _getBackgroundColor(context),
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            border: Border.all(
              color: _getBorderColor(context),
              width: isSelected ? 2 : 1.5,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: _getLetterBackgroundColor(),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    _optionLetter,
                    style: TextStyle(
                      color: _getLetterTextColor(),
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  text,
                  style: TextStyle(
                    color: _getTextColor(context),
                    fontSize: 16,
                  ),
                ),
              ),
              if (showResult && isCorrect == true)
                const Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.success,
                  size: 24,
                ),
              if (showResult && isSelected && isCorrect == false)
                const Icon(
                  Icons.cancel_rounded,
                  color: AppColors.danger,
                  size: 24,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
