import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:clientpulse/features/portal/presentation/screens/portal_screen.dart';
import 'package:clientpulse/shared/models/portal_overview.dart';
import 'package:clientpulse/shared/providers/portal_provider.dart';
import 'package:clientpulse/shared/services/portal_service.dart';

// Valid 32-char hex token — matches PortalService._validateToken regex.
const _kToken = 'a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4';

final _kWorkspace = PortalWorkspace(name: 'Acme Agency', slug: 'acme-agency');
final _kProject = PortalProject(
  id: 'proj-1',
  name: 'Website Redesign',
  clientName: 'Acme Corp',
  status: PortalProjectStatus.active,
);

PortalOverview _overview({
  required List<PortalMilestone> milestones,
  required PortalProgress progress,
}) =>
    PortalOverview(
      workspace: _kWorkspace,
      project: _kProject,
      milestones: milestones,
      progress: progress,
    );

class _FakeUpdatesNotifier extends PortalUpdatesNotifier {
  @override
  Future<PortalUpdatesState> build(String token) async =>
      PortalUpdatesState(updates: const [], total: 0);
}

Widget _wrap(PortalOverview overview) => ProviderScope(
      overrides: [
        portalOverviewProvider(_kToken).overrideWith((_) async => overview),
        portalUpdatesNotifierProvider(_kToken)
            .overrideWith(() => _FakeUpdatesNotifier()),
      ],
      child: const MaterialApp(home: PortalScreen(token: _kToken)),
    );

Widget _wrapError(Object error) => ProviderScope(
      overrides: [
        portalOverviewProvider(_kToken)
            .overrideWith((_) => Future.error(error)),
        portalUpdatesNotifierProvider(_kToken)
            .overrideWith(() => _FakeUpdatesNotifier()),
      ],
      child: const MaterialApp(home: PortalScreen(token: _kToken)),
    );

void main() {
  group('PortalScreen progress bar', () {
    testWidgets('shows "X of Y • Z%" label when milestones exist',
        (tester) async {
      final milestones = [
        PortalMilestone(
            id: 'ms-1', title: 'Discovery', completed: true, position: 0),
        PortalMilestone(
            id: 'ms-2', title: 'Design', completed: false, position: 1),
      ];
      final overview = _overview(
        milestones: milestones,
        progress: const PortalProgress(total: 2, completed: 1, percent: 50),
      );

      await tester.pumpWidget(_wrap(overview));
      await tester.pumpAndSettle();

      expect(find.text('1 of 2 • 50%'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });

    testWidgets('hides progress bar when no milestones', (tester) async {
      final overview = _overview(
        milestones: const [],
        progress: const PortalProgress(total: 0, completed: 0, percent: 0),
      );

      await tester.pumpWidget(_wrap(overview));
      await tester.pumpAndSettle();

      expect(find.byType(LinearProgressIndicator), findsNothing);
      expect(find.text('Milestones'), findsNothing);
    });

    testWidgets('rounds fractional percent in label', (tester) async {
      final milestones = List.generate(
        3,
        (i) => PortalMilestone(
            id: 'ms-$i', title: 'M$i', completed: i == 0, position: i),
      );
      // 1/3 = 33.33... → backend rounds to 33
      final overview = _overview(
        milestones: milestones,
        progress: const PortalProgress(total: 3, completed: 1, percent: 33),
      );

      await tester.pumpWidget(_wrap(overview));
      await tester.pumpAndSettle();

      expect(find.text('1 of 3 • 33%'), findsOneWidget);
    });

    testWidgets('handles 100% without clamp overflow', (tester) async {
      final milestones = [
        PortalMilestone(
            id: 'ms-1', title: 'Done', completed: true, position: 0),
      ];
      final overview = _overview(
        milestones: milestones,
        progress: const PortalProgress(total: 1, completed: 1, percent: 100),
      );

      await tester.pumpWidget(_wrap(overview));
      await tester.pumpAndSettle();

      expect(find.text('1 of 1 • 100%'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      // No RangeError — bar renders without throwing
    });
  });

  group('PortalScreen error states', () {
    testWidgets('shows invalid-token message for INVALID_TOKEN error',
        (tester) async {
      await tester.pumpWidget(
        _wrapError(const PortalException('INVALID_TOKEN', 'Invalid or expired token')),
      );
      await tester.pumpAndSettle();

      expect(find.text('This link is invalid or has expired.'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsNothing);
    });

    testWidgets('shows generic error message for non-token errors',
        (tester) async {
      await tester.pumpWidget(_wrapError(Exception('Network error')));
      await tester.pumpAndSettle();

      expect(
        find.text('Something went wrong. Please try again later.'),
        findsOneWidget,
      );
    });
  });
}
