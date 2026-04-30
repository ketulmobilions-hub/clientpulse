import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/auth_user.dart';
import '../services/auth_service.dart';
import 'auth_service_provider.dart';

part 'auth_notifier.g.dart';

@Riverpod(keepAlive: true)
class AuthNotifier extends _$AuthNotifier {
  @override
  Future<AuthUser?> build() async {
    final authSvc = await ref.read(authServiceProvider.future);
    final token = authSvc.getToken();
    if (token == null || AuthService.isTokenExpired(token)) return null;
    return authSvc.getUser();
  }

  Future<AuthUser> login(String email, String password) async {
    if (state.isLoading) throw StateError('Login already in progress');
    if (state.hasError) throw StateError('Auth service unavailable');
    // guard + AsyncLoading are synchronous — no concurrent caller can slip through.
    state = const AsyncLoading();
    try {
      final authSvc = await ref.read(authServiceProvider.future);
      final user = await authSvc.login(email, password);
      state = AsyncData(user);
      return user;
    } catch (e, st) {
      // Reset to unauthenticated rather than AsyncError — prevents router
      // from flashing /loading on every wrong-password attempt.
      state = const AsyncData(null);
      Error.throwWithStackTrace(e, st);
    }
    throw StateError('unreachable');
  }

  Future<void> register(
    String email,
    String password,
    String name,
    String workspaceName,
  ) async {
    if (state.isLoading) throw StateError('Auth already in progress');
    if (state.hasError) throw StateError('Auth service unavailable');
    state = const AsyncLoading();
    // authSvc is late-final: Error.throwWithStackTrace (Never) in catch guarantees
    // it is assigned before the second try block is reached.
    late final AuthService authSvc;
    try {
      authSvc = await ref.read(authServiceProvider.future);
      await authSvc.register(email, password, name, workspaceName);
    } catch (e, st) {
      state = const AsyncData(null);
      Error.throwWithStackTrace(e, st);
    }
    // Register succeeded — auto-login. Failure here is a distinct error: the
    // account was created but the session could not be established.
    try {
      final user = await authSvc.login(email, password);
      state = AsyncData(user);
    } catch (e, st) {
      if (kDebugMode) debugPrint('Auto-login after register failed: $e');
      state = const AsyncData(null);
      Error.throwWithStackTrace(
        const AuthServiceException('Account created. Please sign in.'),
        st,
      );
    }
  }

  Future<void> logout() async {
    final authSvc = await ref.read(authServiceProvider.future);
    await authSvc.logout();
    state = const AsyncData(null);
  }
}
