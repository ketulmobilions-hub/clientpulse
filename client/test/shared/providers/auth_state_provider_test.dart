import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:clientpulse/shared/models/auth_user.dart';
import 'package:clientpulse/shared/services/auth_service.dart';
import 'package:clientpulse/shared/providers/auth_service_provider.dart';
import 'package:clientpulse/shared/providers/auth_state_provider.dart';

// JWT with exp=4070908800 (year 2099). Signature not verified client-side.
const _kFutureToken =
    'eyJhbGciOiJIUzI1NiJ9.eyJleHAiOjQwNzA5MDg4MDB9.fakesig';

const _kTestUser = AuthUser(
  id: 'u1',
  email: 'a@b.com',
  name: 'Alice',
  role: 'admin',
  workspaceId: 'ws-1',
);

Future<AuthService> _makeAuthService({Map<String, Object> initial = const {}}) async {
  SharedPreferences.setMockInitialValues(initial);
  final prefs = await SharedPreferences.getInstance();
  return AuthService(prefs: prefs, baseUrl: 'http://localhost');
}

ProviderContainer _containerWith(AuthService authSvc) {
  return ProviderContainer(
    overrides: [
      authServiceProvider.overrideWith((_) async => authSvc),
    ],
  );
}

void main() {
  group('isAuthenticated', () {
    test('returns false when no token stored', () async {
      final svc = await _makeAuthService();
      final container = _containerWith(svc);
      addTearDown(container.dispose);

      expect(await container.read(isAuthenticatedProvider.future), isFalse);
    });

    test('returns false when token is expired', () async {
      // JWT with exp=1 (1970).
      const expiredToken = 'eyJhbGciOiJIUzI1NiJ9.eyJleHAiOjF9.fakesig';
      final svc = await _makeAuthService(initial: {'auth_token': expiredToken});
      final container = _containerWith(svc);
      addTearDown(container.dispose);

      expect(await container.read(isAuthenticatedProvider.future), isFalse);
    });

    test('returns true when valid non-expired token and user stored', () async {
      final svc = await _makeAuthService(initial: {
        'auth_token': _kFutureToken,
        'auth_user_id': _kTestUser.id,
        'auth_user_email': _kTestUser.email,
        'auth_user_name': _kTestUser.name,
        'auth_user_role': _kTestUser.role,
        'auth_user_workspace_id': _kTestUser.workspaceId,
      });
      final container = _containerWith(svc);
      addTearDown(container.dispose);

      expect(await container.read(isAuthenticatedProvider.future), isTrue);
    });
  });

  group('currentUser', () {
    test('returns null when not logged in', () async {
      final svc = await _makeAuthService();
      final container = _containerWith(svc);
      addTearDown(container.dispose);

      expect(await container.read(currentUserProvider.future), isNull);
    });

    test('returns user when valid token and all fields stored', () async {
      final svc = await _makeAuthService(initial: {
        'auth_token': _kFutureToken,
        'auth_user_id': _kTestUser.id,
        'auth_user_email': _kTestUser.email,
        'auth_user_name': _kTestUser.name,
        'auth_user_role': _kTestUser.role,
        'auth_user_workspace_id': _kTestUser.workspaceId,
      });
      final container = _containerWith(svc);
      addTearDown(container.dispose);

      final user = await container.read(currentUserProvider.future);
      expect(user?.id, _kTestUser.id);
      expect(user?.workspaceId, _kTestUser.workspaceId);
    });
  });
}
