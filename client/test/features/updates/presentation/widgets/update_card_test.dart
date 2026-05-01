import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:clientpulse/features/updates/presentation/widgets/update_card.dart';
import 'package:clientpulse/shared/models/comment.dart';
import 'package:clientpulse/shared/models/update.dart';
import 'package:clientpulse/shared/providers/comment_provider.dart';
import 'package:clientpulse/shared/providers/update_service_provider.dart';
import 'package:clientpulse/shared/services/update_service.dart';

class _FakeUpdateService implements UpdateService {
  @override
  Future<List<Comment>> listComments(String updateId) async => [];
  @override
  Future<Comment> createComment(String updateId, String body,
          {String? parentId}) async =>
      throw UnimplementedError();
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

Update _update({int commentCount = 0, int attachmentCount = 0}) => Update(
      id: 'u-1',
      projectId: 'p-1',
      authorId: 'a-1',
      title: 'Sprint 1 update',
      body: 'All done.',
      status: UpdateStatus.published,
      category: UpdateCategory.progress,
      position: 0,
      createdAt: '2026-01-01T10:00:00Z',
      updatedAt: '2026-01-01T10:00:00Z',
      attachmentCount: attachmentCount,
      commentCount: commentCount,
    );

Widget _wrap(Update update, {List<Override> overrides = const []}) =>
    ProviderScope(
      overrides: [
        updateServiceProvider.overrideWith((_) async => _FakeUpdateService()),
        ...overrides,
      ],
      child: MaterialApp(
        home: Scaffold(body: UpdateCard(update: update)),
      ),
    );

void main() {
  group('UpdateCard', () {
    testWidgets('renders update title', (tester) async {
      await tester.pumpWidget(_wrap(_update()));
      expect(find.text('Sprint 1 update'), findsOneWidget);
    });

    testWidgets('comment section hidden when collapsed', (tester) async {
      await tester.pumpWidget(_wrap(_update()));
      expect(find.text('Comments'), findsNothing);
      expect(find.text('Post'), findsNothing);
    });

    testWidgets('no comment badge when commentCount is 0', (tester) async {
      await tester.pumpWidget(_wrap(_update(commentCount: 0)));
      expect(find.text('0 comments'), findsNothing);
    });

    testWidgets('comment badge shown when commentCount > 0', (tester) async {
      await tester.pumpWidget(_wrap(_update(commentCount: 3)));
      expect(find.text('3 comments'), findsOneWidget);
    });

    testWidgets('comment badge shows singular for count 1', (tester) async {
      await tester.pumpWidget(_wrap(_update(commentCount: 1)));
      expect(find.text('1 comment'), findsOneWidget);
    });

    testWidgets('tapping card expands comment section', (tester) async {
      await tester.pumpWidget(_wrap(_update()));
      await tester.tap(find.byType(InkWell).first);
      await tester.pump();
      // AgencyCommentSection renders (loading state is initial)
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('tapping card again collapses comment section', (tester) async {
      await tester.pumpWidget(_wrap(_update()));

      // Expand
      await tester.tap(find.byType(InkWell).first);
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Collapse
      await tester.tap(find.byType(InkWell).first);
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('attachment count shown when attachmentCount > 0',
        (tester) async {
      await tester.pumpWidget(_wrap(_update(attachmentCount: 2)));
      expect(find.text('2 attachments'), findsOneWidget);
    });

    testWidgets('comment section shows reply input after load', (tester) async {
      final loadedComments = <Comment>[];
      final container = ProviderContainer(overrides: [
        updateServiceProvider.overrideWith((_) async => _FakeUpdateService()),
        commentNotifierProvider('u-1').overrideWith(
          () => _FakeCommentNotifier(loadedComments),
        ),
      ]);
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(body: UpdateCard(update: _update())),
          ),
        ),
      );

      // Expand card
      await tester.tap(find.byType(InkWell).first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Post'), findsOneWidget);
    });
  });
}

class _FakeCommentNotifier extends CommentNotifier {
  _FakeCommentNotifier(this._comments);
  final List<Comment> _comments;

  @override
  Future<List<Comment>> build(String updateId) async => _comments;
}
