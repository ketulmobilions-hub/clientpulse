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

  /// Returns the LoginOutcome so the caller (login screen) can route to either
  /// the dashboard (LoginSuccess) or verify-pending screen (LoginRequiresVerification).
  Future<LoginOutcome> login(String email, String password) async {
    if (state.isLoading) throw StateError('Login already in progress');
    if (state.hasError) throw StateError('Auth service unavailable');
    state = const AsyncLoading();
    try {
      final authSvc = await ref.read(authServiceProvider.future);
      final outcome = await authSvc.login(email, password);
      switch (outcome) {
        case LoginSuccess(:final user):
          state = AsyncData(user);
        case LoginRequiresVerification():
          // Stay unauthenticated; caller routes to verify-pending screen.
          state = const AsyncData(null);
      }
      return outcome;
    } catch (e, st) {
      // Reset to unauthenticated rather than AsyncError — prevents router
      // from flashing /loading on every wrong-password attempt.
      state = const AsyncData(null);
      Error.throwWithStackTrace(e, st);
    }
  }

  /// Registers, then leaves the user unauthenticated. Backend always issues a
  /// verification token now, so auto-login would immediately fail at the
  /// requires_verification gate. Caller routes to verify-pending screen.
  Future<RegisterOutcome> register(
    String email,
    String password,
    String name,
    String workspaceName,
  ) async {
    if (state.isLoading) throw StateError('Auth already in progress');
    if (state.hasError) throw StateError('Auth service unavailable');
    state = const AsyncLoading();
    try {
      final authSvc = await ref.read(authServiceProvider.future);
      final outcome = await authSvc.register(email, password, name, workspaceName);
      state = const AsyncData(null);
      return outcome;
    } catch (e, st) {
      state = const AsyncData(null);
      Error.throwWithStackTrace(e, st);
    }
  }

  Future<void> logout() async {
    final authSvc = await ref.read(authServiceProvider.future);
    await authSvc.logout();
    state = const AsyncData(null);
  }
}
