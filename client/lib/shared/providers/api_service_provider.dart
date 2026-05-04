import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../core/constants.dart';
import '../services/api_service.dart';
import 'auth_notifier.dart';
import 'auth_service_provider.dart';

part 'api_service_provider.g.dart';

@Riverpod(keepAlive: true)
Future<ApiService> apiService(ApiServiceRef ref) async {
  final authSvc = await ref.watch(authServiceProvider.future);
  return ApiService(
    baseUrl: AppConstants.apiBaseUrl,
    getToken: () async => authSvc.getToken(),
    onUnauthorized: () async {
      await ref.read(authNotifierProvider.notifier).logout();
    },
  );
}
