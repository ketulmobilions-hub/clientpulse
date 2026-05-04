import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../models/portal_overview.dart';
import '../models/portal_update.dart';
import 'portal_service_provider.dart';

part 'portal_provider.g.dart';

@Riverpod(keepAlive: true)
Future<PortalOverview> portalOverview(PortalOverviewRef ref, String token) async {
  final cancelToken = CancelToken();
  ref.onDispose(cancelToken.cancel);
  final svc = await ref.watch(portalServiceProvider.future);
  return svc.getPortalOverview(token, cancelToken: cancelToken);
}

class PortalUpdatesState {
  const PortalUpdatesState({
    required this.updates,
    required this.total,
    this.isLoadingMore = false,
    this.loadMoreError,
  });

  final List<PortalUpdate> updates;
  final int total;
  final bool isLoadingMore;
  final String? loadMoreError;

  bool get hasMore => updates.length < total;

  PortalUpdatesState copyWith({
    List<PortalUpdate>? updates,
    int? total,
    bool? isLoadingMore,
    String? loadMoreError,
    bool clearError = false,
  }) {
    return PortalUpdatesState(
      updates: updates ?? this.updates,
      total: total ?? this.total,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      loadMoreError: clearError ? null : (loadMoreError ?? this.loadMoreError),
    );
  }
}

@riverpod
class PortalUpdatesNotifier extends _$PortalUpdatesNotifier {
  static const _limit = 20;
  int _currentPage = 1;
  // Instance flag checked before the first await — prevents double-tap race.
  bool _loading = false;

  @override
  Future<PortalUpdatesState> build(String token) async {
    _currentPage = 1;
    _loading = false;
    final cancelToken = CancelToken();
    ref.onDispose(cancelToken.cancel);
    final svc = await ref.watch(portalServiceProvider.future);
    final result = await svc.listPortalUpdates(token, page: 1, limit: _limit, cancelToken: cancelToken);
    return PortalUpdatesState(updates: result.updates, total: result.total);
  }

  Future<void> loadMore() async {
    if (_loading) return;
    final current = state.valueOrNull;
    if (current == null || !current.hasMore) return;
    _loading = true;
    state = AsyncData(current.copyWith(isLoadingMore: true, clearError: true));
    try {
      final svc = await ref.read(portalServiceProvider.future);
      _currentPage++;
      final result = await svc.listPortalUpdates(token, page: _currentPage, limit: _limit);
      final merged = [...current.updates, ...result.updates];
      state = AsyncData(PortalUpdatesState(updates: merged, total: result.total));
    } catch (e) {
      _currentPage--;
      state = AsyncData(current.copyWith(
        isLoadingMore: false,
        loadMoreError: e.toString(),
      ));
    } finally {
      _loading = false;
    }
  }
}
