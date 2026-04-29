import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/project.dart';
import 'project_service_provider.dart';

part 'project_provider.g.dart';

@Riverpod(keepAlive: true)
class ProjectNotifier extends _$ProjectNotifier {
  @override
  Future<List<Project>> build() async {
    // ref.watch re-runs build when the API service changes (e.g., after re-auth),
    // ensuring we never use a stale Dio instance with an old JWT.
    final svc = await ref.watch(projectServiceProvider.future);
    return svc.listProjects();
  }

  /// Triggers a full refresh of the project list.
  Future<void> load() async {
    ref.invalidateSelf();
    await future;
  }

  Future<Project> create({
    required String name,
    required String clientName,
    required String clientEmail,
    String? description,
  }) async {
    try {
      final svc = await ref.read(projectServiceProvider.future);
      final project = await svc.createProject(
        name: name,
        clientName: clientName,
        clientEmail: clientEmail,
        description: description,
      );
      final current = state.valueOrNull ?? [];
      state = AsyncData([project, ...current]);
      return project;
    } catch (e, st) {
      Error.throwWithStackTrace(e, st);
    }
  }
}
