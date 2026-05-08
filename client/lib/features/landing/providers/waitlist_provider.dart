import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../shared/providers/api_service_provider.dart';
import '../data/waitlist_repository.dart';

part 'waitlist_provider.g.dart';

@riverpod
Future<WaitlistRepository> waitlistRepository(WaitlistRepositoryRef ref) async {
  final api = await ref.watch(apiServiceProvider.future);
  return WaitlistRepository(api);
}

@riverpod
class WaitlistController extends _$WaitlistController {
  @override
  FutureOr<void> build() {}

  Future<void> submit({
    required String email,
    String? referrer,
    String? utmSource,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repo = await ref.read(waitlistRepositoryProvider.future);
      await repo.submit(email: email, referrer: referrer, utmSource: utmSource);
    });
  }
}
