import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:clientpulse/core/router/route_names.dart';
import 'package:clientpulse/shared/widgets/buttons/app_button.dart';
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
  int registerCallCount = 0;
  Completer<void>? blockOn;

  @override
  Future<AuthUser?> build() async => null;

  @override
  Future<void> register(
    String email,
    String password,
    String name,
    String workspaceName,
  ) async {
    registerCallCount++;
    capturedEmail = email;
    capturedPassword = password;
    capturedName = name;
    capturedWorkspaceName = workspaceName;
    state = const AsyncLoading();
    if (blockOn != null) await blockOn!.future;
    if (errorToThrow != null) {
      state = const AsyncData(null);
      throw errorToThrow!;
    }
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
      GoRoute(
        path: '/register',
        name: RouteNames.register,
        builder: (_, __) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/login',
        name: RouteNames.login,
        builder: (_, __) => const Scaffold(body: Text('Login')),
      ),
      GoRoute(
        path: '/dashboard',
        name: RouteNames.dashboard,
        builder: (_, __) => const Scaffold(body: Text('Dashboard')),
      ),
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

Future<void> _fillStep1Valid(WidgetTester tester) async {
  await tester.enterText(find.byKey(const Key('email_field')), 'alice@acme.com');
  await tester.enterText(find.byKey(const Key('password_field')), 'securepass');
  await tester.enterText(find.byKey(const Key('confirm_password_field')), 'securepass');
}

Future<void> _advanceToStep2(WidgetTester tester) async {
  await _fillStep1Valid(tester);
  await tester.tap(find.byKey(const Key('continue_button')));
  await tester.pumpAndSettle();
}

Future<void> _fillStep2Valid(WidgetTester tester) async {
  await tester.enterText(find.byKey(const Key('name_field')), 'Alice');
  await tester.enterText(find.byKey(const Key('workspace_field')), 'Acme Inc');
}

TextFormField _findFormField(WidgetTester tester, String key) =>
    tester.widget<TextFormField>(find.byKey(Key(key)));

// TextFormField doesn't expose its EditableText config publicly in 3.19.5;
// descend to the underlying TextField (an internal but stable subtree).
TextField _findInnerTextField(WidgetTester tester, String key) =>
    tester.widget<TextField>(
      find.descendant(
        of: find.byKey(Key(key)),
        matching: find.byType(TextField),
      ),
    );

void main() {
  group('RegisterScreen — value prop and step indicator', () {
    late _FakeAuthNotifier notifier;
    setUp(() => notifier = _FakeAuthNotifier());

    testWidgets('shows value proposition tagline', (tester) async {
      await tester.pumpWidget(_wrap(notifier));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('value_prop')), findsOneWidget);
      expect(
        find.text('Manage client updates, approvals & feedback in one place.'),
        findsOneWidget,
      );
    });

    testWidgets('shows "Step 1 of 2" initially', (tester) async {
      await tester.pumpWidget(_wrap(notifier));
      await tester.pumpAndSettle();

      expect(find.text('Step 1 of 2'), findsOneWidget);
    });

    testWidgets('shows "Step 2 of 2" after advancing', (tester) async {
      await tester.pumpWidget(_wrap(notifier));
      await tester.pumpAndSettle();

      await _advanceToStep2(tester);

      expect(find.text('Step 2 of 2'), findsOneWidget);
    });
  });

  group('RegisterScreen — step 1 (email + password)', () {
    late _FakeAuthNotifier notifier;
    setUp(() => notifier = _FakeAuthNotifier());

    testWidgets('renders email, password, confirm, continue button', (tester) async {
      await tester.pumpWidget(_wrap(notifier));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('email_field')), findsOneWidget);
      expect(find.byKey(const Key('password_field')), findsOneWidget);
      expect(find.byKey(const Key('confirm_password_field')), findsOneWidget);
      expect(find.byKey(const Key('continue_button')), findsOneWidget);
    });

    testWidgets('step 2 fields mounted but offstage initially', (tester) async {
      await tester.pumpWidget(_wrap(notifier));
      await tester.pumpAndSettle();

      // skipOffstage: false confirms Offstage keeps fields in the tree
      // (preserves state + lets AutofillGroup advertise creds at submit).
      expect(find.byKey(const Key('name_field'), skipOffstage: false),
          findsOneWidget);
      expect(find.byKey(const Key('workspace_field'), skipOffstage: false),
          findsOneWidget);
      expect(find.byKey(const Key('register_button'), skipOffstage: false),
          findsOneWidget);
      // But not visible by default (skipOffstage: true is the default).
      expect(find.byKey(const Key('name_field')), findsNothing);
      expect(find.byKey(const Key('register_button')), findsNothing);
    });

    testWidgets('shows required errors when continue tapped empty', (tester) async {
      await tester.pumpWidget(_wrap(notifier));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('continue_button')));
      await tester.pump();

      expect(find.text('Email is required'), findsOneWidget);
      expect(find.text('Password is required'), findsOneWidget);
      expect(find.text('Please confirm your password'), findsOneWidget);
    });

    testWidgets('shows error for invalid email — no @ symbol', (tester) async {
      await tester.pumpWidget(_wrap(notifier));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('email_field')), 'notanemail');
      await tester.tap(find.byKey(const Key('continue_button')));
      await tester.pump();

      expect(find.text('Enter a valid email address'), findsOneWidget);
    });

    testWidgets('shows error for invalid email — domain ends with dot', (tester) async {
      await tester.pumpWidget(_wrap(notifier));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('email_field')), 'a@b.');
      await tester.tap(find.byKey(const Key('continue_button')));
      await tester.pump();

      expect(find.text('Enter a valid email address'), findsOneWidget);
    });

    testWidgets('shows error for email longer than 254 characters', (tester) async {
      await tester.pumpWidget(_wrap(notifier));
      await tester.pumpAndSettle();

      final longLocal = 'a' * 250;
      await tester.enterText(
          find.byKey(const Key('email_field')), '$longLocal@b.com');
      await tester.tap(find.byKey(const Key('continue_button')));
      await tester.pump();

      expect(find.text('Email must be under 254 characters'), findsOneWidget);
    });

    testWidgets('shows error for password shorter than 8 characters', (tester) async {
      await tester.pumpWidget(_wrap(notifier));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('email_field')), 'a@b.com');
      await tester.enterText(find.byKey(const Key('password_field')), 'short');
      await tester.tap(find.byKey(const Key('continue_button')));
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
      await tester.tap(find.byKey(const Key('continue_button')));
      await tester.pump();

      expect(find.text('Password must be under 128 characters'), findsOneWidget);
    });

    testWidgets('shows error when passwords do not match', (tester) async {
      await tester.pumpWidget(_wrap(notifier));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('email_field')), 'a@b.com');
      await tester.enterText(find.byKey(const Key('password_field')), 'password123');
      await tester.enterText(
          find.byKey(const Key('confirm_password_field')), 'different123');
      await tester.tap(find.byKey(const Key('continue_button')));
      await tester.pump();

      expect(find.text('Passwords do not match'), findsOneWidget);
      expect(notifier.registerCallCount, 0);
    });

    testWidgets('confirm field auto-revalidates when password edited after mismatch',
        (tester) async {
      await tester.pumpWidget(_wrap(notifier));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('email_field')), 'a@b.com');
      await tester.enterText(find.byKey(const Key('password_field')), 'password123');
      await tester.enterText(
          find.byKey(const Key('confirm_password_field')), 'mismatch1');
      await tester.tap(find.byKey(const Key('continue_button')));
      await tester.pump();
      expect(find.text('Passwords do not match'), findsOneWidget);

      // Edit password to match — error should clear without explicit re-submit.
      await tester.enterText(find.byKey(const Key('password_field')), 'mismatch1');
      await tester.pumpAndSettle();
      expect(find.text('Passwords do not match'), findsNothing);
    });

    testWidgets('shows password visibility toggles on step 1', (tester) async {
      await tester.pumpWidget(_wrap(notifier));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.visibility_outlined), findsNWidgets(2));
    });

    testWidgets('shows login link', (tester) async {
      await tester.pumpWidget(_wrap(notifier));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('login_link')), findsOneWidget);
    });

    testWidgets('email field has correct autofill hint', (tester) async {
      await tester.pumpWidget(_wrap(notifier));
      await tester.pumpAndSettle();

      expect(_findInnerTextField(tester, 'email_field').autofillHints,
          contains(AutofillHints.email));
    });

    testWidgets('password field uses newPassword autofill hint', (tester) async {
      await tester.pumpWidget(_wrap(notifier));
      await tester.pumpAndSettle();

      expect(_findInnerTextField(tester, 'password_field').autofillHints,
          contains(AutofillHints.newPassword));
    });

    testWidgets('confirm field has NO autofill hint', (tester) async {
      await tester.pumpWidget(_wrap(notifier));
      await tester.pumpAndSettle();

      // Duplicating newPassword on two fields confuses password managers.
      final hints = _findInnerTextField(tester, 'confirm_password_field').autofillHints;
      expect(hints == null || hints.isEmpty, isTrue);
    });

    testWidgets('advances to step 2 on valid step 1 submit', (tester) async {
      await tester.pumpWidget(_wrap(notifier));
      await tester.pumpAndSettle();

      await _advanceToStep2(tester);

      expect(find.byKey(const Key('back_button')), findsOneWidget);
      expect(find.text('Create Account'), findsOneWidget);
    });
  });

  group('RegisterScreen — step 2 (name + workspace)', () {
    late _FakeAuthNotifier notifier;
    setUp(() => notifier = _FakeAuthNotifier());

    testWidgets('shows required errors on step 2 submit empty', (tester) async {
      await tester.pumpWidget(_wrap(notifier));
      await tester.pumpAndSettle();

      await _advanceToStep2(tester);

      await tester.tap(find.byKey(const Key('register_button')));
      await tester.pump();

      expect(find.text('Name is required'), findsOneWidget);
      expect(find.text('Workspace name is required'), findsOneWidget);
      expect(notifier.registerCallCount, 0);
    });

    testWidgets('back button returns to step 1 with email retained', (tester) async {
      await tester.pumpWidget(_wrap(notifier));
      await tester.pumpAndSettle();

      await _advanceToStep2(tester);
      await tester.tap(find.byKey(const Key('back_button')));
      await tester.pumpAndSettle();

      expect(find.text('Step 1 of 2'), findsOneWidget);
      expect(_findFormField(tester, 'email_field').controller?.text,
          'alice@acme.com');
    });

    testWidgets('step 2 retains entered name/workspace after back-and-forth',
        (tester) async {
      await tester.pumpWidget(_wrap(notifier));
      await tester.pumpAndSettle();

      await _advanceToStep2(tester);
      await _fillStep2Valid(tester);

      // Back to step 1, then forward again.
      await tester.tap(find.byKey(const Key('back_button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('continue_button')));
      await tester.pumpAndSettle();

      expect(_findFormField(tester, 'name_field').controller?.text, 'Alice');
      expect(_findFormField(tester, 'workspace_field').controller?.text,
          'Acme Inc');
    });

    testWidgets('calls register with trimmed fields on valid submit', (tester) async {
      await tester.pumpWidget(_wrap(notifier));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('email_field')), '  alice@acme.com  ');
      await tester.enterText(find.byKey(const Key('password_field')), 'securepass');
      await tester.enterText(
          find.byKey(const Key('confirm_password_field')), 'securepass');
      await tester.tap(find.byKey(const Key('continue_button')));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('name_field')), '  Alice  ');
      await tester.enterText(find.byKey(const Key('workspace_field')), '  Acme Inc  ');
      await tester.tap(find.byKey(const Key('register_button')));
      await tester.pumpAndSettle();

      expect(notifier.registerCallCount, 1);
      expect(notifier.capturedName, 'Alice');
      expect(notifier.capturedWorkspaceName, 'Acme Inc');
      expect(notifier.capturedEmail, 'alice@acme.com');
      expect(notifier.capturedPassword, 'securepass');
    });

    testWidgets('shows inline error banner when register throws AuthServiceException',
        (tester) async {
      notifier.errorToThrow = const AuthServiceException('Email already in use');

      await tester.pumpWidget(_wrap(notifier));
      await tester.pumpAndSettle();

      await _advanceToStep2(tester);
      await _fillStep2Valid(tester);
      await tester.tap(find.byKey(const Key('register_button')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('error_banner')), findsOneWidget);
      expect(find.text('Email already in use'), findsOneWidget);
    });

    testWidgets('shows inline banner with "Account created. Please sign in."',
        (tester) async {
      notifier.errorToThrow =
          const AuthServiceException('Account created. Please sign in.');

      await tester.pumpWidget(_wrap(notifier));
      await tester.pumpAndSettle();

      await _advanceToStep2(tester);
      await _fillStep2Valid(tester);
      await tester.tap(find.byKey(const Key('register_button')));
      await tester.pumpAndSettle();

      expect(find.text('Account created. Please sign in.'), findsOneWidget);
    });

    testWidgets('error banner clears when user edits any field', (tester) async {
      notifier.errorToThrow = const AuthServiceException('Email already in use');

      await tester.pumpWidget(_wrap(notifier));
      await tester.pumpAndSettle();

      await _advanceToStep2(tester);
      await _fillStep2Valid(tester);
      await tester.tap(find.byKey(const Key('register_button')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('error_banner')), findsOneWidget);

      // Edit name field; banner should clear post-frame.
      await tester.enterText(find.byKey(const Key('name_field')), 'Bob');
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('error_banner')), findsNothing);
    });
  });

  group('RegisterScreen — loading state', () {
    late _FakeAuthNotifier notifier;
    setUp(() => notifier = _FakeAuthNotifier());

    testWidgets('register button shows spinner while register is in flight',
        (tester) async {
      notifier.blockOn = Completer<void>();

      await tester.pumpWidget(_wrap(notifier));
      await tester.pumpAndSettle();
      await _advanceToStep2(tester);
      await _fillStep2Valid(tester);

      await tester.tap(find.byKey(const Key('register_button')));
      await tester.pump();
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Create Account'), findsNothing);

      notifier.blockOn!.complete();
      await tester.pumpAndSettle();
    });

    testWidgets('back button is disabled while register is in flight',
        (tester) async {
      notifier.blockOn = Completer<void>();

      await tester.pumpWidget(_wrap(notifier));
      await tester.pumpAndSettle();
      await _advanceToStep2(tester);
      await _fillStep2Valid(tester);

      await tester.tap(find.byKey(const Key('register_button')));
      await tester.pump();
      await tester.pump();

      final back = tester.widget<AppButton>(find.byKey(const Key('back_button')));
      expect(back.onPressed, isNull);

      notifier.blockOn!.complete();
      await tester.pumpAndSettle();
    });

    testWidgets('Enter on workspace field during loading does NOT double-submit',
        (tester) async {
      notifier.blockOn = Completer<void>();

      await tester.pumpWidget(_wrap(notifier));
      await tester.pumpAndSettle();
      await _advanceToStep2(tester);
      await _fillStep2Valid(tester);

      // First submit — starts loading.
      await tester.tap(find.byKey(const Key('register_button')));
      await tester.pump();
      await tester.pump();
      expect(notifier.registerCallCount, 1);

      // Press Enter on workspace field while still loading.
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
      await tester.pump();

      // Re-entrancy guard prevents second register() call.
      expect(notifier.registerCallCount, 1);

      notifier.blockOn!.complete();
      await tester.pumpAndSettle();
    });
  });
}
