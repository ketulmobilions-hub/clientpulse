import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../services/workspace_service.dart';
import 'api_service_provider.dart';

part 'workspace_service_provider.g.dart';

@Riverpod(keepAlive: true)
Future<WorkspaceService> workspaceService(WorkspaceServiceRef ref) async {
  final api = await ref.watch(apiServiceProvider.future);
  return WorkspaceService(api);
}
