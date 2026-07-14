import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/levm_buttons.dart';
import '../../../core/widgets/levm_text_field.dart';
import '../providers/auth_notifier.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscure = true;
  bool _obscureConfirm = true;
  bool _submitting = false;
  String? _serverError;
  bool _success = false;

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _onSubmit() async {
    if (_submitting || _success) return;
    setState(() => _serverError = null);
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _submitting = true);
    try {
      await ref.read(authNotifierProvider.notifier).register(
            username: _usernameCtrl.text.trim(),
            email: _emailCtrl.text.trim(),
            password: _passwordCtrl.text,
          );
      if (!mounted) return;
      setState(() => _success = true);
      await _showSuccessDialog();
      if (!mounted) return;
      // Backend doesn't auto-login; push user back to login screen.
      context.go(AppRoutes.login);
    } catch (e) {
      if (!mounted) return;
      setState(() => _serverError = _friendly(e));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _showSuccessDialog() async {
    final theme = Theme.of(context);
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: AppColors.brandGradient,
                  ),
                ),
                child: const Icon(
                  Icons.celebration_outlined,
                  color: Colors.white,
                  size: 40,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                "Chào mừng bạn 🎉",
                style: AppTypography.headlineLarge.copyWith(
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Tài khoản đã sẵn sàng. Hành trình học tiếng Anh theo nghề của bạn bắt đầu từ đây!",
                textAlign: TextAlign.center,
                style: AppTypography.bodyMedium.copyWith(
                  color: theme.hintColor,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text("Đăng nhập ngay"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _friendly(Object error) {
    final raw = error.toString();
    final stripped = raw.replaceFirst("Exception: ", "").trim();
    if (stripped.isNotEmpty) return stripped;
    return "Đăng ký chưa thành công, bạn thử lại sau nhé.";
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  "Tạo tài khoản",
                  style: AppTypography.displayMedium.copyWith(
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Chỉ mất 30 giây — để bắt đầu hành trình học của bạn.",
                  style: AppTypography.bodyMedium.copyWith(
                    color: theme.hintColor,
                  ),
                ),
                const SizedBox(height: 28),
                LEVMTextField(
                  controller: _usernameCtrl,
                  label: "Tên đăng nhập",
                  hint: "3-30 ký tự, chỉ chữ, số, dấu chấm hoặc _",
                  keyboardType: TextInputType.text,
                  textCapitalization: TextCapitalization.none,
                  prefixIcon: const Icon(Icons.person_outline_rounded),
                  textInputAction: TextInputAction.next,
                  validator: Validators.username,
                ),
                const SizedBox(height: 18),
                LEVMTextField(
                  controller: _emailCtrl,
                  label: "Email",
                  hint: "you@example.com",
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: const Icon(Icons.alternate_email_rounded),
                  textInputAction: TextInputAction.next,
                  validator: Validators.email,
                ),
                const SizedBox(height: 18),
                LEVMTextField(
                  controller: _passwordCtrl,
                  label: "Mật khẩu",
                  keyboardType: TextInputType.visiblePassword,
                  textInputAction: TextInputAction.next,
                  obscureText: _obscure,
                  prefixIcon: const Icon(Icons.lock_outline_rounded),
                  suffixIcon: IconButton(
                    onPressed: () => setState(() => _obscure = !_obscure),
                    icon: Icon(
                      _obscure
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                    ),
                  ),
                  onChanged: (_) => setState(() {}),
                  validator: Validators.password,
                ),
                const SizedBox(height: 12),
                PasswordStrengthIndicator(
                  password: _passwordCtrl.text,
                  showConfirmMismatch: _confirmCtrl.text.isNotEmpty,
                  confirmValue: _confirmCtrl.text,
                ),
                const SizedBox(height: 18),
                LEVMTextField(
                  controller: _confirmCtrl,
                  label: "Xác nhận mật khẩu",
                  keyboardType: TextInputType.visiblePassword,
                  textInputAction: TextInputAction.done,
                  obscureText: _obscureConfirm,
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
                  validator: (v) => Validators.confirmPassword(
                    v,
                    _passwordCtrl.text,
                  ),
                ),
                if (_serverError != null) ...[
                  const SizedBox(height: 16),
                  InfoBanner(message: _serverError!),
                ],
                const SizedBox(height: 24),
                LEVMPrimaryButton(
                  label: "Tạo tài khoản",
                  leadingIcon: Icons.rocket_launch_rounded,
                  isLoading: _submitting,
                  onPressed: _onSubmit,
                ),
                const SizedBox(height: 16),
                RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: AppTypography.bodySmall.copyWith(
                      color: theme.hintColor,
                    ),
                    children: [
                      const TextSpan(text: "Bằng việc tiếp tục, bạn đồng ý với "),
                      TextSpan(
                        text: "Điều khoản",
                        style: AppTypography.bodySmall.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const TextSpan(text: " và "),
                      TextSpan(
                        text: "Chính sách bảo mật",
                        style: AppTypography.bodySmall.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const TextSpan(text: " của LEVM."),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Đã có tài khoản?",
                      style: AppTypography.bodyMedium.copyWith(
                        color: theme.hintColor,
                      ),
                    ),
                    TextButton(
                      onPressed: () => context.pop(),
                      child: const Text("Đăng nhập"),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
