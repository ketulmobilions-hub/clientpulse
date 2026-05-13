import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/project.dart';
import 'project_service_provider.dart';

part 'project_provider.g.dart';

@Riverpod(keepAlive: true)
class ProjectNotifier extends _$ProjectNotifier {
  bool _includeArchived = false;

  bool get includeArchived => _includeArchived;

  @override
  Future<List<Project>> build() async {
    // ref.watch re-runs build when the API service changes (e.g., after re-auth),
    // ensuring we never use a stale Dio instance with an old JWT.
    final svc = await ref.watch(projectServiceProvider.future);
    return svc.listProjects(includeArchived: _includeArchived);
  }

  /// Triggers a full refresh of the project list.
  Future<void> load() async {
    ref.invalidateSelf();
    await future;
  }

  Future<void> setIncludeArchived(bool value) async {
    if (_includeArchived == value) return;
    final previousFlag = _includeArchived;
    _includeArchived = value;

    // Don't `invalidateSelf` — that nukes the AsyncData and creates a flicker
    // window where any in-flight optimistic mutation (archive/delete) is lost.
    // Re-fetch in place; preserve the current rows under AsyncLoading so the
    // UI shows a soft loading state instead of going blank.
    final current = state.valueOrNull;
    state = current == null
        ? const AsyncLoading()
        : const AsyncLoading<List<Project>>().copyWithPrevious(state);
    try {
      final svc = await ref.read(projectServiceProvider.future);
      final list = await svc.listProjects(includeArchived: value);
      // Cancellation guard: a later toggle has already mutated _includeArchived
      // to a different value, so this stale response would overwrite the
      // newer in-flight state. Drop it. (No ref.mounted in this Riverpod
      // version; the keepAlive notifier survives until app teardown.)
      if (_includeArchived != value) return;
      state = AsyncData(list);
    } catch (e, st) {
      // Roll the flag back so a UI that reads `includeArchived` doesn't drift
      // out of sync with the displayed list. Skip if a later toggle has
      // already moved on.
      if (_includeArchived == value) _includeArchived = previousFlag;
      state = AsyncError<List<Project>>(e, st).copyWithPrevious(state);
    }
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

  Future<Project> archive(String id) async {
    final prev = state.valueOrNull;
    try {
      final svc = await ref.read(projectServiceProvider.future);
      final updated = await svc.archiveProject(id);
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
      if (prev != null) state = AsyncData(prev);
      Error.throwWithStackTrace(e, st);
    }
  }

  Future<Project> unarchive(String id) async {
    final prev = state.valueOrNull;
    try {
      final svc = await ref.read(projectServiceProvider.future);
      final updated = await svc.unarchiveProject(id);
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
      if (prev != null) state = AsyncData(prev);
      Error.throwWithStackTrace(e, st);
    }
  }

  Future<void> delete(String id) async {
    final prev = state.valueOrNull;
    if (prev == null) {
      // Refuse to delete from an unknown cache state — caller may have raced
      // a `load()` that hasn't resolved. Better to surface the error than to
      // silently mutate without a rollback target.
      throw StateError(
          'Cannot delete project before project list is loaded.');
    }
    try {
      final svc = await ref.read(projectServiceProvider.future);
      await svc.deleteProject(id);
      state = AsyncData(prev.where((p) => p.id != id).toList());
    } catch (e, st) {
      state = AsyncData(prev);
      Error.throwWithStackTrace(e, st);
    }
  }
}
