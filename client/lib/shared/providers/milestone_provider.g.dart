// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'milestone_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$milestoneNotifierHash() => r'099a274de22d2dc5c3951357961aa084d90655be';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

abstract class _$MilestoneNotifier
    extends BuildlessAutoDisposeAsyncNotifier<List<Milestone>> {
  late final String projectId;

  FutureOr<List<Milestone>> build(
    String projectId,
  );
}

/// See also [MilestoneNotifier].
@ProviderFor(MilestoneNotifier)
const milestoneNotifierProvider = MilestoneNotifierFamily();

/// See also [MilestoneNotifier].
class MilestoneNotifierFamily extends Family<AsyncValue<List<Milestone>>> {
  /// See also [MilestoneNotifier].
  const MilestoneNotifierFamily();

  /// See also [MilestoneNotifier].
  MilestoneNotifierProvider call(
    String projectId,
  ) {
    return MilestoneNotifierProvider(
      projectId,
    );
  }

  @override
  MilestoneNotifierProvider getProviderOverride(
    covariant MilestoneNotifierProvider provider,
  ) {
    return call(
      provider.projectId,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'milestoneNotifierProvider';
}

/// See also [MilestoneNotifier].
class MilestoneNotifierProvider extends AutoDisposeAsyncNotifierProviderImpl<
    MilestoneNotifier, List<Milestone>> {
  /// See also [MilestoneNotifier].
  MilestoneNotifierProvider(
    String projectId,
  ) : this._internal(
          () => MilestoneNotifier()..projectId = projectId,
          from: milestoneNotifierProvider,
          name: r'milestoneNotifierProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$milestoneNotifierHash,
          dependencies: MilestoneNotifierFamily._dependencies,
          allTransitiveDependencies:
              MilestoneNotifierFamily._allTransitiveDependencies,
          projectId: projectId,
        );

  MilestoneNotifierProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.projectId,
  }) : super.internal();

  final String projectId;

  @override
  FutureOr<List<Milestone>> runNotifierBuild(
    covariant MilestoneNotifier notifier,
  ) {
    return notifier.build(
      projectId,
    );
  }

  @override
  Override overrideWith(MilestoneNotifier Function() create) {
    return ProviderOverride(
      origin: this,
      override: MilestoneNotifierProvider._internal(
        () => create()..projectId = projectId,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        projectId: projectId,
      ),
    );
  }

  @override
  AutoDisposeAsyncNotifierProviderElement<MilestoneNotifier, List<Milestone>>
      createElement() {
    return _MilestoneNotifierProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is MilestoneNotifierProvider && other.projectId == projectId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, projectId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin MilestoneNotifierRef
    on AutoDisposeAsyncNotifierProviderRef<List<Milestone>> {
  /// The parameter `projectId` of this provider.
  String get projectId;
}

class _MilestoneNotifierProviderElement
    extends AutoDisposeAsyncNotifierProviderElement<MilestoneNotifier,
        List<Milestone>> with MilestoneNotifierRef {
  _MilestoneNotifierProviderElement(super.provider);

  @override
  String get projectId => (origin as MilestoneNotifierProvider).projectId;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
