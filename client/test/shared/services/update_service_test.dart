import 'package:flutter_test/flutter_test.dart';
import 'package:clientpulse/shared/models/update.dart';

void main() {
  group('UpdateCategory.fromApi', () {
    test('maps all 5 backend values', () {
      expect(UpdateCategory.fromApi('progress'), UpdateCategory.progress);
      expect(UpdateCategory.fromApi('milestone'), UpdateCategory.milestone);
      expect(UpdateCategory.fromApi('deliverable'), UpdateCategory.deliverable);
      expect(UpdateCategory.fromApi('blocker'), UpdateCategory.blocker);
      expect(UpdateCategory.fromApi('input_needed'), UpdateCategory.inputNeeded);
    });

    test('falls back to progress for unknown value', () {
      expect(UpdateCategory.fromApi('general'), UpdateCategory.progress);
      expect(UpdateCategory.fromApi('unknown_future_value'), UpdateCategory.progress);
    });
  });

  group('UpdateCategory.apiValue', () {
    test('inputNeeded serializes to input_needed', () {
      expect(UpdateCategory.inputNeeded.apiValue, 'input_needed');
    });

    test('other values serialize to their enum name', () {
      expect(UpdateCategory.progress.apiValue, 'progress');
      expect(UpdateCategory.milestone.apiValue, 'milestone');
      expect(UpdateCategory.deliverable.apiValue, 'deliverable');
      expect(UpdateCategory.blocker.apiValue, 'blocker');
    });
  });

  group('UpdateCategory.displayLabel', () {
    test('returns human-readable labels', () {
      expect(UpdateCategory.progress.displayLabel, 'Progress');
      expect(UpdateCategory.milestone.displayLabel, 'Milestone');
      expect(UpdateCategory.deliverable.displayLabel, 'Deliverable');
      expect(UpdateCategory.blocker.displayLabel, 'Blocker');
      expect(UpdateCategory.inputNeeded.displayLabel, 'Input Needed');
    });
  });

  group('Update.fromJson', () {
    const json = {
      'id': 'abc-123',
      'project_id': 'proj-1',
      'author_id': 'user-1',
      'title': 'Week 1 Progress',
      'body': 'Done with backend',
      'status': 'draft',
      'category': 'input_needed',
      'position': 0,
      'notification_sent_at': null,
      'created_at': '2026-01-01T00:00:00Z',
      'updated_at': '2026-01-01T00:00:00Z',
    };

    test('deserializes all fields correctly', () {
      final update = Update.fromJson(json);
      expect(update.id, 'abc-123');
      expect(update.projectId, 'proj-1');
      expect(update.authorId, 'user-1');
      expect(update.title, 'Week 1 Progress');
      expect(update.body, 'Done with backend');
      expect(update.status, 'draft');
      expect(update.category, UpdateCategory.inputNeeded);
      expect(update.position, 0);
      expect(update.notificationSentAt, isNull);
    });

    test('round-trips category through toJson', () {
      final update = Update.fromJson(json);
      final out = update.toJson();
      expect(out['category'], 'input_needed');
    });
  });
}
