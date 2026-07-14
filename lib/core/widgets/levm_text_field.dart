import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// Themed text field with consistent rounded shape, optional prefix/suffix,
/// inline error message, and FormField-compatible `validator`.
class LEVMTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final String? errorText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool obscureText;
  final bool enabled;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onEditingComplete;
  final FocusNode? focusNode;
  final int? maxLength;
  final int? maxLines;
  final String? counterText;
  final TextCapitalization textCapitalization;
  final AutovalidateMode? autovalidateMode;
  final String? Function(String?)? validator;

  const LEVMTextField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.errorText,
    this.keyboardType,
    this.textInputAction,
    this.obscureText = false,
    this.enabled = true,
    this.prefixIcon,
    this.suffixIcon,
    this.onChanged,
    this.onEditingComplete,
    this.focusNode,
    this.maxLength,
    this.maxLines = 1,
    this.counterText,
    this.textCapitalization = TextCapitalization.none,
    this.autovalidateMode,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.labelLarge.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          focusNode: focusNode,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          obscureText: obscureText,
          enabled: enabled,
          maxLength: maxLength,
          maxLines: obscureText ? 1 : maxLines,
          textCapitalization: textCapitalization,
          onChanged: onChanged,
          onEditingComplete: onEditingComplete,
          validator: validator,
          style: AppTypography.bodyLarge,
          decoration: InputDecoration(
            hintText: hint,
            errorText: errorText,
            counterText: counterText,
            prefixIcon: prefixIcon,
            suffixIcon: suffixIcon,
          ),
        ),
      ],
    );
  }
}

/// Pill-shaped chip used to surface the password strength checks.
class StrengthChip extends StatelessWidget {
  final String label;
  final bool met;

  const StrengthChip({super.key, required this.label, required this.met});

  @override
  Widget build(BuildContext context) {
    final color = met ? AppColors.success : Theme.of(context).hintColor;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: met
            ? AppColors.success.withValues(alpha: 0.12)
            : Theme.of(context).colorScheme.surfaceContainerHighest
                .withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            met ? Icons.check_circle : Icons.radio_button_unchecked,
            color: color,
            size: 14,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTypography.labelMedium.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}

/// Visual checklist for password complexity.
class PasswordStrengthIndicator extends StatelessWidget {
  final String password;
  final bool showConfirmMismatch;
  final String? confirmValue;

  const PasswordStrengthIndicator({
    super.key,
    required this.password,
    this.showConfirmMismatch = false,
    this.confirmValue,
  });

  bool get _hasMinLength => password.length >= 6;
  bool get _hasUpper => password.contains(RegExp(r"[A-Z]"));
  bool get _hasDigit => password.contains(RegExp(r"[0-9]"));

  @override
  Widget build(BuildContext context) {
    final checks = <(String, bool)>[
      ("Ít nhất 6 ký tự", _hasMinLength),
      ("Có chữ hoa", _hasUpper),
      ("Có chữ số", _hasDigit),
    ];
    if (showConfirmMismatch && confirmValue != null) {
      checks.add(("Mật khẩu khớp nhau", password == confirmValue));
    }
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: checks
          .map((entry) => StrengthChip(label: entry.$1, met: entry.$2))
          .toList(),
    );
  }
}
