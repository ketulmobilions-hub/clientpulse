import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:clientpulse/shared/models/milestone.dart';
import 'package:clientpulse/shared/providers/milestone_provider.dart';
import 'package:clientpulse/shared/providers/milestone_service_provider.dart';
import 'package:clientpulse/shared/services/milestone_service.dart';

class _FakeMilestoneService implements MilestoneService {
  _FakeMilestoneService({List<Milestone>? initial})
      : _store = initial != null ? [...initial] : [];

  final List<Milestone> _store;

  @override
  Future<List<Milestone>> listMilestones(String projectId) async =>
      List.unmodifiable(_store);

  @override
  Future<Milestone> createMilestone(
    String projectId, {
    required String title,
    String? dueDate,
    int position = 0,
  }) async {
    final m = Milestone(
      id: 'ms-${_store.length + 1}',
      projectId: projectId,
      title: title,
      dueDate: dueDate,
      completed: false,
      completedAt: null,
      position: position,
      createdAt: '2026-01-01T00:00:00Z',
      updatedAt: '2026-01-01T00:00:00Z',
    );
    _store.add(m);
    return m;
  }

  @override
  Future<Milestone> updateMilestone(
    String id, {
    String? title,
    String? dueDate,
    bool clearDueDate = false,
    bool? completed,
    int? position,
  }) async {
    final index = _store.indexWhere((m) => m.id == id);
    if (index == -1) throw MilestoneServiceException('Not found');
    final updated = _store[index].copyWith(
      title: title ?? _store[index].title,
      dueDate: clearDueDate ? null : (dueDate ?? _store[index].dueDate),
      completed: completed ?? _store[index].completed,
      position: position ?? _store[index].position,
    );
    _store[index] = updated;
    return updated;
  }

  @override
  Future<void> deleteMilestone(String id) async {
    _store.removeWhere((m) => m.id == id);
  }
}

Milestone _m(String id, {bool completed = false, int position = 0}) =>
    Milestone(
      id: id,
      projectId: 'proj-1',
      title: 'Milestone $id',
      dueDate: null,
      completed: completed,
      completedAt: null,
      position: position,
      createdAt: '2026-01-01T00:00:00Z',
      updatedAt: '2026-01-01T00:00:00Z',
    );

ProviderContainer _container(_FakeMilestoneService svc) {
  return ProviderContainer(
    overrides: [
      milestoneServiceProvider.overrideWith((_) async => svc),
    ],
  );
}

void main() {
  const projectId = 'proj-1';

  group('build', () {
    test('loads milestones from service', () async {
      final svc = _FakeMilestoneService(initial: [_m('a'), _m('b')]);
      final container = _container(svc);
      addTearDown(container.dispose);

      final result = await container
          .read(milestoneNotifierProvider(projectId).future);
      expect(result.map((m) => m.id), ['a', 'b']);
    });

    test('returns empty list when no milestones', () async {
      final svc = _FakeMilestoneService();
      final container = _container(svc);
      addTearDown(container.dispose);

      final result = await container
          .read(milestoneNotifierProvider(projectId).future);
      expect(result, isEmpty);
    });
  });

  group('create', () {
    test('appends new milestone to state', () async {
      final svc = _FakeMilestoneService();
      final container = _container(svc);
      addTearDown(container.dispose);

      await container.read(milestoneNotifierProvider(projectId).future);
      await container
          .read(milestoneNotifierProvider(projectId).notifier)
          .create('First milestone');

      final list = container
          .read(milestoneNotifierProvider(projectId))
          .valueOrNull!;
      expect(list.length, 1);
      expect(list.first.title, 'First milestone');
    });

    test('assigns position after last item', () async {
      final svc = _FakeMilestoneService(initial: [_m('a', position: 0)]);
      final container = _container(svc);
      addTearDown(container.dispose);

      await container.read(milestoneNotifierProvider(projectId).future);
      await container
          .read(milestoneNotifierProvider(projectId).notifier)
          .create('Second');

      final list = container
          .read(milestoneNotifierProvider(projectId))
          .valueOrNull!;
      expect(list.last.position, 1000);
    });
  });

  group('toggleComplete', () {
    test('flips completed flag', () async {
      final svc = _FakeMilestoneService(initial: [_m('a', completed: false)]);
      final container = _container(svc);
      addTearDown(container.dispose);

      await container.read(milestoneNotifierProvider(projectId).future);
      await container
          .read(milestoneNotifierProvider(projectId).notifier)
          .toggleComplete('a');

      final list = container
          .read(milestoneNotifierProvider(projectId))
          .valueOrNull!;
      expect(list.first.completed, isTrue);
    });

    test('no-ops for unknown id without throwing', () async {
      final svc = _FakeMilestoneService(initial: [_m('a')]);
      final container = _container(svc);
      addTearDown(container.dispose);

      await container.read(milestoneNotifierProvider(projectId).future);
      await container
          .read(milestoneNotifierProvider(projectId).notifier)
          .toggleComplete('unknown');

      final list = container
          .read(milestoneNotifierProvider(projectId))
          .valueOrNull!;
      expect(list.first.completed, isFalse);
    });
  });

  group('delete', () {
    test('removes milestone from state', () async {
      final svc = _FakeMilestoneService(initial: [_m('a'), _m('b')]);
      final container = _container(svc);
      addTearDown(container.dispose);

      await container.read(milestoneNotifierProvider(projectId).future);
      await container
          .read(milestoneNotifierProvider(projectId).notifier)
          .delete('a');

      final list = container
          .read(milestoneNotifierProvider(projectId))
          .valueOrNull!;
      expect(list.map((m) => m.id), ['b']);
    });
  });

  group('reorder', () {
    test('moves item from oldIndex to newIndex', () async {
      final svc = _FakeMilestoneService(
        initial: [_m('a', position: 0), _m('b', position: 1000), _m('c', position: 2000)],
      );
      final container = _container(svc);
      addTearDown(container.dispose);

      await container.read(milestoneNotifierProvider(projectId).future);
      // Move 'a' (index 0) to after 'c' (newIndex 3 — Flutter-style)
      await container
          .read(milestoneNotifierProvider(projectId).notifier)
          .reorder(0, 3);

      final list = container
          .read(milestoneNotifierProvider(projectId))
          .valueOrNull!;
      expect(list.map((m) => m.id), ['b', 'c', 'a']);
      expect(list[0].position, 0);
      expect(list[1].position, 1000);
      expect(list[2].position, 2000);
    });

    test('moves item backward correctly', () async {
      final svc = _FakeMilestoneService(
        initial: [_m('a', position: 0), _m('b', position: 1000), _m('c', position: 2000)],
      );
      final container = _container(svc);
      addTearDown(container.dispose);

      await container.read(milestoneNotifierProvider(projectId).future);
      // Move 'c' (index 2) to front (newIndex 0)
      await container
          .read(milestoneNotifierProvider(projectId).notifier)
          .reorder(2, 0);

      final list = container
          .read(milestoneNotifierProvider(projectId))
          .valueOrNull!;
      expect(list.map((m) => m.id), ['c', 'a', 'b']);
    });
  });

  group('updateTitle', () {
    test('updates title in state', () async {
      final svc = _FakeMilestoneService(initial: [_m('a')]);
      final container = _container(svc);
      addTearDown(container.dispose);

      await container.read(milestoneNotifierProvider(projectId).future);
      await container
          .read(milestoneNotifierProvider(projectId).notifier)
          .updateTitle('a', 'New Title');

      final list = container
          .read(milestoneNotifierProvider(projectId))
          .valueOrNull!;
      expect(list.first.title, 'New Title');
    });
  });

  group('updateDueDate', () {
    test('sets new due date in state', () async {
      final svc = _FakeMilestoneService(initial: [_m('a')]);
      final container = _container(svc);
      addTearDown(container.dispose);

      await container.read(milestoneNotifierProvider(projectId).future);
      await container
          .read(milestoneNotifierProvider(projectId).notifier)
          .updateDueDate('a', dueDate: '2026-12-31');

      final list = container
          .read(milestoneNotifierProvider(projectId))
          .valueOrNull!;
      expect(list.first.dueDate, '2026-12-31');
    });

    test('clears due date when clear=true', () async {
      final svc = _FakeMilestoneService(
        initial: [
          Milestone(
            id: 'a',
            projectId: projectId,
            title: 'Test',
            dueDate: '2026-05-01',
            completed: false,
            completedAt: null,
            position: 0,
            createdAt: '2026-01-01T00:00:00Z',
            updatedAt: '2026-01-01T00:00:00Z',
          ),
        ],
      );
      final container = _container(svc);
      addTearDown(container.dispose);

      await container.read(milestoneNotifierProvider(projectId).future);
      await container
          .read(milestoneNotifierProvider(projectId).notifier)
          .updateDueDate('a', clear: true);

      final list = container
          .read(milestoneNotifierProvider(projectId))
          .valueOrNull!;
      expect(list.first.dueDate, isNull);
    });
  });
}
