import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../services/storage_service.dart';
import 'api_service_provider.dart';

part 'storage_service_provider.g.dart';

@Riverpod(keepAlive: true)
Future<StorageService> storageService(StorageServiceRef ref) async {
  final api = await ref.watch(apiServiceProvider.future);
  return StorageService(api);
}
