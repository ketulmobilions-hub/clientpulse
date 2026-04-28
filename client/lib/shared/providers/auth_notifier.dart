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
    state = const AsyncLoading();
    final authSvc = await ref.read(authServiceProvider.future);
    try {
      final user = await authSvc.login(email, password);
      state = AsyncData(user);
      return user;
    } catch (e, st) {
      // Reset to unauthenticated rather than AsyncError — prevents router
      // from flashing /loading on every wrong-password attempt.
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
