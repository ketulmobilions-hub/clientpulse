import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/milestone.dart';
import '../services/milestone_service.dart';
import 'milestone_service_provider.dart';

part 'milestone_provider.g.dart';

@riverpod
class MilestoneNotifier extends _$MilestoneNotifier {
  late MilestoneService _svc;

  @override
  Future<List<Milestone>> build(String projectId) async {
    _svc = await ref.watch(milestoneServiceProvider.future);
    return _svc.listMilestones(projectId);
  }

  Future<void> load() async {
    ref.invalidateSelf();
    await future;
  }

  Future<Milestone> create(String title, {String? dueDate}) async {
    final current = state.valueOrNull ?? [];
    final position = current.isNotEmpty ? current.last.position + 1000 : 0;
    final milestone = await _svc.createMilestone(
      projectId,
      title: title,
      dueDate: dueDate,
      position: position,
    );
    state = AsyncData([...current, milestone]);
    return milestone;
  }

  Future<void> toggleComplete(String id) async {
    final current = state.valueOrNull;
    if (current == null) return;
    final index = current.indexWhere((m) => m.id == id);
    if (index == -1) return;
    final updated = await _svc.updateMilestone(
      id,
      completed: !current[index].completed,
    );
    final list = [...current];
    list[index] = updated;
    state = AsyncData(list);
  }

  Future<void> updateTitle(String id, String title) async {
    final current = state.valueOrNull;
    if (current == null) return;
    final index = current.indexWhere((m) => m.id == id);
    if (index == -1) return;
    final updated = await _svc.updateMilestone(id, title: title);
    final list = [...current];
    list[index] = updated;
    state = AsyncData(list);
  }

  Future<void> updateDueDate(
    String id, {
    String? dueDate,
    bool clear = false,
  }) async {
    final current = state.valueOrNull;
    if (current == null) return;
    final index = current.indexWhere((m) => m.id == id);
    if (index == -1) return;
    final updated = await _svc.updateMilestone(
      id,
      dueDate: dueDate,
      clearDueDate: clear,
    );
    final list = [...current];
    list[index] = updated;
    state = AsyncData(list);
  }

  Future<void> delete(String id) async {
    final current = state.valueOrNull;
    if (current == null) return;
    await _svc.deleteMilestone(id);
    state = AsyncData(current.where((m) => m.id != id).toList());
  }

  Future<void> reorder(int oldIndex, int newIndex) async {
    final current = state.valueOrNull;
    if (current == null) return;
    // Flutter passes newIndex relative to the original list (before removal),
    // so when moving an item forward we adjust by -1.
    final adjusted = newIndex > oldIndex ? newIndex - 1 : newIndex;
    final list = [...current];
    final item = list.removeAt(oldIndex);
    list.insert(adjusted, item);
    final reordered = [
      for (var i = 0; i < list.length; i++)
        list[i].copyWith(position: i * 1000),
    ];
    state = AsyncData(reordered);
    final originalPositions = {for (final m in current) m.id: m.position};
    try {
      await Future.wait([
        for (final m in reordered)
          if (originalPositions[m.id] != m.position)
            _svc.updateMilestone(m.id, position: m.position),
      ]);
    } catch (_) {
      state = AsyncData(current);
      rethrow;
    }
  }
}
