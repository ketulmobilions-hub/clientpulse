import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:clientpulse/shared/models/auth_user.dart';
import 'package:clientpulse/shared/providers/auth_notifier.dart';
import 'package:clientpulse/shared/providers/auth_state_provider.dart';
import 'package:clientpulse/core/router/app_router.dart';

// Stable notifier: resolves immediately without touching SharedPreferences.
// Used in router tests so pumpAndSettle is not blocked by a loading spinner.
class _StableAuthNotifier extends AuthNotifier {
  @override
  Future<AuthUser?> build() async => null;
}

/// Creates a [ProviderContainer] with [isAuthenticatedProvider] overridden.
/// Also overrides [authNotifierProvider] with a stable (non-loading) notifier
/// so that screens watching it do not spin forever during pumpAndSettle.
/// Caller MUST call [ProviderContainer.dispose] in tearDown to avoid leaks.
ProviderContainer containerWithAuth(bool authenticated) {
  return ProviderContainer(
    overrides: [
      isAuthenticatedProvider.overrideWith((_) async => authenticated),
      authNotifierProvider.overrideWith(() => _StableAuthNotifier()),
    ],
  );
}

String currentPath(ProviderContainer container) {
  final router = container.read(routerProvider);
  return router.routerDelegate.currentConfiguration.uri.path;
}
