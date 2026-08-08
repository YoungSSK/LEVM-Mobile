import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/storage_keys.dart';
import '../../../core/services/secure_storage_service.dart';
import '../../grammar/providers/grammar_providers.dart';
import '../../listening/presentation/providers/listening_provider.dart';
import '../../membership/providers/membership_provider.dart';
import '../../occupation/providers/occupation_providers.dart';
import '../../profile/providers/profile_providers.dart';
import '../../reading/presentation/providers/reading_providers.dart';
import '../../vocabulary/providers/study_session_provider.dart';
import '../../vocabulary/providers/vocabulary_providers.dart';
import '../../vocabulary/providers/xp_streak_provider.dart';
import '../models/auth_models.dart';
import '../services/auth_api.dart';
import 'auth_providers.dart';

/// Session state exposed to the UI.
class AuthState {
  final bool initialized;
  final bool authenticated;
  final String? role;

  const AuthState({
    this.initialized = false,
    this.authenticated = false,
    this.role,
  });

  AuthState copyWith({
    bool? initialized,
    bool? authenticated,
    String? role,
    bool clearRole = false,
  }) {
    return AuthState(
      initialized: initialized ?? this.initialized,
      authenticated: authenticated ?? this.authenticated,
      role: clearRole ? null : (role ?? this.role),
    );
  }
}

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() => const AuthState();

  /// Invalidates all user-dependent Riverpod providers so no user profile,
  /// XP/streak, subscription, or learning progress leaks across sessions.
  void _clearUserScopedState() {
    ref.invalidate(currentUserProvider);
    ref.invalidate(xpStreakProvider);
    ref.invalidate(membershipNotifierProvider);
    ref.invalidate(vocabularyTopicsProvider);
    ref.invalidate(grammarTopicsProvider);
    ref.invalidate(allGrammarLessonsProvider);
    ref.invalidate(readingCategoriesProvider);
    ref.invalidate(readingPassagesProvider);
    ref.invalidate(listeningSetsProvider);
    ref.invalidate(studySessionProvider);
    ref.invalidate(listeningSessionProvider);
    ref.invalidate(quizNotifierProvider);
    ref.invalidate(selectedCategoryProvider);
    ref.invalidate(selectedCefrLevelProvider);
    ref.invalidate(readingSearchQueryProvider);
    ref.invalidate(occupationCategoriesProvider);
  }

  /// Called once at app startup to figure out if we have stored tokens.
  Future<void> bootstrap() async {
    final access = await SecureStorageService.read(StorageKeys.accessToken);
    final role = await SecureStorageService.read("role");
    state = AuthState(
      initialized: true,
      authenticated: access != null && access.isNotEmpty,
      role: role,
    );
  }

  Future<void> login({required String email, required String password}) async {
    _clearUserScopedState();
    final api = ref.read(authApiProvider);
    final LoginResponse res = await api.login(email: email, password: password);
    await AuthApi.saveTokens(
      accessToken: res.accessToken,
      refreshToken: res.refreshToken,
    );
    await SecureStorageService.write(key: "role", value: res.role);
    _clearUserScopedState();
    state = state.copyWith(
      initialized: true,
      authenticated: true,
      role: res.role,
    );
  }

  Future<void> register({
    required String username,
    required String email,
    required String password,
  }) async {
    final api = ref.read(authApiProvider);
    await api.register(username: username, email: email, password: password);
    // Note: backend does NOT auto-login on register — caller navigates to /login.
  }

  Future<void> logout() async {
    final api = ref.read(authApiProvider);
    await api.logout();
    await AuthApi.clearTokens();
    _clearUserScopedState();
    state = state.copyWith(
      authenticated: false,
      clearRole: true,
    );
  }

  /// Hard-reset when the refresh-token interceptor fails (tokens wiped).
  void forceLoggedOut() {
    AuthApi.clearTokens();
    _clearUserScopedState();
    state = state.copyWith(authenticated: false, clearRole: true);
  }
}

final authNotifierProvider =
    NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);

