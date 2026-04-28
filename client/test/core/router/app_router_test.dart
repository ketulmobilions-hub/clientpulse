import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:clientpulse/shared/providers/auth_state_provider.dart';
import 'package:clientpulse/core/router/app_router.dart';
import '../../helpers/router_test_helpers.dart';

void main() {
  group('unauthenticated', () {
    late ProviderContainer container;

    setUp(() async {
      container = containerWithAuth(false);
      await container.read(isAuthenticatedProvider.future);
    });

    tearDown(() => container.dispose());

    testWidgets('/dashboard redirects to /login', (tester) async {
      final router = container.read(routerProvider);
      // router.dispose() is handled by ref.onDispose when container is disposed.

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle(); // settles to /login from /loading

      router.go('/dashboard');
      await tester.pumpAndSettle();

      expect(currentPath(container), '/login');
    });

    testWidgets('/login accessible without auth', (tester) async {
      final router = container.read(routerProvider);
      // router.dispose() is handled by ref.onDispose when container is disposed.

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();

      router.go('/login');
      await tester.pumpAndSettle();

      expect(currentPath(container), '/login');
    });

    testWidgets('/p/:token accessible without auth', (tester) async {
      final router = container.read(routerProvider);
      // router.dispose() is handled by ref.onDispose when container is disposed.

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();

      router.go('/p/abc123');
      await tester.pumpAndSettle();

      expect(currentPath(container), '/p/abc123');
    });

    testWidgets('/p/ with whitespace-only token redirects to /login', (tester) async {
      final router = container.read(routerProvider);
      // router.dispose() is handled by ref.onDispose when container is disposed.

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();

      // URL-encoded space → GoRouter decodes to /p/ , trim → empty → /login
      router.go('/p/%20');
      await tester.pumpAndSettle();

      expect(currentPath(container), '/login');
    });
  });

  group('authenticated', () {
    late ProviderContainer container;

    setUp(() async {
      container = containerWithAuth(true);
      await container.read(isAuthenticatedProvider.future);
    });

    tearDown(() => container.dispose());

    testWidgets('/login redirects to /dashboard', (tester) async {
      final router = container.read(routerProvider);
      // router.dispose() is handled by ref.onDispose when container is disposed.

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle(); // settles to /dashboard from /loading

      router.go('/login');
      await tester.pumpAndSettle();

      expect(currentPath(container), '/dashboard');
    });

    testWidgets('/dashboard accessible', (tester) async {
      final router = container.read(routerProvider);
      // router.dispose() is handled by ref.onDispose when container is disposed.

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();

      router.go('/dashboard');
      await tester.pumpAndSettle();

      expect(currentPath(container), '/dashboard');
    });

    testWidgets('/p/:token accessible when authenticated', (tester) async {
      final router = container.read(routerProvider);
      // router.dispose() is handled by ref.onDispose when container is disposed.

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();

      router.go('/p/mytoken');
      await tester.pumpAndSettle();

      expect(currentPath(container), '/p/mytoken');
    });
  });

  group('loading state', () {
    testWidgets('shows /loading while auth unresolved, then redirects to /login', (tester) async {
      final completer = Completer<bool>();
      final container = ProviderContainer(
        overrides: [
          isAuthenticatedProvider.overrideWith((_) => completer.future),
        ],
      );
      addTearDown(container.dispose);

      final router = container.read(routerProvider);
      // router.dispose() is handled by ref.onDispose when container is disposed.

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pump(); // do NOT settle — auth is still pending

      expect(currentPath(container), '/loading');

      completer.complete(false);
      await tester.pumpAndSettle();

      expect(currentPath(container), '/login');
    });

    testWidgets('shows /loading then redirects to /dashboard when authenticated', (tester) async {
      final completer = Completer<bool>();
      final container = ProviderContainer(
        overrides: [
          isAuthenticatedProvider.overrideWith((_) => completer.future),
        ],
      );
      addTearDown(container.dispose);

      final router = container.read(routerProvider);
      // router.dispose() is handled by ref.onDispose when container is disposed.

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pump();

      expect(currentPath(container), '/loading');

      completer.complete(true);
      await tester.pumpAndSettle();

      expect(currentPath(container), '/dashboard');
    });
  });
}
