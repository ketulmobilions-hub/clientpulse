import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'auth_state_provider.g.dart';

// Stub: checks SharedPreferences for a JWT token.
// Replaced by real auth logic in issue #8.
// Note: tests must override this provider — real SharedPreferences calls
// require platform channel setup that is absent in the test environment.
@Riverpod(keepAlive: true)
Future<bool> isAuthenticated(IsAuthenticatedRef ref) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString('auth_token') != null;
}
