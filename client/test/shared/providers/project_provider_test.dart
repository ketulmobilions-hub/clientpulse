import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:clientpulse/shared/models/project.dart';
import 'package:clientpulse/shared/providers/project_provider.dart';
import 'package:clientpulse/shared/providers/project_service_provider.dart';
import 'package:clientpulse/shared/services/project_service.dart';

class _FakeProjectService implements ProjectService {
  _FakeProjectService({List<Project>? initial}) : _projects = [...?initial];

  final List<Project> _projects;
  bool? lastIncludeArchived;

  @override
  Future<List<Project>> listProjects({bool includeArchived = false}) async {
    lastIncludeArchived = includeArchived;
    if (includeArchived) return List.unmodifiable(_projects);
    return _projects
        .where((p) => p.status != ProjectStatus.archived)
        .toList(growable: false);
  }

  @override
  Future<Project> archiveProject(String id) async {
    final idx = _projects.indexWhere((p) => p.id == id);
    final updated = _projects[idx].copyWith(status: ProjectStatus.archived);
    _projects[idx] = updated;
    return updated;
  }

  @override
  Future<Project> unarchiveProject(String id) async {
    final idx = _projects.indexWhere((p) => p.id == id);
    final updated = _projects[idx].copyWith(status: ProjectStatus.active);
    _projects[idx] = updated;
    return updated;
  }

  @override
  Future<void> deleteProject(String id) async {
    _projects.removeWhere((p) => p.id == id);
  }

  // Any interface method we forgot to stub fails loudly with the member name.
  @override
  noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('Fake missing: ${invocation.memberName}');
}

Project _makeProject({
  required String id,
  String name = 'Alpha',
  ProjectStatus status = ProjectStatus.active,
}) =>
    Project(
      id: id,
      workspaceId: 'ws-1',
      name: name,
      clientName: 'Acme',
      clientEmail: 'client@acme.com',
      status: status,
      shareToken: 'tok-$id',
      createdAt: DateTime.utc(2026, 1, 1),
      updatedAt: DateTime.utc(2026, 1, 1),
      updateCount: 2,
      commentCount: 1,
      latestUpdateTitle: 'Update 1',
      progressPct: 50,
    );

ProviderContainer _container(_FakeProjectService svc) => ProviderContainer(
      overrides: [
        projectServiceProvider.overrideWith((_) async => svc),
      ],
    );

void main() {
  group('ProjectNotifier', () {
    test('build excludes archived by default and passes flag to service', () async {
      final svc = _FakeProjectService(initial: [
        _makeProject(id: 'p-1'),
        _makeProject(id: 'p-2', status: ProjectStatus.archived),
      ]);
      final container = _container(svc);
      addTearDown(container.dispose);

      final list = await container.read(projectNotifierProvider.future);
      expect(list, hasLength(1));
      expect(list.first.id, 'p-1');
      expect(svc.lastIncludeArchived, isFalse);
    });

    test('setIncludeArchived(true) re-fetches with flag and reveals archived', () async {
      final svc = _FakeProjectService(initial: [
        _makeProject(id: 'p-1'),
        _makeProject(id: 'p-2', status: ProjectStatus.archived),
      ]);
      final container = _container(svc);
      addTearDown(container.dispose);

      await container.read(projectNotifierProvider.future);

      await container
          .read(projectNotifierProvider.notifier)
          .setIncludeArchived(true);

      final list = await container.read(projectNotifierProvider.future);
      expect(list, hasLength(2));
      expect(svc.lastIncludeArchived, isTrue);
    });

    test('archive flips status in cache and preserves aggregate fields', () async {
      final svc = _FakeProjectService(initial: [_makeProject(id: 'p-1')]);
      final container = _container(svc);
      addTearDown(container.dispose);

      await container.read(projectNotifierProvider.future);

      await container.read(projectNotifierProvider.notifier).archive('p-1');

      final list = await container.read(projectNotifierProvider.future);
      // Archived stays in cache (filter is the visibility layer).
      expect(list, hasLength(1));
      expect(list.first.status, ProjectStatus.archived);
      expect(list.first.updateCount, 2);
      expect(list.first.progressPct, 50);
    });

    test('unarchive flips status back to active', () async {
      final svc = _FakeProjectService(initial: [
        _makeProject(id: 'p-1', status: ProjectStatus.archived),
      ]);
      final container = _container(svc);
      addTearDown(container.dispose);

      // Need includeArchived=true to even see the project initially.
      await container
          .read(projectNotifierProvider.notifier)
          .setIncludeArchived(true);
      await container.read(projectNotifierProvider.future);

      await container.read(projectNotifierProvider.notifier).unarchive('p-1');

      final list = await container.read(projectNotifierProvider.future);
      expect(list.first.status, ProjectStatus.active);
    });

    test('delete removes project from cached list', () async {
      final svc = _FakeProjectService(initial: [
        _makeProject(id: 'p-1'),
        _makeProject(id: 'p-2', name: 'Beta'),
      ]);
      final container = _container(svc);
      addTearDown(container.dispose);

      await container.read(projectNotifierProvider.future);

      await container.read(projectNotifierProvider.notifier).delete('p-1');

      final list = await container.read(projectNotifierProvider.future);
      expect(list, hasLength(1));
      expect(list.first.id, 'p-2');
    });

    test('archive failure rolls state back to previous list', () async {
      final svc = _ThrowingProjectService(
        initial: [_makeProject(id: 'p-1')],
        throwOn: 'archive',
      );
      final container = _container(svc);
      addTearDown(container.dispose);

      await container.read(projectNotifierProvider.future);

      await expectLater(
        container.read(projectNotifierProvider.notifier).archive('p-1'),
        throwsA(isA<Exception>()),
      );

      final list = await container.read(projectNotifierProvider.future);
      expect(list.first.status, ProjectStatus.active,
          reason: 'state rolled back, archive must not be reflected');
    });

    test('delete failure rolls state back and keeps project visible', () async {
      final svc = _ThrowingProjectService(
        initial: [_makeProject(id: 'p-1'), _makeProject(id: 'p-2')],
        throwOn: 'delete',
      );
      final container = _container(svc);
      addTearDown(container.dispose);

      await container.read(projectNotifierProvider.future);

      await expectLater(
        container.read(projectNotifierProvider.notifier).delete('p-1'),
        throwsA(isA<Exception>()),
      );

      final list = await container.read(projectNotifierProvider.future);
      expect(list, hasLength(2),
          reason: 'failed delete must not remove the project from cache');
    });

    test('delete refuses to run before initial list load', () async {
      final svc = _FakeProjectService(initial: [_makeProject(id: 'p-1')]);
      final container = _container(svc);
      addTearDown(container.dispose);

      // Do NOT await the future. State is AsyncLoading on first call.
      await expectLater(
        container.read(projectNotifierProvider.notifier).delete('p-1'),
        throwsA(isA<StateError>()),
      );
    });
  });
}

class _ThrowingProjectService extends _FakeProjectService {
  _ThrowingProjectService({super.initial, required this.throwOn});

  final String throwOn;

  @override
  Future<Project> archiveProject(String id) async {
    if (throwOn == 'archive') throw Exception('archive failed');
    return super.archiveProject(id);
  }

  @override
  Future<Project> unarchiveProject(String id) async {
    if (throwOn == 'unarchive') throw Exception('unarchive failed');
    return super.unarchiveProject(id);
  }

  @override
  Future<void> deleteProject(String id) async {
    if (throwOn == 'delete') throw Exception('delete failed');
    return super.deleteProject(id);
  }
}
