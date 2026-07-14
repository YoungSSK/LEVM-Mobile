import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_feedback.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/levm_buttons.dart';
import '../../../core/widgets/levm_text_field.dart';
import '../providers/profile_providers.dart';

class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  ConsumerState<ChangePasswordScreen> createState() =>
      _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _oldCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscureOld = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _submitting = false;
  String? _serverError;

  @override
  void dispose() {
    _oldCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _onSubmit() async {
    if (_submitting) return;
    setState(() => _serverError = null);
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final diff = Validators.newPasswordDifferent(
      oldPassword: _oldCtrl.text,
      newPassword: _newCtrl.text,
    );
    if (diff != null) {
      setState(() => _serverError = diff);
      return;
    }

    setState(() => _submitting = true);
    try {
      final msg = await ref.read(currentUserProvider.notifier).changePassword(
            oldPassword: _oldCtrl.text,
            newPassword: _newCtrl.text,
            confirmPassword: _confirmCtrl.text,
          );
      if (!mounted) return;
      AppFeedback.showSuccess(context, msg);
      context.pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _serverError = _friendly(e));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  String _friendly(Object error) {
    final raw = error.toString();
    if (raw.contains("Exception: ")) {
      return raw.replaceFirst("Exception: ", "");
    }
    return "Đổi mật khẩu chưa thành công, bạn thử lại sau nhé.";
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text("Đổi mật khẩu"),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.shield_outlined,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          "Mật khẩu mới cần có tối thiểu 6 ký tự, ít nhất 1 chữ hoa và 1 chữ số.",
                          style: AppTypography.bodySmall.copyWith(
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                LEVMTextField(
                  controller: _oldCtrl,
                  label: "Mật khẩu hiện tại",
                  obscureText: _obscureOld,
                  textInputAction: TextInputAction.next,
                  prefixIcon: const Icon(Icons.lock_outline_rounded),
                  suffixIcon: IconButton(
                    onPressed: () => setState(() => _obscureOld = !_obscureOld),
                    icon: Icon(
                      _obscureOld
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                    ),
                  ),
                  validator: (v) =>
                      (v == null || v.isEmpty) ? "Vui lòng nhập mật khẩu hiện tại." : null,
                ),
                const SizedBox(height: 16),
                LEVMTextField(
                  controller: _newCtrl,
                  label: "Mật khẩu mới",
                  obscureText: _obscureNew,
                  textInputAction: TextInputAction.next,
                  prefixIcon: const Icon(Icons.lock_outline_rounded),
                  suffixIcon: IconButton(
                    onPressed: () => setState(() => _obscureNew = !_obscureNew),
                    icon: Icon(
                      _obscureNew
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                    ),
                  ),
                  onChanged: (_) => setState(() {}),
                  validator: Validators.password,
                ),
                const SizedBox(height: 12),
                PasswordStrengthIndicator(password: _newCtrl.text),
                const SizedBox(height: 16),
                LEVMTextField(
                  controller: _confirmCtrl,
                  label: "Xác nhận mật khẩu mới",
                  obscureText: _obscureConfirm,
                  textInputAction: TextInputAction.done,
                  onEditingComplete: _onSubmit,
                  onChanged: (_) => setState(() {}),
                  prefixIcon: const Icon(Icons.lock_outline_rounded),
                  suffixIcon: IconButton(
                    onPressed: () =>
                        setState(() => _obscureConfirm = !_obscureConfirm),
                    icon: Icon(
                      _obscureConfirm
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                    ),
                  ),
                  validator: (v) =>
                      Validators.confirmPassword(v, _newCtrl.text),
                ),
                if (_serverError != null) ...[
                  const SizedBox(height: 16),
                  InfoBanner(message: _serverError!),
                ],
                const SizedBox(height: 24),
                LEVMPrimaryButton(
                  label: "Cập nhật mật khẩu",
                  leadingIcon: Icons.check_circle_outline,
                  isLoading: _submitting,
                  onPressed: _onSubmit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
