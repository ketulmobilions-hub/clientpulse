import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:clientpulse/features/portal/presentation/widgets/portal_milestone_section.dart';
import 'package:clientpulse/shared/models/portal_overview.dart';

Widget _wrap(Widget child) =>
    MaterialApp(home: Scaffold(body: SingleChildScrollView(child: child)));

PortalMilestone _ms(int i, {bool completed = false, String? dueDate}) =>
    PortalMilestone(
      id: 'ms-$i',
      title: 'Milestone $i',
      completed: completed,
      position: i,
      dueDate: dueDate,
    );

PortalProgress _progress(List<PortalMilestone> milestones) {
  final done = milestones.where((m) => m.completed).length;
  final total = milestones.length;
  return PortalProgress(
    total: total,
    completed: done,
    percent: total > 0 ? (done / total * 100) : 0,
  );
}

void main() {
  group('PortalMilestoneSection', () {
    testWidgets('renders all milestones when count ≤ 5', (tester) async {
      final milestones = List.generate(5, _ms);
      await tester.pumpWidget(_wrap(PortalMilestoneSection(
        milestones: milestones,
        progress: _progress(milestones),
      )));

      for (var i = 0; i < 5; i++) {
        expect(find.text('Milestone $i'), findsOneWidget);
      }
      expect(find.textContaining('Show all'), findsNothing);
    });

    testWidgets('collapses to 5 and shows button when count > 5',
        (tester) async {
      final milestones = List.generate(6, _ms);
      await tester.pumpWidget(_wrap(PortalMilestoneSection(
        milestones: milestones,
        progress: _progress(milestones),
      )));

      for (var i = 0; i < 5; i++) {
        expect(find.text('Milestone $i'), findsOneWidget);
      }
      expect(find.text('Milestone 5'), findsNothing);
      expect(find.text('Show all 6 milestones'), findsOneWidget);
    });

    testWidgets('tap "Show all" expands list and changes button label',
        (tester) async {
      final milestones = List.generate(6, _ms);
      await tester.pumpWidget(_wrap(PortalMilestoneSection(
        milestones: milestones,
        progress: _progress(milestones),
      )));

      await tester.tap(find.text('Show all 6 milestones'));
      await tester.pumpAndSettle();

      for (var i = 0; i < 6; i++) {
        expect(find.text('Milestone $i'), findsOneWidget);
      }
      expect(find.text('Show less'), findsOneWidget);
    });

    testWidgets('tap "Show less" collapses back to 5', (tester) async {
      final milestones = List.generate(6, _ms);
      await tester.pumpWidget(_wrap(PortalMilestoneSection(
        milestones: milestones,
        progress: _progress(milestones),
      )));

      await tester.tap(find.text('Show all 6 milestones'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Show less'));
      await tester.pumpAndSettle();

      expect(find.text('Milestone 5'), findsNothing);
      expect(find.text('Show all 6 milestones'), findsOneWidget);
    });

    testWidgets('renders due date as locale-formatted string', (tester) async {
      final milestones = [_ms(0, dueDate: '2026-06-01')];
      await tester.pumpWidget(_wrap(PortalMilestoneSection(
        milestones: milestones,
        progress: _progress(milestones),
      )));

      // Formatted by DateFormat('MMM d, y') → "Jun 1, 2026"
      expect(find.text('Jun 1, 2026'), findsOneWidget);
    });

    testWidgets('completed milestone has no due date text when absent',
        (tester) async {
      final milestones = [_ms(0, completed: true)];
      await tester.pumpWidget(_wrap(PortalMilestoneSection(
        milestones: milestones,
        progress: _progress(milestones),
      )));

      expect(find.text('Completed'), findsOneWidget);
    });

    testWidgets('past-due incomplete milestone shows Delayed pill',
        (tester) async {
      final milestones = [_ms(0, dueDate: '2000-01-01')];
      await tester.pumpWidget(_wrap(PortalMilestoneSection(
        milestones: milestones,
        progress: _progress(milestones),
      )));

      expect(find.text('Delayed'), findsOneWidget);
    });

    testWidgets('future-due incomplete milestone shows Upcoming pill',
        (tester) async {
      final milestones = [_ms(0, dueDate: '2099-12-31')];
      await tester.pumpWidget(_wrap(PortalMilestoneSection(
        milestones: milestones,
        progress: _progress(milestones),
      )));

      expect(find.text('Upcoming'), findsOneWidget);
    });

    testWidgets('counter label uses PortalProgress values, not recomputed count',
        (tester) async {
      // Simulate mismatched server response: progress says 2 done, but only 1
      // milestone has completed=true. Widget must trust PortalProgress for the
      // displayed label.
      final milestones = [_ms(0, completed: true), _ms(1), _ms(2)];
      const progress =
          PortalProgress(total: 3, completed: 2, percent: 67);
      await tester.pumpWidget(_wrap(PortalMilestoneSection(
        milestones: milestones,
        progress: progress,
      )));

      expect(find.text('2 of 3 • 67%'), findsOneWidget);
    });
  });
}
