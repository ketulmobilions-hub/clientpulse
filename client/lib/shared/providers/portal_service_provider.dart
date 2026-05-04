import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../services/portal_service.dart';
import 'api_service_provider.dart';

part 'portal_service_provider.g.dart';

@Riverpod(keepAlive: true)
Future<PortalService> portalService(PortalServiceRef ref) async {
  final api = await ref.watch(apiServiceProvider.future);
  return PortalService(api);
}
