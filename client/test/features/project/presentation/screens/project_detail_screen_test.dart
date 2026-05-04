import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:clientpulse/features/project/presentation/screens/project_detail_screen.dart';
import 'package:clientpulse/shared/models/project.dart';
import 'package:clientpulse/shared/providers/project_provider.dart';

class _FakeProjectNotifier extends ProjectNotifier {
  _FakeProjectNotifier({this.failLoad = false, required this.project});

  final bool failLoad;
  final Project project;

  @override
  Future<List<Project>> build() async {
    if (failLoad) throw Exception('Load failed');
    return [project];
  }

  @override
  Future<void> load() async {
    if (failLoad) {
      state = AsyncError(Exception('Load failed'), StackTrace.empty);
      return;
    }
    state = AsyncData([project]);
  }
}

final _kProject = Project(
  id: 'proj-1',
  workspaceId: 'ws-1',
  name: 'Acme Redesign',
  clientName: 'Acme Corp',
  clientEmail: 'pm@acme.com',
  status: ProjectStatus.active,
  shareToken: 'tok-abc',
  createdAt: DateTime(2026, 1, 1),
  updatedAt: DateTime(2026, 1, 2),
);

Widget _wrap(_FakeProjectNotifier notifier, {String projectId = 'proj-1'}) =>
    ProviderScope(
      overrides: [
        projectNotifierProvider.overrideWith(() => notifier),
      ],
      child: MaterialApp(
        home: ProjectDetailScreen(projectId: projectId),
      ),
    );

Future<void> _awaitBody(WidgetTester tester) async {
  await tester.pumpAndSettle(const Duration(seconds: 2));
  expect(
    find.text('Updates').evaluate().isNotEmpty ||
        find.text('Retry').evaluate().isNotEmpty ||
        find.text('Project not found').evaluate().isNotEmpty,
    isTrue,
    reason: 'Screen did not leave loading state',
  );
}

void main() {
  group('ProjectDetailScreen', () {
    testWidgets('shows loading spinner initially', (tester) async {
      final notifier = _FakeProjectNotifier(project: _kProject);
      await tester.pumpWidget(_wrap(notifier));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows project name in AppBar after load', (tester) async {
      final notifier = _FakeProjectNotifier(project: _kProject);
      await tester.pumpWidget(_wrap(notifier));
      await _awaitBody(tester);

      expect(
        find.descendant(
          of: find.byType(AppBar),
          matching: find.text('Acme Redesign'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('shows client name and status badge after load', (tester) async {
      final notifier = _FakeProjectNotifier(project: _kProject);
      await tester.pumpWidget(_wrap(notifier));
      await _awaitBody(tester);

      expect(find.text('Acme Corp'), findsOneWidget);
      expect(find.text('Active'), findsOneWidget);
    });

    testWidgets('shows all three tabs after load', (tester) async {
      final notifier = _FakeProjectNotifier(project: _kProject);
      await tester.pumpWidget(_wrap(notifier));
      await _awaitBody(tester);

      expect(find.text('Updates'), findsOneWidget);
      expect(find.text('Milestones'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);
    });

    testWidgets('Updates tab shows placeholder by default', (tester) async {
      final notifier = _FakeProjectNotifier(project: _kProject);
      await tester.pumpWidget(_wrap(notifier));
      await _awaitBody(tester);

      expect(find.text('Updates coming soon'), findsOneWidget);
    });

    testWidgets('tapping Milestones tab shows milestones placeholder',
        (tester) async {
      final notifier = _FakeProjectNotifier(project: _kProject);
      await tester.pumpWidget(_wrap(notifier));
      await _awaitBody(tester);

      await tester.tap(find.text('Milestones'));
      await tester.pumpAndSettle();

      expect(find.text('Milestones coming soon'), findsOneWidget);
    });

    testWidgets('tapping Settings tab shows settings placeholder',
        (tester) async {
      final notifier = _FakeProjectNotifier(project: _kProject);
      await tester.pumpWidget(_wrap(notifier));
      await _awaitBody(tester);

      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();

      expect(find.text('Settings coming soon'), findsOneWidget);
    });

    testWidgets('copy button shows snackbar on tap', (tester) async {
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') return null;
          return null;
        },
      );
      addTearDown(() {
        tester.binding.defaultBinaryMessenger
            .setMockMethodCallHandler(SystemChannels.platform, null);
      });

      final notifier = _FakeProjectNotifier(project: _kProject);
      await tester.pumpWidget(_wrap(notifier));
      await _awaitBody(tester);

      await tester.tap(find.byIcon(Icons.copy_outlined));
      await tester.pump();

      expect(find.text('Link copied'), findsOneWidget);
    });

    testWidgets('rapid copy taps show only one snackbar', (tester) async {
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async => null,
      );
      addTearDown(() {
        tester.binding.defaultBinaryMessenger
            .setMockMethodCallHandler(SystemChannels.platform, null);
      });

      final notifier = _FakeProjectNotifier(project: _kProject);
      await tester.pumpWidget(_wrap(notifier));
      await _awaitBody(tester);

      await tester.tap(find.byIcon(Icons.copy_outlined));
      await tester.tap(find.byIcon(Icons.copy_outlined));
      await tester.tap(find.byIcon(Icons.copy_outlined));
      await tester.pump();

      expect(find.text('Link copied'), findsOneWidget);
    });

    testWidgets('shows retry button on load error', (tester) async {
      final notifier =
          _FakeProjectNotifier(failLoad: true, project: _kProject);
      await tester.pumpWidget(_wrap(notifier));
      await _awaitBody(tester);

      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('retry button is tappable and does not crash', (tester) async {
      final notifier =
          _FakeProjectNotifier(failLoad: true, project: _kProject);
      await tester.pumpWidget(_wrap(notifier));
      await _awaitBody(tester);

      await tester.tap(find.text('Retry'));
      await _awaitBody(tester);

      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('shows not-found state when project missing from list',
        (tester) async {
      final notifier = _FakeProjectNotifier(project: _kProject);
      await tester.pumpWidget(_wrap(notifier, projectId: 'nonexistent-id'));
      await _awaitBody(tester);

      expect(find.text('Project not found'), findsOneWidget);
    });
  });
}
