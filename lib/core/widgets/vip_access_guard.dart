import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/membership/domain/models/membership_models.dart';
import '../router/app_routes.dart';
import '../theme/app_typography.dart';

class VipAccessHelper {
  /// Kiểm tra 1 package có phải gói miễn phí / gói thường (level 0 hoặc price 0) hay không
  static bool _isFreePackage(dynamic pkg) {
    if (pkg == null) return false;
    if (pkg is Map<String, dynamic>) {
      final level = (pkg['level'] as num?)?.toInt();
      final price = (pkg['price'] as num?)?.toInt();
      final isFree = pkg['isFree'] == true;
      final slug = (pkg['slug'] ?? '').toString().toLowerCase();
      final name = (pkg['name'] ?? '').toString().toLowerCase();

      if (isFree || (level != null && level == 0) || (price != null && price == 0)) {
        return true;
      }
      if (slug == 'free' || slug == 'thuong' || slug == 'goi-thuong') return true;
      if (name.contains('miễn phí') || name == 'gói thường' || name == 'thường') return true;
    }
    return false;
  }

  /// Kiểm tra xem bài học có thực sự yêu cầu gói VIP hay không.
  /// Nếu allowedPackageIds rỗng HOẶC chứa bất kỳ gói Free (level 0) nào -> Bài học miễn phí cho tất cả.
  static bool isVipLesson(List<dynamic>? allowedPackageIds) {
    if (allowedPackageIds == null || allowedPackageIds.isEmpty) return false;

    for (final pkg in allowedPackageIds) {
      if (_isFreePackage(pkg)) {
        return false; // Nếu có gói Thường/Free trong whitelist -> Bài Miễn Phí
      }
    }
    return true;
  }

  /// Lấy tên gói VIP yêu cầu tối thiểu (chỉ lấy gói VIP level > 0)
  static String getRequiredPackageName(List<dynamic>? allowedPackageIds) {
    if (allowedPackageIds == null || allowedPackageIds.isEmpty) return 'VIP';

    for (final pkg in allowedPackageIds) {
      if (pkg is Map<String, dynamic>) {
        if (_isFreePackage(pkg)) continue;
        final name = (pkg['name'] ?? '').toString().trim();
        if (name.isNotEmpty) return name;
      }
    }
    return 'VIP';
  }

  /// Kiểm tra xem người dùng hiện tại có đủ quyền truy cập bài học không.
  static bool hasAccess({
    required SubscriptionModel? subscription,
    required List<dynamic>? allowedPackageIds,
  }) {
    // Nếu là bài học Miễn phí (rỗng hoặc chứa gói Thường/Free) -> mở cho tất cả
    if (!isVipLesson(allowedPackageIds)) return true;

    // Nếu bài học VIP mà người dùng chưa đăng ký gói nào hoặc gói không active
    if (subscription == null || !subscription.isActive) return false;

    final userLevel = subscription.packageLevel;
    final userPackageId = subscription.packageId;

    for (final pkg in allowedPackageIds!) {
      if (pkg is Map<String, dynamic>) {
        final pkgId = (pkg['_id'] ?? pkg['id'] ?? '').toString();
        final pkgLevel = (pkg['level'] as num?)?.toInt() ?? 0;
        if (pkgId == userPackageId || userLevel >= pkgLevel) {
          return true;
        }
      } else if (pkg.toString() == userPackageId) {
        return true;
      }
    }

    // Nếu userLevel > 0 (có mua gói VIP bất kỳ), mở bài học
    return userLevel >= 1;
  }

  /// Hiển thị Toast / SnackBar thông báo bài học bị khóa VIP kèm nút Nâng cấp ngay
  static void showVipLockedToast(
    BuildContext context, {
    required String requiredPackageName,
  }) {
    final pkgDisplay = requiredPackageName.toLowerCase().startsWith('gói')
        ? requiredPackageName
        : 'gói $requiredPackageName';

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        elevation: 8,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: const Color(0xFF1E1E2C),
        duration: const Duration(seconds: 4),
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFFFD700), Color(0xFFFF8C00)],
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.workspace_premium_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Nội dung dành cho VIP 🔒',
                    style: AppTypography.labelLarge.copyWith(
                      color: const Color(0xFFFFD700),
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Cần nâng cấp lên $pkgDisplay trở lên để mở khóa bài học này.',
                    style: AppTypography.bodySmall.copyWith(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 12,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        action: SnackBarAction(
          label: 'Nâng cấp',
          textColor: const Color(0xFFFFD700),
          onPressed: () {
            context.push(AppRoutes.membership);
          },
        ),
      ),
    );
  }
}

/// Widget Huy hiệu khóa VIP hiển thị góc thẻ bài học
class VipLockBadge extends StatelessWidget {
  final String packageName;
  final bool compact;

  const VipLockBadge({
    super.key,
    required this.packageName,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final text = packageName.isNotEmpty ? 'VIP $packageName' : 'VIP';

    if (compact) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFFD700), Color(0xFFFF8C00)],
          ),
          borderRadius: BorderRadius.circular(6),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF8C00).withValues(alpha: 0.3),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lock_rounded, size: 10, color: Colors.white),
            const SizedBox(width: 3),
            Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 9,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFD700), Color(0xFFFF8C00)],
        ),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF8C00).withValues(alpha: 0.3),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.lock_rounded, size: 12, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 11,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}
