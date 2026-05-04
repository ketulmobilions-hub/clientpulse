import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../services/project_service.dart';
import 'api_service_provider.dart';

part 'project_service_provider.g.dart';

@Riverpod(keepAlive: true)
Future<ProjectService> projectService(ProjectServiceRef ref) async {
  final api = await ref.watch(apiServiceProvider.future);
  return ProjectService(api);
}
