import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/comment.dart';
import 'update_service_provider.dart';

part 'comment_provider.g.dart';

@riverpod
class CommentNotifier extends _$CommentNotifier {
  bool _posting = false;

  @override
  Future<List<Comment>> build(String updateId) async {
    final svc = await ref.read(updateServiceProvider.future);
    return svc.listComments(updateId);
  }

  Future<void> addComment(String body, {String? parentId}) async {
    // Guard: no concurrent posts; no post when list not yet loaded.
    if (_posting || !state.hasValue) return;
    _posting = true;
    try {
      final svc = await ref.read(updateServiceProvider.future);
      final comment = await svc.createComment(updateId, body, parentId: parentId);
      // Re-read state after await — another invalidation may have run.
      final current = state.valueOrNull ?? [];
      state = AsyncData([...current, comment]);
    } finally {
      _posting = false;
    }
  }
}
