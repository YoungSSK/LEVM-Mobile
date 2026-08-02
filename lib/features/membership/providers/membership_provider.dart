import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/api/membership_api_service.dart';
import '../domain/models/membership_models.dart';

// ── State ─────────────────────────────────────────────────────────────────────

class MembershipState {
  final List<PackageModel> packages;
  final SubscriptionModel? currentSubscription;
  final bool isLoading;
  final String? error;

  const MembershipState({
    this.packages = const [],
    this.currentSubscription,
    this.isLoading = false,
    this.error,
  });

  MembershipState copyWith({
    List<PackageModel>? packages,
    SubscriptionModel? currentSubscription,
    bool clearSubscription = false,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return MembershipState(
      packages: packages ?? this.packages,
      currentSubscription: clearSubscription ? null : (currentSubscription ?? this.currentSubscription),
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

// ── Notifier ──────────────────────────────────────────────────────────────────

class MembershipNotifier extends Notifier<MembershipState> {
  final _api = MembershipApiService();

  @override
  MembershipState build() => const MembershipState();

  /// Load cả danh sách gói và subscription của user
  Future<void> loadAll() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final packages = await _api.getPackages();
      final subData = await _api.getMySubscription();

      SubscriptionModel? subscription;
      final subJson = subData['subscription'] as Map<String, dynamic>?;
      if (subJson != null) {
        subscription = SubscriptionModel.fromJson(subJson);
      }

      state = state.copyWith(
        packages: packages,
        currentSubscription: subscription,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Refresh sau khi thanh toán xong (VNPay deep link return)
  Future<void> refreshAfterPayment() async {
    try {
      final subData = await _api.refreshSubscription();
      final subJson = subData['subscription'] as Map<String, dynamic>?;
      if (subJson != null) {
        final subscription = SubscriptionModel.fromJson(subJson);
        state = state.copyWith(currentSubscription: subscription);
      }
    } catch (_) {}
  }

  /// Tạo đơn thanh toán — trả về URL để mở WebView
  Future<String?> checkout(String packageId) async {
    return _api.checkout(packageId);
  }
}

// ── Provider ──────────────────────────────────────────────────────────────────

final membershipNotifierProvider =
    NotifierProvider<MembershipNotifier, MembershipState>(MembershipNotifier.new);

final membershipApiProvider = Provider<MembershipApiService>(
  (ref) => MembershipApiService(),
);
