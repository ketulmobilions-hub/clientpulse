import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/update.dart';
import 'update_service_provider.dart';

part 'update_provider.g.dart';

@Riverpod(keepAlive: true)
class UpdateNotifier extends _$UpdateNotifier {
  @override
  // Starts empty; populated by createUpdate() calls in-session.
  // A dedicated listUpdates() build will be wired up in the updates list issue.
  Future<List<Update>> build() async => [];

  Future<Update> createUpdate(
    String projectId, {
    required String title,
    required String body,
    required UpdateCategory category,
    String status = 'draft',
  }) async {
    final svc = await ref.read(updateServiceProvider.future);
    final update = await svc.createUpdate(
      projectId,
      title: title,
      body: body,
      category: category,
      status: status,
    );
    final current = state.valueOrNull ?? [];
    state = AsyncData([update, ...current]);
    return update;
  }

  void remove(String updateId) {
    final current = state.valueOrNull;
    // Don't clobber an in-flight load or error state — only remove from a known list.
    if (current == null) return;
    state = AsyncData(current.where((u) => u.id != updateId).toList());
  }

  void invalidate() => ref.invalidateSelf();
}
