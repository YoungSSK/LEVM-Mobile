import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../profile/models/user_model.dart';
import '../../profile/providers/profile_providers.dart';
import '../../vocabulary/providers/xp_streak_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("LEVM"),
        actions: [
          IconButton(
            tooltip: "Hồ sơ",
            icon: const Icon(Icons.account_circle_rounded),
            onPressed: () => context.push(AppRoutes.profile),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
        child: userAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text(e.toString())),
          data: (user) {
            if (user == null) {
              return const Center(child: Text("Chưa đăng nhập."));
            }
            return _HomeBody(user: user);
          },
        ),
      ),
    );
  }
}

class _HomeBody extends ConsumerStatefulWidget {
  final UserModel user;
  const _HomeBody({required this.user});

  @override
  ConsumerState<_HomeBody> createState() => _HomeBodyState();
}

class _HomeBodyState extends ConsumerState<_HomeBody> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(xpStreakProvider.notifier).loadXpAndStreak();
    });
  }

  @override
  Widget build(BuildContext context) {
    final xpStreakState = ref.watch(xpStreakProvider);

    return ListView(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: AppColors.brandGradient),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _greeting(),
                style: AppTypography.bodyMedium.copyWith(
                  color: Colors.white.withValues(alpha: 0.85),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                widget.user.displayName,
                style: AppTypography.displayMedium.copyWith(
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(
                    Icons.local_fire_department,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    "Streak: ${xpStreakState.streakInfo?.currentStreak ?? widget.user.streak}",
                    style: AppTypography.titleMedium.copyWith(
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Icon(Icons.star_rounded, color: Colors.white),
                  const SizedBox(width: 6),
                  Text(
                    "${xpStreakState.xpInfo?.totalXp ?? widget.user.xp} XP",
                    style: AppTypography.titleMedium.copyWith(
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        _buildSectionHeader("Học từ vựng", Icons.school_rounded),
        const SizedBox(height: 12),
        _QuickActionCard(
          icon: Icons.book_rounded,
          title: "Chủ đề từ vựng",
          subtitle: "Học từ theo chủ đề ngành nghề",
          onTap: () => context.push(AppRoutes.vocabularyTopics),
          color: AppColors.brandPrimary,
        ),
        const SizedBox(height: 24),
        _buildSectionHeader("Học ngữ pháp", Icons.spellcheck_rounded),
        const SizedBox(height: 12),
        _QuickActionCard(
          icon: Icons.spellcheck_rounded,
          title: "Chủ đề ngữ pháp",
          subtitle: "Lý thuyết và bài trắc nghiệm",
          onTap: () => context.push(AppRoutes.grammarTopics),
          color: AppColors.brandSecondary,
        ),
        const SizedBox(height: 24),
        _buildSectionHeader("Hồ sơ", Icons.person_rounded),
        const SizedBox(height: 12),
        _QuickActionCard(
          icon: Icons.person_rounded,
          title: "Hồ sơ cá nhân",
          subtitle: "Cập nhật thông tin, đổi avatar, chỉnh sửa giới thiệu…",
          onTap: () => context.push(AppRoutes.profile),
          color: AppColors.info,
        ),
        const SizedBox(height: 12),
        _QuickActionCard(
          icon: Icons.lock_reset_rounded,
          title: "Đổi mật khẩu",
          subtitle: "Bảo mật tài khoản của bạn.",
          onTap: () => context.push(AppRoutes.changePassword),
          color: AppColors.warning,
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.brandPrimary),
        const SizedBox(width: 8),
        Text(
          title,
          style: AppTypography.titleMedium.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 11) return "Chào buổi sáng,";
    if (h < 14) return "Chào buổi trưa,";
    if (h < 18) return "Chào buổi chiều,";
    return "Chào buổi tối,";
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color color;

  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: theme.dividerColor),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTypography.titleMedium),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: AppTypography.bodySmall.copyWith(
                        color: theme.hintColor,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: color),
            ],
          ),
        ),
      ),
    );
  }
}
