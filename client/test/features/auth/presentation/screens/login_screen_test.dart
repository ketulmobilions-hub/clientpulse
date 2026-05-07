import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:clientpulse/core/router/route_names.dart';
import 'package:clientpulse/features/auth/presentation/screens/login_screen.dart';
import 'package:clientpulse/shared/models/auth_user.dart';
import 'package:clientpulse/shared/providers/auth_notifier.dart';
import 'package:clientpulse/shared/services/auth_service.dart';

class _FakeAuthNotifier extends AuthNotifier {
  AuthServiceException? errorToThrow;
  String? capturedEmail;
  String? capturedPassword;
  bool loginCalled = false;
  int loginCallCount = 0;

  @override
  Future<AuthUser?> build() async => null;

  @override
  Future<AuthUser> login(String email, String password) async {
    loginCalled = true;
    loginCallCount += 1;
    capturedEmail = email;
    capturedPassword = password;
    if (errorToThrow != null) throw errorToThrow!;
    const user = AuthUser(
      id: 'u1',
      email: 'test@example.com',
      name: 'Tester',
      role: 'admin',
      workspaceId: 'ws-1',
    );
    state = const AsyncData(user);
    return user;
  }
}

/// Login that does NOT resolve until [completer] is completed by the test.
/// Used to observe the `isLoading: true` state, which the synchronous fake skips entirely.
class _SlowFakeAuthNotifier extends AuthNotifier {
  final completer = Completer<AuthUser>();

  @override
  Future<AuthUser?> build() async => null;

  @override
  Future<AuthUser> login(String email, String password) async {
    state = const AsyncLoading();
    final user = await completer.future;
    state = AsyncData(user);
    return user;
  }
}

Widget _wrap(AuthNotifier notifier) {
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/login',
        name: RouteNames.login,
        builder: (_, __) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        name: RouteNames.register,
        builder: (_, __) => const Scaffold(body: Text('Register')),
      ),
      GoRoute(
        path: '/dashboard',
        name: RouteNames.dashboard,
        builder: (_, __) => const Scaffold(body: Text('Dashboard')),
      ),
    ],
    initialLocation: '/login',
  );

  return ProviderScope(
    overrides: [
      authNotifierProvider.overrideWith(() => notifier),
    ],
    child: MaterialApp.router(routerConfig: router),
  );
}

void main() {
  group('LoginScreen — form validation', () {
    late _FakeAuthNotifier notifier;

    setUp(() => notifier = _FakeAuthNotifier());

    testWidgets('renders email, password fields and sign-in button', (tester) async {
      await tester.pumpWidget(_wrap(notifier));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('email_field')), findsOneWidget);
      expect(find.byKey(const Key('password_field')), findsOneWidget);
      expect(find.byKey(const Key('login_button')), findsOneWidget);
    });

    testWidgets('shows required errors when form submitted empty', (tester) async {
      await tester.pumpWidget(_wrap(notifier));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('login_button')));
      await tester.pump();

      expect(find.text('Email is required'), findsOneWidget);
      expect(find.text('Password is required'), findsOneWidget);
    });

    testWidgets('shows error for invalid email — no @ symbol', (tester) async {
      await tester.pumpWidget(_wrap(notifier));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('email_field')), 'notanemail');
      await tester.tap(find.byKey(const Key('login_button')));
      await tester.pump();

      expect(find.text('Enter a valid email address'), findsOneWidget);
    });

    testWidgets('shows error for invalid email — @ at start', (tester) async {
      await tester.pumpWidget(_wrap(notifier));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('email_field')), '@domain.com');
      await tester.tap(find.byKey(const Key('login_button')));
      await tester.pump();

      expect(find.text('Enter a valid email address'), findsOneWidget);
    });

    testWidgets('shows error for invalid email — domain ends with dot', (tester) async {
      await tester.pumpWidget(_wrap(notifier));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('email_field')), 'a@b.');
      await tester.tap(find.byKey(const Key('login_button')));
      await tester.pump();

      expect(find.text('Enter a valid email address'), findsOneWidget);
    });

    testWidgets('does NOT reject short password on login screen', (tester) async {
      await tester.pumpWidget(_wrap(notifier));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('email_field')), 'a@b.com');
      await tester.enterText(find.byKey(const Key('password_field')), 'short');
      await tester.tap(find.byKey(const Key('login_button')));
      await tester.pumpAndSettle();

      // Login accepts any non-empty password — length check belongs on register only.
      expect(find.text('Password must be at least 8 characters'), findsNothing);
      expect(notifier.loginCalled, isTrue);
    });

    testWidgets('shows password visibility toggle', (tester) async {
      await tester.pumpWidget(_wrap(notifier));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);
    });

    testWidgets('shows register link', (tester) async {
      await tester.pumpWidget(_wrap(notifier));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('register_link')), findsOneWidget);
    });
  });

  group('LoginScreen — submit behavior', () {
    late _FakeAuthNotifier notifier;

    setUp(() => notifier = _FakeAuthNotifier());

    testWidgets('calls login with trimmed email and exact password on valid submit',
        (tester) async {
      await tester.pumpWidget(_wrap(notifier));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('email_field')), '  test@example.com  ');
      await tester.enterText(find.byKey(const Key('password_field')), 'password123');
      await tester.tap(find.byKey(const Key('login_button')));
      await tester.pumpAndSettle();

      expect(notifier.loginCalled, isTrue);
      expect(notifier.capturedEmail, 'test@example.com');
      expect(notifier.capturedPassword, 'password123');
    });

    testWidgets('shows inline error banner when login throws AuthServiceException', (tester) async {
      notifier.errorToThrow = const AuthServiceException('Invalid credentials');

      await tester.pumpWidget(_wrap(notifier));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('email_field')), 'a@b.com');
      await tester.enterText(find.byKey(const Key('password_field')), 'password123');
      await tester.tap(find.byKey(const Key('login_button')));
      await tester.pumpAndSettle();

      expect(find.text('Invalid credentials'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);
    });

    testWidgets('clears inline error when user edits email field', (tester) async {
      notifier.errorToThrow = const AuthServiceException('Invalid credentials');

      await tester.pumpWidget(_wrap(notifier));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('email_field')), 'a@b.com');
      await tester.enterText(find.byKey(const Key('password_field')), 'password123');
      await tester.tap(find.byKey(const Key('login_button')));
      await tester.pumpAndSettle();
      expect(find.text('Invalid credentials'), findsOneWidget);

      // Editing the field should dismiss the inline error.
      // pumpAndSettle (not pump) — clear is dispatched via addPostFrameCallback,
      // which needs an extra frame to flush the setState.
      await tester.enterText(find.byKey(const Key('email_field')), 'b@c.com');
      await tester.pumpAndSettle();
      expect(find.text('Invalid credentials'), findsNothing);
    });

    testWidgets('forgot-password link shows honest reset-coming-soon SnackBar (no fake email)',
        (tester) async {
      await tester.pumpWidget(_wrap(notifier));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('forgot_password_link')));
      await tester.pump();

      expect(find.text('Password reset is coming soon.'), findsOneWidget);
      // Honest-copy guard: the SnackBar must not point to a non-functional support email.
      expect(find.textContaining('@'), findsNothing);
    });

    testWidgets('CTA reads "Sign in to workspace" instead of generic "Sign In"', (tester) async {
      await tester.pumpWidget(_wrap(notifier));
      await tester.pumpAndSettle();

      expect(find.text('Sign in to workspace'), findsOneWidget);
    });

    testWidgets('clears inline error when user edits PASSWORD field (mirrors email path)',
        (tester) async {
      notifier.errorToThrow = const AuthServiceException('Invalid credentials');

      await tester.pumpWidget(_wrap(notifier));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('email_field')), 'a@b.com');
      await tester.enterText(find.byKey(const Key('password_field')), 'password123');
      await tester.tap(find.byKey(const Key('login_button')));
      await tester.pumpAndSettle();
      expect(find.text('Invalid credentials'), findsOneWidget);

      // Editing the password should also dismiss the inline error.
      await tester.enterText(find.byKey(const Key('password_field')), 'differentpw');
      await tester.pumpAndSettle();
      expect(find.text('Invalid credentials'), findsNothing);
    });

    testWidgets('two consecutive failed logins replace the banner (no stacking, no stuck-null)',
        (tester) async {
      notifier.errorToThrow = const AuthServiceException('Invalid credentials');

      await tester.pumpWidget(_wrap(notifier));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('email_field')), 'a@b.com');
      await tester.enterText(find.byKey(const Key('password_field')), 'password123');
      await tester.tap(find.byKey(const Key('login_button')));
      await tester.pumpAndSettle();
      expect(find.text('Invalid credentials'), findsOneWidget);

      // Second attempt with a different error message — banner must replace, not duplicate.
      notifier.errorToThrow = const AuthServiceException('Account is locked');
      await tester.tap(find.byKey(const Key('login_button')));
      await tester.pumpAndSettle();

      expect(find.text('Invalid credentials'), findsNothing);
      expect(find.text('Account is locked'), findsOneWidget);
    });
  });

  group('LoginScreen — loading state', () {
    testWidgets('disables login button + forgot-password link while isLoading', (tester) async {
      final slow = _SlowFakeAuthNotifier();

      await tester.pumpWidget(_wrap(slow));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('email_field')), 'a@b.com');
      await tester.enterText(find.byKey(const Key('password_field')), 'password123');
      await tester.tap(find.byKey(const Key('login_button')));
      // pump (not settle) so the slow login stays pending and isLoading == true.
      await tester.pump();

      final button = tester.widget<FilledButton>(find.byKey(const Key('login_button')));
      expect(button.onPressed, isNull, reason: 'login button must be disabled while loading');

      final forgot = tester.widget<TextButton>(find.byKey(const Key('forgot_password_link')));
      expect(forgot.onPressed, isNull,
          reason: 'forgot-password link must be disabled while loading');

      // Clean up the pending future so the test runner does not complain about leaks.
      slow.completer.complete(const AuthUser(
        id: 'u1',
        email: 'a@b.com',
        name: 'T',
        role: 'admin',
        workspaceId: 'ws-1',
      ));
      await tester.pumpAndSettle();
    });
  });

  group('LoginScreen — prefillEmail', () {
    Widget wrapWithPrefill(_FakeAuthNotifier notifier, String? prefill) {
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/login',
            name: RouteNames.login,
            builder: (_, __) => LoginScreen(prefillEmail: prefill),
          ),
          GoRoute(
            path: '/register',
            name: RouteNames.register,
            builder: (_, __) => const Scaffold(body: Text('R')),
          ),
          GoRoute(
            path: '/dashboard',
            name: RouteNames.dashboard,
            builder: (_, __) => const Scaffold(body: Text('D')),
          ),
        ],
        initialLocation: '/login',
      );
      return ProviderScope(
        overrides: [authNotifierProvider.overrideWith(() => notifier)],
        child: MaterialApp.router(routerConfig: router),
      );
    }

    testWidgets('populates email field when prefill is a valid string', (tester) async {
      final notifier = _FakeAuthNotifier();
      await tester.pumpWidget(wrapWithPrefill(notifier, 'preset@example.com'));
      await tester.pumpAndSettle();

      final field = tester.widget<TextField>(
        find.descendant(
          of: find.byKey(const Key('email_field')),
          matching: find.byType(TextField),
        ),
      );
      expect(field.controller!.text, 'preset@example.com');
    });

    testWidgets('null prefill leaves email field empty', (tester) async {
      final notifier = _FakeAuthNotifier();
      await tester.pumpWidget(wrapWithPrefill(notifier, null));
      await tester.pumpAndSettle();

      final field = tester.widget<TextField>(
        find.descendant(
          of: find.byKey(const Key('email_field')),
          matching: find.byType(TextField),
        ),
      );
      expect(field.controller!.text, '');
    });

    testWidgets('empty prefill leaves email field empty', (tester) async {
      final notifier = _FakeAuthNotifier();
      await tester.pumpWidget(wrapWithPrefill(notifier, ''));
      await tester.pumpAndSettle();

      final field = tester.widget<TextField>(
        find.descendant(
          of: find.byKey(const Key('email_field')),
          matching: find.byType(TextField),
        ),
      );
      expect(field.controller!.text, '');
    });

    testWidgets('over-length prefill is rejected (DoS guard)', (tester) async {
      final notifier = _FakeAuthNotifier();
      final huge = 'a' * 1000 + '@example.com';
      await tester.pumpWidget(wrapWithPrefill(notifier, huge));
      await tester.pumpAndSettle();

      final field = tester.widget<TextField>(
        find.descendant(
          of: find.byKey(const Key('email_field')),
          matching: find.byType(TextField),
        ),
      );
      expect(field.controller!.text, '');
    });

    testWidgets('prefilled email remains editable', (tester) async {
      final notifier = _FakeAuthNotifier();
      await tester.pumpWidget(wrapWithPrefill(notifier, 'preset@example.com'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('email_field')), 'changed@example.com');
      await tester.pump();

      final field = tester.widget<TextField>(
        find.descendant(
          of: find.byKey(const Key('email_field')),
          matching: find.byType(TextField),
        ),
      );
      expect(field.controller!.text, 'changed@example.com');
    });

    testWidgets('/login?email= route param feeds LoginScreen prefillEmail', (tester) async {
      final notifier = _FakeAuthNotifier();
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/login',
            name: RouteNames.login,
            builder: (_, state) =>
                LoginScreen(prefillEmail: state.uri.queryParameters['email']),
          ),
        ],
        initialLocation: '/login?email=route%2Bparam%40example.com',
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [authNotifierProvider.overrideWith(() => notifier)],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();

      final field = tester.widget<TextField>(
        find.descendant(
          of: find.byKey(const Key('email_field')),
          matching: find.byType(TextField),
        ),
      );
      expect(field.controller!.text, 'route+param@example.com');
    });
  });
}
