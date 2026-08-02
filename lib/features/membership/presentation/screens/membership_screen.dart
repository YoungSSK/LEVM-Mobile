import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/membership_provider.dart';
import '../../domain/models/membership_models.dart';

/// Màn hình nâng cấp gói thành viên.
/// Hiển thị danh sách gói VIP, CTA mua gói → mở trang thanh toán SePay.
class MembershipScreen extends ConsumerStatefulWidget {
  const MembershipScreen({super.key});

  @override
  ConsumerState<MembershipScreen> createState() => _MembershipScreenState();
}

class _MembershipScreenState extends ConsumerState<MembershipScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(membershipNotifierProvider.notifier).loadAll();
    });
  }

  Future<void> _handleCheckout(PackageModel pkg) async {
    try {
      final url = await ref.read(membershipNotifierProvider.notifier).checkout(pkg.id);
      if (url == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Gói này không yêu cầu thanh toán')),
          );
          await ref.read(membershipNotifierProvider.notifier).refreshAfterPayment();
        }
        return;
      }

      // Mở URL thanh toán SePay
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        // Sau khi người dùng quay lại, refresh subscription
        if (mounted) {
          await ref.read(membershipNotifierProvider.notifier).refreshAfterPayment();
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Đang kiểm tra giao dịch...'),
              backgroundColor: Colors.blue,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Không thể mở trang thanh toán'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(membershipNotifierProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('Nâng cấp gói'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: colorScheme.onSurface,
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                // Current subscription banner
                if (state.currentSubscription != null)
                  SliverToBoxAdapter(
                    child: _CurrentSubscriptionBanner(sub: state.currentSubscription!),
                  ),

                // Header
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Chọn gói phù hợp',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Mở khoá toàn bộ bài học VIP và học không giới hạn.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Package cards
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, i) {
                        final pkg = state.packages[i];
                        final isRecommended = i == 1; // Middle plan recommended
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _PackageCard(
                            package: pkg,
                            isRecommended: isRecommended,
                            onBuy: () => _handleCheckout(pkg),
                          ),
                        );
                      },
                      childCount: state.packages.length,
                    ),
                  ),
                ),

                if (state.packages.isEmpty)
                  const SliverToBoxAdapter(
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.all(48),
                        child: Text(
                          'Chưa có gói VIP nào.\nVui lòng quay lại sau.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    ),
                  ),

                const SliverToBoxAdapter(child: SizedBox(height: 32)),
              ],
            ),
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _CurrentSubscriptionBanner extends StatelessWidget {
  final SubscriptionModel sub;
  const _CurrentSubscriptionBanner({required this.sub});

  @override
  Widget build(BuildContext context) {
    final color = sub.isExpiringSoon ? Colors.orange : Colors.green;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        border: Border.all(color: color.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.verified, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Gói hiện tại: ${sub.packageName}',
                  style: TextStyle(fontWeight: FontWeight.bold, color: color),
                ),
                if (sub.endAt != null)
                  Text(
                    sub.isExpiringSoon
                        ? 'Sắp hết hạn: ${_formatDate(sub.endAt!)}'
                        : 'Hết hạn: ${_formatDate(sub.endAt!)}',
                    style: TextStyle(fontSize: 12, color: color.withValues(alpha: 0.8)),
                  )
                else
                  Text(
                    'Không giới hạn thời gian',
                    style: TextStyle(fontSize: 12, color: color.withValues(alpha: 0.8)),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}

class _PackageCard extends StatelessWidget {
  final PackageModel package;
  final bool isRecommended;
  final VoidCallback onBuy;

  const _PackageCard({
    required this.package,
    required this.isRecommended,
    required this.onBuy,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: isRecommended
            ? colorScheme.primaryContainer
            : colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isRecommended ? colorScheme.primary : Colors.transparent,
          width: 2,
        ),
        boxShadow: isRecommended
            ? [
                BoxShadow(
                  color: colorScheme.primary.withValues(alpha: 0.2),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (isRecommended)
                        Container(
                          margin: const EdgeInsets.only(bottom: 6),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.primary,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '⭐ Phổ biến nhất',
                            style: TextStyle(
                              color: colorScheme.onPrimary,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      Text(
                        package.name,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        package.durationDisplay,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      package.priceDisplay,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                      ),
                    ),
                    if (package.durationInDays != null)
                      Text(
                        '/${package.durationDisplay}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurface.withOpacity(0.5),
                        ),
                      ),
                  ],
                ),
              ],
            ),
            if (package.features.isNotEmpty) ...[
              const SizedBox(height: 16),
              ...package.features.map(
                (f) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle,
                          size: 16, color: colorScheme.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(f, style: theme.textTheme.bodySmall),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onBuy,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isRecommended
                      ? colorScheme.primary
                      : colorScheme.secondary,
                  foregroundColor: isRecommended
                      ? colorScheme.onPrimary
                      : colorScheme.onSecondary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: isRecommended ? 4 : 0,
                ),
                child: Text(
                  'Mua ngay — ${package.priceDisplay}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
