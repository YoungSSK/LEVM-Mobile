import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_routes.dart';

/// Widget hiển thị icon khoá lên trên nội dung bị giới hạn.
/// Tap vào → bottom sheet nâng cấp gói.
///
/// Dùng trong các màn hình danh sách bài học khi item có locked: true.
///
/// Ví dụ dùng:
///   Stack(children: [
///     LessonCard(...),
///     if (isLocked) LockedOverlayWidget(lessonTitle: lesson.title),
///   ])
class LockedOverlayWidget extends StatelessWidget {
  final String? lessonTitle;
  final String? requiredPackageName;

  const LockedOverlayWidget({
    super.key,
    this.lessonTitle,
    this.requiredPackageName,
  });

  void _showUpgradeSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => UpgradeBottomSheet(
        lessonTitle: lessonTitle,
        requiredPackageName: requiredPackageName,
        onUpgrade: () {
          Navigator.pop(ctx);
          context.push(AppRoutes.membership);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showUpgradeSheet(context),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.lock, color: Colors.white, size: 28),
              SizedBox(height: 4),
              Text(
                'VIP',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Bottom sheet giải thích lý do bị khoá và CTA nâng cấp.
class UpgradeBottomSheet extends StatelessWidget {
  final String? lessonTitle;
  final String? requiredPackageName;
  final VoidCallback onUpgrade;

  const UpgradeBottomSheet({
    super.key,
    this.lessonTitle,
    this.requiredPackageName,
    required this.onUpgrade,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: colorScheme.onSurface.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Icon
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.lock_open_rounded,
              color: colorScheme.primary,
              size: 30,
            ),
          ),

          const SizedBox(height: 16),

          Text(
            'Nội dung VIP',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            lessonTitle != null
                ? '"$lessonTitle" yêu cầu gói thành viên VIP.'
                : 'Bài học này yêu cầu gói thành viên VIP.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),

          if (requiredPackageName != null) ...[
            const SizedBox(height: 4),
            Text(
              'Gói yêu cầu: $requiredPackageName',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],

          const SizedBox(height: 24),

          // CTA
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onUpgrade,
              icon: const Icon(Icons.star_rounded),
              label: const Text('Nâng cấp ngay'),
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          const SizedBox(height: 10),

          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Để sau',
              style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.5)),
            ),
          ),
        ],
      ),
    );
  }
}
