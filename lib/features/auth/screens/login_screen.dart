import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_feedback.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/levm_buttons.dart';
import '../../../core/widgets/levm_logo.dart';
import '../../../core/widgets/levm_text_field.dart';
import '../providers/auth_notifier.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscure = true;
  bool _submitting = false;
  String? _serverError;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _onSubmit() async {
    if (_submitting) return;
    setState(() => _serverError = null);
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _submitting = true);
    try {
      await ref.read(authNotifierProvider.notifier).login(
            email: _emailCtrl.text.trim(),
            password: _passwordCtrl.text,
          );
      if (!mounted) return;
      context.go(AppRoutes.home);
    } catch (e) {
      if (!mounted) return;
      setState(() => _serverError = _friendly(e));
      AppFeedback.showError(context, _serverError!);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  String _friendly(Object error) {
    // AuthApi._translateError returns an `Exception` whose `.toString()` is
    // exactly the message we want to show — the backend already speaks
    // Vietnamese (e.g. "Username hoặc Password không đúng"), so just strip
    // the "Exception: " prefix and pass it through. Fall back to a generic
    // message only when we don't recognise the error shape at all.
    final raw = error.toString();
    final stripped = raw.replaceFirst("Exception: ", "").trim();
    if (stripped.isNotEmpty && stripped != raw) {
      return stripped;
    }
    // Dio sometimes wraps the message without the "Exception: " prefix.
    if (stripped.isNotEmpty) return stripped;
    return "Đăng nhập chưa thành công, bạn thử lại sau nhé.";
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 24),
                const Center(child: LEVMLogo(size: 72)),
                const SizedBox(height: 24),
                Text(
                  "Chào bạn đến với LEVM 👋",
                  textAlign: TextAlign.center,
                  style: AppTypography.displayMedium.copyWith(
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Học tiếng Anh theo đúng nghề nghiệp bạn đang theo đuổi.",
                  textAlign: TextAlign.center,
                  style: AppTypography.bodyMedium.copyWith(
                    color: theme.hintColor,
                  ),
                ),
                const SizedBox(height: 32),
                LEVMTextField(
                  controller: _emailCtrl,
                  label: "Email",
                  hint: "you@example.com",
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  prefixIcon: const Icon(Icons.alternate_email_rounded),
                  validator: Validators.email,
                ),
                const SizedBox(height: 18),
                LEVMTextField(
                  controller: _passwordCtrl,
                  label: "Mật khẩu",
                  hint: "Tối thiểu 6 ký tự",
                  obscureText: _obscure,
                  textInputAction: TextInputAction.done,
                  onEditingComplete: _onSubmit,
                  prefixIcon: const Icon(Icons.lock_outline_rounded),
                  suffixIcon: IconButton(
                    onPressed: () => setState(() => _obscure = !_obscure),
                    icon: Icon(
                      _obscure
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                    ),
                  ),
                  validator: Validators.password,
                ),
                const SizedBox(height: 8),
                if (_serverError != null) ...[
                  const SizedBox(height: 8),
                  InfoBanner(message: _serverError!),
                ],
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      // TODO(backend): chờ API /auth/forgot-password.
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            "Tính năng đang được phát triển, bạn quay lại sau nhé.",
                          ),
                        ),
                      );
                    },
                    child: const Text("Quên mật khẩu?"),
                  ),
                ),
                const SizedBox(height: 8),
                LEVMPrimaryButton(
                  label: "Đăng nhập",
                  leadingIcon: Icons.login_rounded,
                  isLoading: _submitting,
                  onPressed: _onSubmit,
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: Divider(color: theme.dividerColor),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        "Chưa có tài khoản?",
                        style: AppTypography.bodySmall.copyWith(
                          color: theme.hintColor,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Divider(color: theme.dividerColor),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                LEVMSecondaryButton(
                  label: "Tạo tài khoản mới",
                  leadingIcon: Icons.person_add_alt_1_rounded,
                  onPressed: () => context.push(AppRoutes.register),
                ),
                const SizedBox(height: 32),
                _StudyMotivationStrip(color: AppColors.brandPrimary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StudyMotivationStrip extends StatelessWidget {
  final Color color;
  const _StudyMotivationStrip({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(Icons.auto_awesome_rounded, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Mỗi ngày 5 phút, tiến bộ cả năm 💪",
                  style: AppTypography.titleMedium.copyWith(
                    color: color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  "Mỗi ngày bạn học sẽ tích luỹ XP và giữ streak — đừng để chuỗi ngày học bị đứt nhé!",
                  style: AppTypography.bodySmall.copyWith(
                    color: Theme.of(context).hintColor,
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
