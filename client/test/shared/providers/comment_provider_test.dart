import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:clientpulse/shared/models/comment.dart';
// CommentAuthorType used in _makeComment helper
import 'package:clientpulse/shared/providers/comment_provider.dart';
import 'package:clientpulse/shared/providers/update_service_provider.dart';
import 'package:clientpulse/shared/services/update_service.dart';
import 'package:clientpulse/shared/models/update.dart';

class _FakeUpdateService implements UpdateService {
  _FakeUpdateService({List<Comment>? comments}) : _comments = comments ?? [];

  final List<Comment> _comments;
  int _nextId = 1;

  @override
  Future<List<Comment>> listComments(String updateId) async =>
      List.unmodifiable(_comments);

  @override
  Future<Comment> createComment(String updateId, String body,
      {String? parentId}) async {
    final c = _makeComment(
      id: 'c-${_nextId++}',
      updateId: updateId,
      body: body,
      parentId: parentId,
    );
    _comments.add(c);
    return c;
  }

  // Unused methods — satisfy interface
  @override
  Future<Update> createUpdate(String projectId,
          {required String title,
          required String body,
          required UpdateCategory category,
          String status = 'draft'}) async =>
      throw UnimplementedError();

  @override
  Future<List<Update>> listUpdates(String projectId) async => [];

  @override
  Future<void> deleteUpdate(String updateId) async {}
}

Comment _makeComment({
  required String id,
  String updateId = 'u-1',
  String? parentId,
  CommentAuthorType authorType = CommentAuthorType.agency,
  String authorName = 'Alice',
  required String body,
}) =>
    Comment(
      id: id,
      updateId: updateId,
      parentId: parentId,
      authorId: 'user-1',
      authorType: authorType,
      authorName: authorName,
      body: body,
      createdAt: DateTime(2026, 1, 1, 10),
      updatedAt: DateTime(2026, 1, 1, 10),
    );

ProviderContainer _container(_FakeUpdateService svc) => ProviderContainer(
      overrides: [
        updateServiceProvider.overrideWith((_) async => svc),
      ],
    );

void main() {
  group('CommentNotifier', () {
    test('build loads existing comments', () async {
      final initial = [_makeComment(id: 'c-1', body: 'Hello')];
      final container = _container(_FakeUpdateService(comments: initial));
      addTearDown(container.dispose);

      final comments =
          await container.read(commentNotifierProvider('u-1').future);
      expect(comments.length, 1);
      expect(comments.first.body, 'Hello');
    });

    test('build returns empty list when no comments', () async {
      final container = _container(_FakeUpdateService());
      addTearDown(container.dispose);

      final comments =
          await container.read(commentNotifierProvider('u-1').future);
      expect(comments, isEmpty);
    });

    test('addComment appends comment to state', () async {
      final container = _container(_FakeUpdateService());
      addTearDown(container.dispose);

      // Wait for initial load
      await container.read(commentNotifierProvider('u-1').future);

      await container
          .read(commentNotifierProvider('u-1').notifier)
          .addComment('New comment');

      final comments =
          await container.read(commentNotifierProvider('u-1').future);
      expect(comments.length, 1);
      expect(comments.first.body, 'New comment');
    });

    test('addComment with parentId passes it through', () async {
      final initial = [_makeComment(id: 'c-1', body: 'Parent')];
      final container = _container(_FakeUpdateService(comments: initial));
      addTearDown(container.dispose);

      await container.read(commentNotifierProvider('u-1').future);

      await container
          .read(commentNotifierProvider('u-1').notifier)
          .addComment('Reply', parentId: 'c-1');

      final comments =
          await container.read(commentNotifierProvider('u-1').future);
      expect(comments.length, 2);
      expect(comments.last.parentId, 'c-1');
    });

    test('multiple addComment calls accumulate', () async {
      final container = _container(_FakeUpdateService());
      addTearDown(container.dispose);

      await container.read(commentNotifierProvider('u-1').future);
      final notifier =
          container.read(commentNotifierProvider('u-1').notifier);

      await notifier.addComment('First');
      await notifier.addComment('Second');

      final comments =
          await container.read(commentNotifierProvider('u-1').future);
      expect(comments.length, 2);
      expect(comments[0].body, 'First');
      expect(comments[1].body, 'Second');
    });
  });
}
