import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:clientpulse/shared/models/auth_user.dart';
import 'package:clientpulse/shared/providers/auth_notifier.dart';
import 'package:clientpulse/shared/providers/auth_service_provider.dart';
import 'package:clientpulse/shared/services/auth_service.dart';

class _FakeAuthService implements AuthService {
  _FakeAuthService({
    this.loginOutcome,
    this.registerOutcome,
    Object? throwOnLogin,
  })  : _loginThrow = throwOnLogin;

  LoginOutcome? loginOutcome;
  RegisterOutcome? registerOutcome;
  final Object? _loginThrow;

  @override
  Future<LoginOutcome> login(String email, String password) async {
    if (_loginThrow != null) throw _loginThrow!;
    return loginOutcome ?? LoginSuccess(_user);
  }

  @override
  Future<RegisterOutcome> register(
    String email,
    String password,
    String name,
    String workspaceName,
  ) async {
    return registerOutcome ?? RegisterRequiresVerification(email);
  }

  @override
  String? getToken() => null;

  @override
  AuthUser? getUser() => null;

  @override
  Future<void> logout() async {}

  @override
  noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('Fake missing: ${invocation.memberName}');
}

const _user = AuthUser(
  id: 'u-1',
  email: 'pm@agency.com',
  name: 'Pat',
  role: 'admin',
  workspaceId: 'ws-1',
);

ProviderContainer _container(_FakeAuthService svc) => ProviderContainer(
      overrides: [
        authServiceProvider.overrideWith((_) async => svc),
      ],
    );

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('AuthNotifier.login', () {
    test('LoginSuccess sets state to AsyncData(user)', () async {
      final svc = _FakeAuthService(loginOutcome: LoginSuccess(_user));
      final container = _container(svc);
      addTearDown(container.dispose);

      await container.read(authNotifierProvider.future);
      final outcome = await container
          .read(authNotifierProvider.notifier)
          .login('pm@agency.com', 'secret123');

      expect(outcome, isA<LoginSuccess>());
      expect(container.read(authNotifierProvider).value, _user);
    });

    test('LoginRequiresVerification keeps state unauthenticated', () async {
      final svc = _FakeAuthService(
        loginOutcome: const LoginRequiresVerification('pm@agency.com'),
      );
      final container = _container(svc);
      addTearDown(container.dispose);

      await container.read(authNotifierProvider.future);
      final outcome = await container
          .read(authNotifierProvider.notifier)
          .login('pm@agency.com', 'secret123');

      expect(outcome, isA<LoginRequiresVerification>());
      expect(
        (outcome as LoginRequiresVerification).email,
        'pm@agency.com',
      );
      expect(container.read(authNotifierProvider).value, isNull);
    });

    test('login error resets to AsyncData(null)', () async {
      final svc = _FakeAuthService(
        throwOnLogin: const AuthServiceException('Invalid email or password'),
      );
      final container = _container(svc);
      addTearDown(container.dispose);

      await container.read(authNotifierProvider.future);
      await expectLater(
        container
            .read(authNotifierProvider.notifier)
            .login('pm@agency.com', 'wrong'),
        throwsA(isA<AuthServiceException>()),
      );
      expect(container.read(authNotifierProvider).hasValue, isTrue);
      expect(container.read(authNotifierProvider).value, isNull);
    });
  });

  group('AuthNotifier.register', () {
    test('returns RegisterRequiresVerification without auto-login', () async {
      final svc = _FakeAuthService();
      final container = _container(svc);
      addTearDown(container.dispose);

      await container.read(authNotifierProvider.future);
      final outcome = await container
          .read(authNotifierProvider.notifier)
          .register('new@agency.com', 'secret123', 'Pat', 'Acme');

      expect(outcome, isA<RegisterRequiresVerification>());
      expect(
        (outcome as RegisterRequiresVerification).email,
        'new@agency.com',
      );
      // State stays unauthenticated — verify-pending screen is the next stop.
      expect(container.read(authNotifierProvider).value, isNull);
    });
  });
}
