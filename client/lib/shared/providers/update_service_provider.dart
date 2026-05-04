import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../services/update_service.dart';
import 'api_service_provider.dart';

part 'update_service_provider.g.dart';

@Riverpod(keepAlive: true)
Future<UpdateService> updateService(UpdateServiceRef ref) async {
  final api = await ref.watch(apiServiceProvider.future);
  return UpdateService(api);
}
