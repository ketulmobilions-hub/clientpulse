// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'update_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$updateNotifierHash() => r'23842fe2465baabbd36e797baffa3bd3c6d409a1';

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

abstract class _$UpdateNotifier
    extends BuildlessAutoDisposeAsyncNotifier<List<Update>> {
  late final String projectId;

  FutureOr<List<Update>> build(
    String projectId,
  );
}

/// See also [UpdateNotifier].
@ProviderFor(UpdateNotifier)
const updateNotifierProvider = UpdateNotifierFamily();

/// See also [UpdateNotifier].
class UpdateNotifierFamily extends Family<AsyncValue<List<Update>>> {
  /// See also [UpdateNotifier].
  const UpdateNotifierFamily();

  /// See also [UpdateNotifier].
  UpdateNotifierProvider call(
    String projectId,
  ) {
    return UpdateNotifierProvider(
      projectId,
    );
  }

  @override
  UpdateNotifierProvider getProviderOverride(
    covariant UpdateNotifierProvider provider,
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
  String? get name => r'updateNotifierProvider';
}

/// See also [UpdateNotifier].
class UpdateNotifierProvider
    extends AutoDisposeAsyncNotifierProviderImpl<UpdateNotifier, List<Update>> {
  /// See also [UpdateNotifier].
  UpdateNotifierProvider(
    String projectId,
  ) : this._internal(
          () => UpdateNotifier()..projectId = projectId,
          from: updateNotifierProvider,
          name: r'updateNotifierProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$updateNotifierHash,
          dependencies: UpdateNotifierFamily._dependencies,
          allTransitiveDependencies:
              UpdateNotifierFamily._allTransitiveDependencies,
          projectId: projectId,
        );

  UpdateNotifierProvider._internal(
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
  FutureOr<List<Update>> runNotifierBuild(
    covariant UpdateNotifier notifier,
  ) {
    return notifier.build(
      projectId,
    );
  }

  @override
  Override overrideWith(UpdateNotifier Function() create) {
    return ProviderOverride(
      origin: this,
      override: UpdateNotifierProvider._internal(
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
  AutoDisposeAsyncNotifierProviderElement<UpdateNotifier, List<Update>>
      createElement() {
    return _UpdateNotifierProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is UpdateNotifierProvider && other.projectId == projectId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, projectId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin UpdateNotifierRef on AutoDisposeAsyncNotifierProviderRef<List<Update>> {
  /// The parameter `projectId` of this provider.
  String get projectId;
}

class _UpdateNotifierProviderElement
    extends AutoDisposeAsyncNotifierProviderElement<UpdateNotifier,
        List<Update>> with UpdateNotifierRef {
  _UpdateNotifierProviderElement(super.provider);

  @override
  String get projectId => (origin as UpdateNotifierProvider).projectId;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
