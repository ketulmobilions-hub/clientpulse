import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:clientpulse/features/auth/presentation/screens/register_screen.dart';
import 'package:clientpulse/shared/models/auth_user.dart';
import 'package:clientpulse/shared/providers/auth_notifier.dart';
import 'package:clientpulse/shared/services/auth_service.dart';

class _FakeAuthNotifier extends AuthNotifier {
  AuthServiceException? errorToThrow;
  String? capturedEmail;
  String? capturedPassword;
  String? capturedName;
  String? capturedWorkspaceName;
  bool registerCalled = false;

  @override
  Future<AuthUser?> build() async => null;

  @override
  Future<void> register(
    String email,
    String password,
    String name,
    String workspaceName,
  ) async {
    registerCalled = true;
    capturedEmail = email;
    capturedPassword = password;
    capturedName = name;
    capturedWorkspaceName = workspaceName;
    if (errorToThrow != null) throw errorToThrow!;
    const user = AuthUser(
      id: 'u1',
      email: 'test@example.com',
      name: 'Tester',
      role: 'admin',
      workspaceId: 'ws-1',
    );
    state = const AsyncData(user);
  }
}

Widget _wrap(_FakeAuthNotifier notifier) {
  final router = GoRouter(
    routes: [
      GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
      GoRoute(path: '/login', builder: (_, __) => const Scaffold(body: Text('Login'))),
      GoRoute(path: '/dashboard', builder: (_, __) => const Scaffold(body: Text('Dashboard'))),
    ],
    initialLocation: '/register',
  );

  return ProviderScope(
    overrides: [
      authNotifierProvider.overrideWith(() => notifier),
    ],
    child: MaterialApp.router(routerConfig: router),
  );
}

// Fills all fields with valid data (including matching confirm password).
Future<void> _fillValid(WidgetTester tester) async {
  await tester.enterText(find.byKey(const Key('name_field')), 'Alice');
  await tester.enterText(find.byKey(const Key('workspace_field')), 'Acme Inc');
  await tester.enterText(find.byKey(const Key('email_field')), 'alice@acme.com');
  await tester.enterText(find.byKey(const Key('password_field')), 'securepass');
  await tester.enterText(find.byKey(const Key('confirm_password_field')), 'securepass');
}

void main() {
  group('RegisterScreen — form validation', () {
    late _FakeAuthNotifier notifier;

    setUp(() => notifier = _FakeAuthNotifier());

    testWidgets('renders all 5 fields and register button', (tester) async {
      await tester.pumpWidget(_wrap(notifier));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('name_field')), findsOneWidget);
      expect(find.byKey(const Key('workspace_field')), findsOneWidget);
      expect(find.byKey(const Key('email_field')), findsOneWidget);
      expect(find.byKey(const Key('password_field')), findsOneWidget);
      expect(find.byKey(const Key('confirm_password_field')), findsOneWidget);
      expect(find.byKey(const Key('register_button')), findsOneWidget);
    });

    testWidgets('shows required errors when form submitted empty', (tester) async {
      await tester.pumpWidget(_wrap(notifier));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('register_button')));
      await tester.pump();

      expect(find.text('Name is required'), findsOneWidget);
      expect(find.text('Workspace name is required'), findsOneWidget);
      expect(find.text('Email is required'), findsOneWidget);
      expect(find.text('Password is required'), findsOneWidget);
      expect(find.text('Please confirm your password'), findsOneWidget);
    });

    testWidgets('shows error for invalid email — no @ symbol', (tester) async {
      await tester.pumpWidget(_wrap(notifier));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('email_field')), 'notanemail');
      await tester.tap(find.byKey(const Key('register_button')));
      await tester.pump();

      expect(find.text('Enter a valid email address'), findsOneWidget);
    });

    testWidgets('shows error for invalid email — domain ends with dot', (tester) async {
      await tester.pumpWidget(_wrap(notifier));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('email_field')), 'a@b.');
      await tester.tap(find.byKey(const Key('register_button')));
      await tester.pump();

      expect(find.text('Enter a valid email address'), findsOneWidget);
    });

    testWidgets('shows error for password shorter than 8 characters', (tester) async {
      await tester.pumpWidget(_wrap(notifier));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('name_field')), 'Alice');
      await tester.enterText(find.byKey(const Key('workspace_field')), 'Acme Inc');
      await tester.enterText(find.byKey(const Key('email_field')), 'a@b.com');
      await tester.enterText(find.byKey(const Key('password_field')), 'short');
      await tester.tap(find.byKey(const Key('register_button')));
      await tester.pump();

      expect(find.text('Password must be at least 8 characters'), findsOneWidget);
    });

    testWidgets('shows error for password longer than 128 characters', (tester) async {
      await tester.pumpWidget(_wrap(notifier));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('password_field')),
        'a' * 129,
      );
      await tester.tap(find.byKey(const Key('register_button')));
      await tester.pump();

      expect(find.text('Password must be under 128 characters'), findsOneWidget);
    });

    testWidgets('shows error when passwords do not match', (tester) async {
      await tester.pumpWidget(_wrap(notifier));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('name_field')), 'Alice');
      await tester.enterText(find.byKey(const Key('workspace_field')), 'Acme Inc');
      await tester.enterText(find.byKey(const Key('email_field')), 'a@b.com');
      await tester.enterText(find.byKey(const Key('password_field')), 'password123');
      await tester.enterText(
          find.byKey(const Key('confirm_password_field')), 'different123');
      await tester.tap(find.byKey(const Key('register_button')));
      await tester.pump();

      expect(find.text('Passwords do not match'), findsOneWidget);
      expect(notifier.registerCalled, isFalse);
    });

    testWidgets('shows password visibility toggles', (tester) async {
      await tester.pumpWidget(_wrap(notifier));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.visibility_outlined), findsNWidgets(2));
    });

    testWidgets('shows login link', (tester) async {
      await tester.pumpWidget(_wrap(notifier));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('login_link')), findsOneWidget);
    });
  });

  group('RegisterScreen — submit behavior', () {
    late _FakeAuthNotifier notifier;

    setUp(() => notifier = _FakeAuthNotifier());

    testWidgets('calls register with trimmed fields on valid submit', (tester) async {
      await tester.pumpWidget(_wrap(notifier));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('name_field')), '  Alice  ');
      await tester.enterText(find.byKey(const Key('workspace_field')), '  Acme Inc  ');
      await tester.enterText(find.byKey(const Key('email_field')), '  alice@acme.com  ');
      await tester.enterText(find.byKey(const Key('password_field')), 'securepass');
      await tester.enterText(
          find.byKey(const Key('confirm_password_field')), 'securepass');
      await tester.tap(find.byKey(const Key('register_button')));
      await tester.pumpAndSettle();

      expect(notifier.registerCalled, isTrue);
      expect(notifier.capturedName, 'Alice');
      expect(notifier.capturedWorkspaceName, 'Acme Inc');
      expect(notifier.capturedEmail, 'alice@acme.com');
      expect(notifier.capturedPassword, 'securepass');
    });

    testWidgets('does not call register when passwords do not match', (tester) async {
      await tester.pumpWidget(_wrap(notifier));
      await tester.pumpAndSettle();

      await _fillValid(tester);
      // Overwrite confirm password with a mismatch.
      await tester.enterText(
          find.byKey(const Key('confirm_password_field')), 'wrongpass');
      await tester.tap(find.byKey(const Key('register_button')));
      await tester.pump();

      expect(notifier.registerCalled, isFalse);
    });

    testWidgets('shows SnackBar when register throws AuthServiceException', (tester) async {
      notifier.errorToThrow = const AuthServiceException('Email already in use');

      await tester.pumpWidget(_wrap(notifier));
      await tester.pumpAndSettle();

      await _fillValid(tester);
      await tester.tap(find.byKey(const Key('register_button')));
      await tester.pumpAndSettle();

      expect(find.text('Email already in use'), findsOneWidget);
    });

    testWidgets('shows "Account created. Please sign in." SnackBar on auto-login failure',
        (tester) async {
      notifier.errorToThrow =
          const AuthServiceException('Account created. Please sign in.');

      await tester.pumpWidget(_wrap(notifier));
      await tester.pumpAndSettle();

      await _fillValid(tester);
      await tester.tap(find.byKey(const Key('register_button')));
      await tester.pumpAndSettle();

      expect(find.text('Account created. Please sign in.'), findsOneWidget);
    });
  });
}
