import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:clientpulse/features/dashboard/presentation/widgets/project_card.dart';
import 'package:clientpulse/shared/models/project.dart';

Project _project({
  String name = 'Website Redesign',
  String client = 'Acme Corp',
  ProjectStatus status = ProjectStatus.active,
  int? updateCount,
  int? commentCount,
  String? latestUpdateTitle,
  int? progressPct,
}) {
  return Project(
    id: 'p1',
    workspaceId: 'ws1',
    name: name,
    clientName: client,
    clientEmail: 'c@acme.com',
    status: status,
    createdAt: DateTime.utc(2026, 5, 1),
    updatedAt: DateTime.utc(2026, 5, 5),
    updateCount: updateCount,
    commentCount: commentCount,
    latestUpdateTitle: latestUpdateTitle,
    progressPct: progressPct,
  );
}

/// Returns (widget, router) so tests can inspect the router after a tap.
({Widget widget, GoRouter router}) _wrapWithRouter(Project project) {
  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (_, __) => Scaffold(body: ProjectCard(project: project)),
      ),
      GoRoute(
        name: 'project-detail',
        path: '/projects/:id',
        builder: (_, state) => Scaffold(
          body: Text('detail-${state.pathParameters['id']}'),
        ),
      ),
    ],
  );
  return (widget: MaterialApp.router(routerConfig: router), router: router);
}

Widget _wrap(Project project) => _wrapWithRouter(project).widget;

void main() {
  group('ProjectCard', () {
    testWidgets('renders project name and client name', (tester) async {
      await tester.pumpWidget(_wrap(_project()));
      await tester.pump();

      expect(find.text('Website Redesign'), findsOneWidget);
      expect(find.text('Acme Corp'), findsOneWidget);
    });

    testWidgets('shows update count with correct singular/plural form', (tester) async {
      await tester.pumpWidget(_wrap(_project(updateCount: 1)));
      await tester.pump();
      expect(find.text('1 update'), findsOneWidget);

      await tester.pumpWidget(_wrap(_project(updateCount: 3)));
      await tester.pump();
      expect(find.text('3 updates'), findsOneWidget);
    });

    testWidgets('hides comment count when zero, shows when positive', (tester) async {
      await tester.pumpWidget(_wrap(_project(commentCount: 0)));
      await tester.pump();
      expect(find.textContaining('comment'), findsNothing);

      await tester.pumpWidget(_wrap(_project(commentCount: 2)));
      await tester.pump();
      expect(find.text('2 comments'), findsOneWidget);
    });

    testWidgets('renders latest update preview when present', (tester) async {
      await tester.pumpWidget(_wrap(_project(latestUpdateTitle: 'Homepage design ready')));
      await tester.pump();
      expect(find.text('Last update: "Homepage design ready"'), findsOneWidget);
    });

    testWidgets('omits latest update line when null', (tester) async {
      await tester.pumpWidget(_wrap(_project()));
      await tester.pump();
      expect(find.textContaining('Last update:'), findsNothing);
    });

    testWidgets('renders progress bar with percent label when progressPct set', (tester) async {
      await tester.pumpWidget(_wrap(_project(progressPct: 60)));
      await tester.pump();
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      expect(find.text('60%'), findsOneWidget);
    });

    testWidgets('omits progress bar when progressPct null', (tester) async {
      await tester.pumpWidget(_wrap(_project()));
      await tester.pump();
      expect(find.byType(LinearProgressIndicator), findsNothing);
    });

    testWidgets('archived project is wrapped in Opacity + ColorFiltered', (tester) async {
      await tester.pumpWidget(_wrap(_project(status: ProjectStatus.archived)));
      await tester.pump();
      expect(find.byType(Opacity), findsWidgets);
      expect(find.byType(ColorFiltered), findsOneWidget);
    });

    testWidgets('active project is NOT grayscale-filtered', (tester) async {
      await tester.pumpWidget(_wrap(_project(status: ProjectStatus.active)));
      await tester.pump();
      expect(find.byType(ColorFiltered), findsNothing);
    });

    testWidgets('hides update count when zero', (tester) async {
      // updateCount: 0 should be hidden (consistent with comment-count handling).
      await tester.pumpWidget(_wrap(_project(updateCount: 0)));
      await tester.pump();
      expect(find.textContaining('update'), findsNothing);
    });

    testWidgets('renders 0% progress when progressPct is 0', (tester) async {
      // progressPct: 0 means milestones exist but none are complete.
      // This is semantically distinct from null (no milestones) and must render.
      await tester.pumpWidget(_wrap(_project(progressPct: 0)));
      await tester.pump();
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      expect(find.text('0%'), findsOneWidget);
    });

    testWidgets('clamps progressPct over 100 to 100%', (tester) async {
      // Defensive: a backend bug shouldn't render "150%" in the UI.
      await tester.pumpWidget(_wrap(_project(progressPct: 150)));
      await tester.pump();
      expect(find.text('100%'), findsOneWidget);
      expect(find.text('150%'), findsNothing);

      final indicator = tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator),
      );
      expect(indicator.value, 1.0);
    });

    testWidgets('clamps negative progressPct to 0%', (tester) async {
      await tester.pumpWidget(_wrap(_project(progressPct: -5)));
      await tester.pump();
      expect(find.text('0%'), findsOneWidget);

      final indicator = tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator),
      );
      expect(indicator.value, 0.0);
    });

    testWidgets('archived progress bar uses outline (not primary) color', (tester) async {
      await tester.pumpWidget(
        _wrap(_project(status: ProjectStatus.archived, progressPct: 50)),
      );
      await tester.pump();

      final element = tester.element(find.byType(LinearProgressIndicator));
      final theme = Theme.of(element);
      final indicator = tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator),
      );
      expect(indicator.valueColor?.value, theme.colorScheme.outline);
    });

    testWidgets('tap navigates to project detail route', (tester) async {
      final harness = _wrapWithRouter(_project());
      await tester.pumpWidget(harness.widget);
      await tester.pump();

      // Sanity: detail body is not rendered initially.
      expect(find.text('detail-p1'), findsNothing);

      await tester.tap(find.byType(InkWell).first);
      await tester.pumpAndSettle();

      expect(find.text('detail-p1'), findsOneWidget);
      expect(harness.router.routerDelegate.currentConfiguration.uri.path,
          '/projects/p1');
    });
  });
}
