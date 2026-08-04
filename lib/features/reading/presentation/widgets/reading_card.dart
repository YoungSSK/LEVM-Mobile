import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/vip_access_guard.dart';
import '../../../membership/providers/membership_provider.dart';
import '../../domain/models/reading_passage.dart';
import 'cefr_level_badge.dart';

class ReadingCard extends ConsumerWidget {
  final ReadingPassage passage;
  final VoidCallback onTap;

  const ReadingCard({
    super.key,
    required this.passage,
    required this.onTap,
  });

  bool _isValidUrl(String? url) {
    if (url == null || url.trim().isEmpty) return false;
    final trimmed = url.trim().toLowerCase();
    return trimmed.startsWith('http://') || trimmed.startsWith('https://');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final membershipState = ref.watch(membershipNotifierProvider);
    final subscription = membershipState.currentSubscription;

    final isVip = VipAccessHelper.isVipLesson(passage.allowedPackageIds);
    final hasAccess = VipAccessHelper.hasAccess(
      subscription: subscription,
      allowedPackageIds: passage.allowedPackageIds,
    );
    final isLocked = isVip && !hasAccess;
    final requiredPackage = VipAccessHelper.getRequiredPackageName(passage.allowedPackageIds);

    return Material(
      color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      borderRadius: BorderRadius.circular(20),
      elevation: isDark ? 0 : 2,
      shadowColor: Colors.black.withValues(alpha: 0.04),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          if (isLocked) {
            VipAccessHelper.showVipLockedToast(
              context,
              requiredPackageName: requiredPackage,
            );
          } else {
            onTap();
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thumbnail Image
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: SizedBox(
                  width: 90,
                  height: 90,
                  child: _isValidUrl(passage.thumbnail)
                      ? Image.network(
                          passage.thumbnail,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => _buildPlaceholderImage(),
                        )
                      : _buildPlaceholderImage(),
                ),
              ),
              const SizedBox(width: 14),
              // Content Column
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CefrLevelBadge(level: passage.cefrLevel),
                        const SizedBox(width: 6),
                        if (isVip) ...[
                          VipLockBadge(packageName: requiredPackage, compact: true),
                          const SizedBox(width: 6),
                        ],
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.brandPrimary.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            passage.readingType.toUpperCase(),
                            style: AppTypography.labelMedium.copyWith(
                              color: AppColors.brandPrimary,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const Spacer(),
                        // XP Reward Badge
                        Row(
                          children: [
                            const Icon(Icons.bolt, size: 14, color: AppColors.xp),
                            const SizedBox(width: 2),
                            Text(
                              "+${passage.xpReward} XP",
                              style: AppTypography.labelMedium.copyWith(
                                color: AppColors.xp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      passage.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.titleMedium.copyWith(
                        fontWeight: FontWeight.bold,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time_rounded,
                          size: 14,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          "${passage.estimatedTime} phút",
                          style: AppTypography.bodySmall.copyWith(
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(
                          Icons.menu_book_rounded,
                          size: 14,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          "${passage.wordCount} từ",
                          style: AppTypography.bodySmall.copyWith(
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
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

  Widget _buildPlaceholderImage() {
    return Container(
      color: AppColors.brandPrimary.withValues(alpha: 0.1),
      child: const Center(
        child: Icon(
          Icons.menu_book_outlined,
          color: AppColors.brandPrimary,
          size: 36,
        ),
      ),
    );
  }
}
