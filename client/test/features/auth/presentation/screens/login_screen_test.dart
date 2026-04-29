import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:clientpulse/features/auth/presentation/screens/login_screen.dart';
import 'package:clientpulse/shared/models/auth_user.dart';
import 'package:clientpulse/shared/providers/auth_notifier.dart';
import 'package:clientpulse/shared/services/auth_service.dart';

class _FakeAuthNotifier extends AuthNotifier {
  AuthServiceException? errorToThrow;
  String? capturedEmail;
  String? capturedPassword;
  bool loginCalled = false;

  @override
  Future<AuthUser?> build() async => null;

  @override
  Future<AuthUser> login(String email, String password) async {
    loginCalled = true;
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

Widget _wrap(_FakeAuthNotifier notifier) {
  final router = GoRouter(
    routes: [
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, __) => const Scaffold(body: Text('Register'))),
      GoRoute(path: '/dashboard', builder: (_, __) => const Scaffold(body: Text('Dashboard'))),
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

    testWidgets('shows SnackBar when login throws AuthServiceException', (tester) async {
      notifier.errorToThrow = const AuthServiceException('Invalid credentials');

      await tester.pumpWidget(_wrap(notifier));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('email_field')), 'a@b.com');
      await tester.enterText(find.byKey(const Key('password_field')), 'password123');
      await tester.tap(find.byKey(const Key('login_button')));
      await tester.pumpAndSettle();

      expect(find.text('Invalid credentials'), findsOneWidget);
    });
  });
}
