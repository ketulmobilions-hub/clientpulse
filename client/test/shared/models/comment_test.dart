import 'package:flutter_test/flutter_test.dart';
import 'package:clientpulse/shared/models/comment.dart';

void main() {
  const json = {
    'id': 'c-1',
    'update_id': 'u-1',
    'parent_id': null,
    'author_id': 'user-1',
    'author_type': 'agency',
    'author_name': 'Alice',
    'body': 'Looks good!',
    'created_at': '2026-01-01T10:00:00.000Z',
    'updated_at': '2026-01-01T10:00:00.000Z',
  };

  group('Comment.fromJson', () {
    test('deserializes all fields correctly', () {
      final c = Comment.fromJson(json);
      expect(c.id, 'c-1');
      expect(c.updateId, 'u-1');
      expect(c.parentId, isNull);
      expect(c.authorId, 'user-1');
      expect(c.authorType, CommentAuthorType.agency);
      expect(c.authorName, 'Alice');
      expect(c.body, 'Looks good!');
      expect(c.createdAt, isA<DateTime>());
      expect(c.updatedAt, isA<DateTime>());
    });

    test('parses createdAt as local DateTime', () {
      final c = Comment.fromJson(json);
      expect(c.createdAt.isUtc, isFalse);
    });

    test('nullable parentId defaults to null', () {
      final c = Comment.fromJson(json);
      expect(c.parentId, isNull);
    });

    test('parentId set when present', () {
      final c = Comment.fromJson({...json, 'parent_id': 'c-parent'});
      expect(c.parentId, 'c-parent');
    });

    test('client author_type preserved', () {
      final c = Comment.fromJson({...json, 'author_type': 'client', 'author_id': null});
      expect(c.authorType, CommentAuthorType.client);
      expect(c.authorId, isNull);
    });
  });

  group('Comment round-trip', () {
    test('toJson → fromJson produces equal object', () {
      final original = Comment.fromJson(json);
      final roundTripped = Comment.fromJson(original.toJson());
      expect(roundTripped, original);
    });
  });
}
