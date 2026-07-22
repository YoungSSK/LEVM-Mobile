import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/vocabulary_api.dart';
import '../models/xp_models.dart';
import 'vocabulary_providers.dart';

class XpStreakState {
  final XpInfoModel? xpInfo;
  final StreakInfoModel? streakInfo;
  final bool isLoading;
  final String? error;

  const XpStreakState({
    this.xpInfo,
    this.streakInfo,
    this.isLoading = false,
    this.error,
  });

  XpStreakState copyWith({
    XpInfoModel? xpInfo,
    StreakInfoModel? streakInfo,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return XpStreakState(
      xpInfo: xpInfo ?? this.xpInfo,
      streakInfo: streakInfo ?? this.streakInfo,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class XpStreakNotifier extends Notifier<XpStreakState> {
  @override
  XpStreakState build() => const XpStreakState();

  VocabularyApi get _api => ref.read(vocabularyApiProvider);

  Future<void> loadXpAndStreak() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final results = await Future.wait([
        _api.getXpInfo(),
        _api.getStreakInfo(),
      ]);

      state = state.copyWith(
        xpInfo: results[0] as XpInfoModel,
        streakInfo: results[1] as StreakInfoModel,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> refresh() async {
    await loadXpAndStreak();
  }

  Future<bool> useStreakFreeze() async {
    try {
      await _api.useStreakFreeze();
      await loadXpAndStreak();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  void updateWithNewXp(int addedXp) {
    if (state.xpInfo == null) return;

    final currentXp = state.xpInfo!.totalXp;
    final newXp = currentXp + addedXp;
    final newLevel = (newXp ~/ state.xpInfo!.xpPerLevel) + 1;
    final currentLevel = state.xpInfo!.currentLevel;

    final newXpInfo = XpInfoModel(
      totalXp: newXp,
      currentLevel: newLevel,
      xpInLevel: newXp % state.xpInfo!.xpPerLevel,
      xpToNextLevel: state.xpInfo!.xpPerLevel - (newXp % state.xpInfo!.xpPerLevel),
      progressInLevel: (newXp % state.xpInfo!.xpPerLevel) / state.xpInfo!.xpPerLevel,
      xpPerLevel: state.xpInfo!.xpPerLevel,
    );

    state = state.copyWith(xpInfo: newXpInfo);
  }

  void updateWithNewStreak(int newStreak) {
    if (state.streakInfo == null) return;

    final newStreakInfo = StreakInfoModel(
      currentStreak: newStreak,
      longestStreak: newStreak > state.streakInfo!.longestStreak
          ? newStreak
          : state.streakInfo!.longestStreak,
      freezeCount: state.streakInfo!.freezeCount,
      timezone: state.streakInfo!.timezone,
      studiedToday: true,
      streakAtRisk: false,
      lastActivityDate: DateTime.now(),
    );

    state = state.copyWith(streakInfo: newStreakInfo);
  }
}

final xpStreakProvider =
    NotifierProvider<XpStreakNotifier, XpStreakState>(
  XpStreakNotifier.new,
);
