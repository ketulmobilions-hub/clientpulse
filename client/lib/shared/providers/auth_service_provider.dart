import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../core/constants.dart';
import '../services/auth_service.dart';
import 'shared_preferences_provider.dart';

part 'auth_service_provider.g.dart';

@Riverpod(keepAlive: true)
Future<AuthService> authService(AuthServiceRef ref) async {
  final prefs = await ref.watch(sharedPreferencesProvider.future);
  return AuthService(prefs: prefs, baseUrl: AppConstants.apiBaseUrl);
}
