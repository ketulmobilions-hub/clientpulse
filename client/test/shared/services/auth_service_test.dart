import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:clientpulse/shared/services/auth_service.dart';
import 'package:clientpulse/shared/models/auth_user.dart';

// JWT with exp=4070908800 (2099-01-01). Signature not verified client-side.
const _kFutureToken =
    'eyJhbGciOiJIUzI1NiJ9.eyJleHAiOjQwNzA5MDg4MDB9.fakesig';

// JWT with exp=1 (1970-01-01) — always expired.
const _kExpiredToken =
    'eyJhbGciOiJIUzI1NiJ9.eyJleHAiOjF9.fakesig';

// JWT with no exp claim — treated as non-expiring.
const _kNoExpToken =
    'eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJ0ZXN0In0.fakesig';

void main() {
  const testUser = AuthUser(
    id: 'user-1',
    email: 'test@example.com',
    name: 'Test User',
    role: 'admin',
    workspaceId: 'ws-1',
  );

  Future<AuthService> makeService({Map<String, Object> initial = const {}}) async {
    SharedPreferences.setMockInitialValues(initial);
    final prefs = await SharedPreferences.getInstance();
    return AuthService(prefs: prefs, baseUrl: 'http://localhost');
  }

  group('getToken', () {
    test('returns null when no token stored', () async {
      final sut = await makeService();
      expect(sut.getToken(), isNull);
    });

    test('returns raw token string regardless of expiry', () async {
      final sut = await makeService(initial: {'auth_token': _kExpiredToken});
      expect(sut.getToken(), _kExpiredToken);
    });
  });

  group('isTokenExpired', () {
    test('returns false for future-dated token', () {
      expect(AuthService.isTokenExpired(_kFutureToken), isFalse);
    });

    test('returns true for past-dated token', () {
      expect(AuthService.isTokenExpired(_kExpiredToken), isTrue);
    });

    test('returns false for token with no exp claim', () {
      expect(AuthService.isTokenExpired(_kNoExpToken), isFalse);
    });

    test('returns true for malformed token', () {
      expect(AuthService.isTokenExpired('not.a.jwt.at.all'), isTrue);
    });

    test('returns true for empty string', () {
      expect(AuthService.isTokenExpired(''), isTrue);
    });
  });

  group('getUser', () {
    test('returns null when no user stored', () async {
      final sut = await makeService();
      expect(sut.getUser(), isNull);
    });

    test('returns null when any required field missing', () async {
      // Only id — all other fields absent.
      final sut = await makeService(initial: {'auth_user_id': testUser.id});
      expect(sut.getUser(), isNull);
    });

    test('returns user when all fields stored', () async {
      final sut = await makeService(initial: {
        'auth_user_id': testUser.id,
        'auth_user_email': testUser.email,
        'auth_user_name': testUser.name,
        'auth_user_role': testUser.role,
        'auth_user_workspace_id': testUser.workspaceId,
      });

      final user = sut.getUser();
      expect(user?.id, testUser.id);
      expect(user?.email, testUser.email);
      expect(user?.name, testUser.name);
      expect(user?.role, testUser.role);
      expect(user?.workspaceId, testUser.workspaceId);
    });
  });

  group('logout', () {
    test('clears token and all user fields', () async {
      final sut = await makeService(initial: {
        'auth_token': _kFutureToken,
        'auth_user_id': testUser.id,
        'auth_user_email': testUser.email,
        'auth_user_name': testUser.name,
        'auth_user_role': testUser.role,
        'auth_user_workspace_id': testUser.workspaceId,
      });

      await sut.logout();

      expect(sut.getToken(), isNull);
      expect(sut.getUser(), isNull);
    });

    test('is idempotent when already logged out', () async {
      final sut = await makeService();
      await expectLater(sut.logout(), completes);
      expect(sut.getToken(), isNull);
    });
  });
}
