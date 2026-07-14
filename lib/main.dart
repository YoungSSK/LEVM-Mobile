import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/providers/auth_notifier.dart';

/// Shared global router instance.
final _router = AppRouter.build();

void main() {
  runApp(
    ProviderScope(
      child: const LEVMApp(),
    ),
  );
}

class LEVMApp extends ConsumerStatefulWidget {
  const LEVMApp({super.key});

  @override
  ConsumerState<LEVMApp> createState() => _LEVMAppState();
}

class _LEVMAppState extends ConsumerState<LEVMApp> {
  ProviderSubscription<AuthState>? _authSub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Bootstrap auth state and wire the router refresh listener.
      ref.read(authNotifierProvider.notifier).bootstrap();
      _authSub = ref.listenManual<AuthState>(
        authNotifierProvider,
        (previous, next) {
          // Notify the router so its refresh-listenable re-runs redirect()
          // (e.g. when the user logs out we want to land on /login).
          RefreshBridge.instance.notifyRouter();
        },
      );
    });
  }

  @override
  void dispose() {
    _authSub?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: "LEVM",
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      routerConfig: _router,
    );
  }
}
