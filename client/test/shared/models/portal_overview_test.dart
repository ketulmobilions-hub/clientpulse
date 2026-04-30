import 'package:flutter_test/flutter_test.dart';

import 'package:clientpulse/shared/models/milestone.dart';
import 'package:clientpulse/shared/models/portal_overview.dart';

PortalMilestone _milestone({
  bool completed = false,
  String? dueDate,
}) =>
    PortalMilestone(
      id: 'ms-1',
      title: 'Test',
      completed: completed,
      position: 0,
      dueDate: dueDate,
    );

void main() {
  group('PortalMilestoneStatusX.status', () {
    test('completed=true returns completed', () {
      expect(_milestone(completed: true).status, MilestoneStatus.completed);
    });

    test('completed=false, no dueDate returns upcoming', () {
      expect(_milestone().status, MilestoneStatus.upcoming);
    });

    test('completed=false, past dueDate returns delayed', () {
      expect(
        _milestone(dueDate: '2000-01-01').status,
        MilestoneStatus.delayed,
      );
    });

    test('completed=false, future dueDate returns upcoming', () {
      expect(
        _milestone(dueDate: '2099-12-31').status,
        MilestoneStatus.upcoming,
      );
    });

    test('completed=true with past dueDate still returns completed', () {
      // The completed guard must take priority over the dueDate check.
      expect(
        _milestone(completed: true, dueDate: '2000-01-01').status,
        MilestoneStatus.completed,
      );
    });

    test('dueDate = today returns upcoming (isBefore is exclusive)', () {
      final today = DateTime.now();
      final todayStr =
          '${today.year.toString().padLeft(4, '0')}-'
          '${today.month.toString().padLeft(2, '0')}-'
          '${today.day.toString().padLeft(2, '0')}';
      expect(_milestone(dueDate: todayStr).status, MilestoneStatus.upcoming);
    });

    test('malformed dueDate string falls back to upcoming', () {
      expect(_milestone(dueDate: 'not-a-date').status, MilestoneStatus.upcoming);
    });
  });
}
