import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/theme_provider.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_feedback.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/badges.dart';
import '../../../core/widgets/gamification.dart';
import '../../../core/widgets/levm_avatar.dart';
import '../../auth/providers/auth_notifier.dart';
import '../models/user_model.dart';
import '../providers/profile_providers.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    final auth = ref.watch(authNotifierProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: userAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _ErrorState(
          message: "Không tải được hồ sơ: ${e.toString()}",
          onRetry: () => ref.read(currentUserProvider.notifier).refresh(),
        ),
        data: (user) {
          if (user == null) {
            return const _EmptyState();
          }
          return RefreshIndicator(
            onRefresh: () =>
                ref.read(currentUserProvider.notifier).refresh(),
            child: CustomScrollView(
              slivers: [
                SliverAppBar(
                  pinned: true,
                  expandedHeight: 200,
                  backgroundColor: AppColors.brandPrimary,
                  foregroundColor: Colors.white,
                  leading: IconButton(
                    tooltip: "Quay lại",
                    icon: const Icon(Icons.arrow_back_rounded),
                    onPressed: () {
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go(AppRoutes.home);
                      }
                    },
                  ),
                  actions: [
                    Consumer(
                      builder: (context, ref, _) {
                        final themeMode = ref.watch(themeProvider);
                        final isDark = themeMode == ThemeMode.dark ||
                            (themeMode == ThemeMode.system &&
                                MediaQuery.platformBrightnessOf(context) == Brightness.dark);
                        return IconButton(
                          tooltip: isDark ? "Chế độ sáng" : "Chế độ tối",
                          icon: Icon(
                            isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                          ),
                          onPressed: () {
                            ref.read(themeProvider.notifier).toggle();
                          },
                        );
                      },
                    ),
                    IconButton(
                      tooltip: "Đăng xuất",
                      icon: const Icon(Icons.logout_rounded),
                      onPressed: () => _confirmLogout(context, ref),
                    ),
                  ],
                  flexibleSpace: FlexibleSpaceBar(
                    titlePadding: const EdgeInsetsDirectional.only(
                      start: 56,
                      end: 56,
                      bottom: 14,
                    ),
                    title: Text(
                      "Hồ sơ của tôi",
                      style: AppTypography.titleLarge.copyWith(
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    centerTitle: false,
                    background: _ProfileHeaderBackground(user: user),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _IdentityCard(user: user, isAdmin: auth.role == "admin"),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: StreakBadge(streak: user.streak),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: XpProgressBar(xp: user.xp),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (user.streak > 0) ...[
                          _Card(
                            title: "Chuỗi ngày học",
                            child: StreakCalendar(streak: user.streak),
                          ),
                          const SizedBox(height: 16),
                        ],
                        const BadgeStrip(),
                        const SizedBox(height: 16),
                        _OccupationCard(user: user),
                        const SizedBox(height: 16),
                        _BioCard(user: user),
                        const SizedBox(height: 24),
                        OutlinedButton.icon(
                          onPressed: () =>
                              context.push(AppRoutes.editProfile),
                          icon: const Icon(Icons.edit_rounded),
                          label: const Text("Chỉnh sửa hồ sơ"),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: () =>
                              context.push(AppRoutes.changePassword),
                          icon: const Icon(Icons.lock_reset_rounded),
                          label: const Text("Đổi mật khẩu"),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: () => _confirmLogout(context, ref),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.danger,
                          ),
                          icon: const Icon(Icons.logout_rounded),
                          label: const Text("Đăng xuất"),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final ok = await AppFeedback.confirm(
      context,
      title: "Đăng xuất?",
      message:
          "Bạn sẽ phải đăng nhập lại để tiếp tục học. Hẹn gặp lại nhé!",
      confirmText: "Đăng xuất",
      destructive: true,
    );
    if (!ok) return;
    await ref.read(authNotifierProvider.notifier).logout();
    if (context.mounted) context.go(AppRoutes.login);
  }
}

class _ProfileHeaderBackground extends StatelessWidget {
  final UserModel user;
  const _ProfileHeaderBackground({required this.user});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: AppColors.brandGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      // Chừa khoảng đáy cho title "Hồ sơ của tôi" của FlexibleSpaceBar
      // khi SliverAppBar ở trạng thái collapsed — tránh title đè lên avatar.
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 48),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              LEVMAvatar(user: user, size: 76),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      user.displayName,
                      style: AppTypography.headlineLarge.copyWith(
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "@${user.username}",
                      style: AppTypography.bodyMedium.copyWith(
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IdentityCard extends StatelessWidget {
  final UserModel user;
  final bool isAdmin;

  const _IdentityCard({required this.user, required this.isAdmin});

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.brandPrimary.withValues(alpha: 0.12),
                child: const Icon(
                  Icons.alternate_email_rounded,
                  color: AppColors.brandPrimary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Email",
                      style: AppTypography.bodySmall.copyWith(
                        color: Theme.of(context).hintColor,
                      ),
                    ),
                    Text(
                      user.email,
                      style: AppTypography.bodyLarge,
                    ),
                  ],
                ),
              ),
              if (isAdmin)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.brandSecondary.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.admin_panel_settings_rounded,
                        size: 14,
                        color: AppColors.brandSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        "Quản trị",
                        style: AppTypography.labelMedium.copyWith(
                          color: AppColors.brandSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OccupationCard extends StatelessWidget {
  final UserModel user;
  const _OccupationCard({required this.user});

  @override
  Widget build(BuildContext context) {
    // Ưu tiên hiển thị cấp nhóm ngành (category) vì hiện tại chức năng chỉnh
    // sửa chỉ cho phép chọn nhóm ngành; rơi xuống cấp nghề cụ thể nếu backend
    // cũ vẫn trả về `occupationId` mà chưa có category.
    final categoryId = user.occupationCategoryId;
    final categoryName = user.occupationCategoryName;
    final occupationId = user.occupationId;
    final occupationName = user.occupationName;

    final hasCategory = categoryId != null || categoryName != null;
    final hasOccupation = !hasCategory &&
        (occupationName != null || occupationId != null);

    return _Card(
      title: "Nhóm ngành đang học",
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.brandTertiary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.work_outline_rounded,
              color: AppColors.brandTertiary,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (hasCategory) ...[
                  Text(
                    categoryName ?? "Đã chọn một nhóm ngành",
                    style: AppTypography.titleMedium,
                  ),
                  if (categoryName == null && categoryId != null)
                    Text(
                      "Mã: $categoryId",
                      style: AppTypography.bodySmall.copyWith(
                        color: Theme.of(context).hintColor,
                      ),
                    ),
                ] else if (hasOccupation) ...[
                  Text(
                    occupationName ?? "Đã chọn một nghề nghiệp",
                    style: AppTypography.titleMedium,
                  ),
                  if (occupationName == null && occupationId != null)
                    Text(
                      "Mã: $occupationId",
                      style: AppTypography.bodySmall.copyWith(
                        color: Theme.of(context).hintColor,
                      ),
                    ),
                ] else ...[
                  Text(
                    "Chưa chọn nhóm ngành",
                    style: AppTypography.titleMedium.copyWith(
                      color: Theme.of(context).hintColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "Chọn nhóm ngành để học từ vựng chuyên ngành phù hợp với bạn.",
                    style: AppTypography.bodySmall.copyWith(
                      color: Theme.of(context).hintColor,
                    ),
                  ),
                ],
              ],
            ),
          ),
          TextButton(
            onPressed: () => context.push(AppRoutes.editProfile),
            child: Text(
              hasCategory
                  ? "Đổi"
                  : hasOccupation
                      ? "Đổi"
                      : "Chọn ngay",
            ),
          ),
        ],
      ),
    );
  }
}

class _BioCard extends StatelessWidget {
  final UserModel user;
  const _BioCard({required this.user});

  @override
  Widget build(BuildContext context) {
    final hasBio = (user.bio ?? "").isNotEmpty;
    return _Card(
      title: "Giới thiệu",
      child: hasBio
          ? Text(
              user.bio!,
              style: AppTypography.bodyMedium.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
              ),
            )
          : Text(
              "Chưa có phần giới thiệu. Hãy chia sẻ đôi chút về bạn nhé.",
              style: AppTypography.bodyMedium.copyWith(
                color: Theme.of(context).hintColor,
                fontStyle: FontStyle.italic,
              ),
            ),
    );
  }
}

class _Card extends StatelessWidget {
  final Widget child;
  final String? title;
  const _Card({required this.child, this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Text(
              title!,
              style: AppTypography.titleMedium.copyWith(
                color: Theme.of(context).hintColor,
                fontSize: 13,
                letterSpacing: 0.4,
              ),
            ),
            const SizedBox(height: 12),
          ],
          child,
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.person_off_outlined,
              size: 48,
              color: AppColors.brandPrimary,
            ),
            const SizedBox(height: 12),
            Text(
              "Không có dữ liệu hồ sơ",
              style: AppTypography.titleLarge,
            ),
            const SizedBox(height: 6),
            Text(
              "Vui lòng đăng nhập lại để tiếp tục.",
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium.copyWith(
                color: Theme.of(context).hintColor,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => context.go(AppRoutes.login),
              icon: const Icon(Icons.login_rounded),
              label: const Text("Về trang đăng nhập"),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              size: 48,
              color: AppColors.danger,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text("Thử lại"),
            ),
          ],
        ),
      ),
    );
  }
}
