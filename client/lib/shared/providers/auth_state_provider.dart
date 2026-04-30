import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/auth_user.dart';
import 'auth_notifier.dart';

part 'auth_state_provider.g.dart';

// Tests can override isAuthenticatedProvider directly (router tests),
// or override authServiceProvider to drive state through the full stack.
@Riverpod(keepAlive: true)
Future<bool> isAuthenticated(IsAuthenticatedRef ref) async {
  final user = await ref.watch(authNotifierProvider.future);
  return user != null;
}

@Riverpod(keepAlive: true)
Future<AuthUser?> currentUser(CurrentUserRef ref) async {
  return ref.watch(authNotifierProvider.future);
}
