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

  Future<Project> getProject(String id) async {
    // Serve from cache to avoid a network round-trip when data is already loaded.
    final cached = state.valueOrNull?.where((p) => p.id == id).firstOrNull;
    if (cached != null) return cached;
    try {
      final svc = await ref.read(projectServiceProvider.future);
      return svc.getProject(id);
    } catch (e, st) {
      Error.throwWithStackTrace(e, st);
    }
  }

  Future<Project> updateProject(
    String id, {
    String? name,
    String? clientName,
    String? clientEmail,
    String? description,
    bool clearDescription = false,
    ProjectStatus? status,
    DateTime? startDate,
    bool clearStartDate = false,
    DateTime? expectedEndDate,
    bool clearExpectedEndDate = false,
  }) async {
    final prev = state.valueOrNull;
    try {
      final svc = await ref.read(projectServiceProvider.future);
      final updated = await svc.updateProject(
        id,
        name: name,
        clientName: clientName,
        clientEmail: clientEmail,
        description: description,
        clearDescription: clearDescription,
        status: status,
        startDate: startDate,
        clearStartDate: clearStartDate,
        expectedEndDate: expectedEndDate,
        clearExpectedEndDate: clearExpectedEndDate,
      );
      // Replace updated project in cached list so dashboard reflects change immediately.
      // PATCH /projects/:id does NOT return aggregate fields (those come only from the list
      // RPC), so merge them from the cached row to keep dashboard counts/progress visible.
      final current = state.valueOrNull ?? [];
      state = AsyncData(current.map((p) {
        if (p.id != id) return p;
        return updated.copyWith(
          updateCount: p.updateCount,
          commentCount: p.commentCount,
          latestUpdateTitle: p.latestUpdateTitle,
          progressPct: p.progressPct,
        );
      }).toList());
      return updated;
    } catch (e, st) {
      // Restore previous list state so the dashboard doesn't go blank on failure.
      if (prev != null) state = AsyncData(prev);
      Error.throwWithStackTrace(e, st);
    }
  }

  Future<Project> create({
    required String name,
    required String clientName,
    required String clientEmail,
    String? description,
    DateTime? startDate,
    DateTime? expectedEndDate,
  }) async {
    try {
      final svc = await ref.read(projectServiceProvider.future);
      final project = await svc.createProject(
        name: name,
        clientName: clientName,
        clientEmail: clientEmail,
        description: description,
        startDate: startDate,
        expectedEndDate: expectedEndDate,
      );
      // POST /projects does not return aggregate fields. A brand-new project legitimately has
      // zero updates / comments / milestones, so seed the aggregates explicitly to avoid showing
      // a half-rendered card with null counts.
      final seeded = project.copyWith(
        updateCount: 0,
        commentCount: 0,
        latestUpdateTitle: null,
        progressPct: null,
      );
      final current = state.valueOrNull ?? [];
      state = AsyncData([seeded, ...current]);
      return seeded;
    } catch (e, st) {
      Error.throwWithStackTrace(e, st);
    }
  }
}
