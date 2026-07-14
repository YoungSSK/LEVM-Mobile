import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/storage_keys.dart';
import '../../../core/services/secure_storage_service.dart';
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
    final api = ref.read(authApiProvider);
    final LoginResponse res = await api.login(email: email, password: password);
    await AuthApi.saveTokens(
      accessToken: res.accessToken,
      refreshToken: res.refreshToken,
    );
    await SecureStorageService.write(key: "role", value: res.role);
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
    await SecureStorageService.delete("role");
    state = state.copyWith(
      authenticated: false,
      clearRole: true,
    );
  }

  /// Hard-reset when the refresh-token interceptor fails (tokens wiped).
  void forceLoggedOut() {
    state = state.copyWith(authenticated: false, clearRole: true);
  }
}

final authNotifierProvider =
    NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);
