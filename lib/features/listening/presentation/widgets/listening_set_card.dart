import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/vip_access_guard.dart';
import '../../../membership/providers/membership_provider.dart';
import '../../domain/models/listening_models.dart';

class ListeningSetCard extends ConsumerWidget {
  final ListeningSet set;
  final VoidCallback onTap;

  const ListeningSetCard({
    super.key,
    required this.set,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membershipState = ref.watch(membershipNotifierProvider);
    final subscription = membershipState.currentSubscription;

    final isVip = set.isProRequired || VipAccessHelper.isVipLesson(set.allowedPackageIds);
    final hasAccess = VipAccessHelper.hasAccess(
      subscription: subscription,
      allowedPackageIds: set.allowedPackageIds,
    );
    final isLocked = isVip && !hasAccess;
    final requiredPackage = VipAccessHelper.getRequiredPackageName(set.allowedPackageIds);

    Color partColor;
    String partTitle;

    switch (set.part) {
      case 1:
        partColor = const Color(0xFF3F8CFF);
        partTitle = 'Part 1 • Mô Tả Ảnh';
        break;
      case 2:
        partColor = const Color(0xFF22C55E);
        partTitle = 'Part 2 • Hỏi - Đáp';
        break;
      case 3:
        partColor = const Color(0xFFFF9F43);
        partTitle = 'Part 3 • Hội Thoại';
        break;
      case 4:
        partColor = const Color(0xFFA855F7);
        partTitle = 'Part 4 • Bài Nói';
        break;
      default:
        partColor = AppColors.brandPrimary;
        partTitle = 'Part ${set.part}';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppColors.lightSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isLocked ? Colors.amber.shade400 : AppColors.lightBorder,
          width: isLocked ? 1.5 : 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
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
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Part Badge & Package/XP Badges
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: partColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        partTitle,
                        style: TextStyle(
                          color: partColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        if (isVip) ...[
                          VipLockBadge(packageName: requiredPackage, compact: true),
                          const SizedBox(width: 8),
                        ],
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.xp.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.stars_rounded, size: 13, color: AppColors.xp),
                              const SizedBox(width: 3),
                              Text(
                                '+${set.xpReward} XP',
                                style: const TextStyle(
                                  color: AppColors.xp,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Set Title
                Text(
                  set.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.lightTextPrimary,
                  ),
                ),

                const SizedBox(height: 14),
                const Divider(height: 1, color: AppColors.lightBorder),
                const SizedBox(height: 12),

                // Bottom Stats Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.quiz_outlined, size: 16, color: AppColors.lightTextSecondary),
                        const SizedBox(width: 4),
                        Text(
                          '${set.questionCount} câu hỏi',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.lightTextSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Icon(Icons.check_circle_outline_rounded, size: 16, color: AppColors.success),
                        const SizedBox(width: 4),
                        Text(
                          'Đạt ${set.passThreshold}%',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.lightTextSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 14,
                      color: AppColors.brandPrimary,
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
