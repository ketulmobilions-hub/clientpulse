// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'waitlist_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$waitlistRepositoryHash() =>
    r'0dc2edb0b115147915bc2d41502863a690f20a81';

/// See also [waitlistRepository].
@ProviderFor(waitlistRepository)
final waitlistRepositoryProvider =
    AutoDisposeFutureProvider<WaitlistRepository>.internal(
  waitlistRepository,
  name: r'waitlistRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$waitlistRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef WaitlistRepositoryRef
    = AutoDisposeFutureProviderRef<WaitlistRepository>;
String _$waitlistControllerHash() =>
    r'42c352c0cbcef46f5bb26e7db2dc85ae4eb01bc7';

/// See also [WaitlistController].
@ProviderFor(WaitlistController)
final waitlistControllerProvider =
    AutoDisposeAsyncNotifierProvider<WaitlistController, void>.internal(
  WaitlistController.new,
  name: r'waitlistControllerProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$waitlistControllerHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$WaitlistController = AutoDisposeAsyncNotifier<void>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
