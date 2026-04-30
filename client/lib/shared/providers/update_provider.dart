import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/update.dart';
import 'update_service_provider.dart';

part 'update_provider.g.dart';

@riverpod
class UpdateNotifier extends _$UpdateNotifier {
  @override
  Future<List<Update>> build(String projectId) async {
    final svc = await ref.read(updateServiceProvider.future);
    return svc.listUpdates(projectId);
  }

  Future<void> load() async {
    ref.invalidateSelf();
    await future;
  }

  Future<Update> createUpdate({
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
    state = AsyncData([update.copyWith(attachmentCount: 0), ...current]);
    return update;
  }

  void remove(String updateId) {
    final current = state.valueOrNull;
    // Don't clobber an in-flight load or error state — only remove from a known list.
    if (current == null) return;
    state = AsyncData(current.where((u) => u.id != updateId).toList());
  }
}
