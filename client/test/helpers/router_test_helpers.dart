import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:clientpulse/shared/providers/auth_state_provider.dart';
import 'package:clientpulse/core/router/app_router.dart';

/// Creates a [ProviderContainer] with [isAuthenticatedProvider] overridden.
/// Caller MUST call [ProviderContainer.dispose] in tearDown to avoid leaks.
ProviderContainer containerWithAuth(bool authenticated) {
  return ProviderContainer(
    overrides: [
      isAuthenticatedProvider.overrideWith((_) async => authenticated),
    ],
  );
}

String currentPath(ProviderContainer container) {
  final router = container.read(routerProvider);
  return router.routerDelegate.currentConfiguration.uri.path;
}
