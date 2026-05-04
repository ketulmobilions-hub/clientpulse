// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'comment_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$commentNotifierHash() => r'de7906b6adf9698a0b53a8fa4fedd790159dc8a9';

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

abstract class _$CommentNotifier
    extends BuildlessAutoDisposeAsyncNotifier<List<Comment>> {
  late final String updateId;

  FutureOr<List<Comment>> build(
    String updateId,
  );
}

/// See also [CommentNotifier].
@ProviderFor(CommentNotifier)
const commentNotifierProvider = CommentNotifierFamily();

/// See also [CommentNotifier].
class CommentNotifierFamily extends Family<AsyncValue<List<Comment>>> {
  /// See also [CommentNotifier].
  const CommentNotifierFamily();

  /// See also [CommentNotifier].
  CommentNotifierProvider call(
    String updateId,
  ) {
    return CommentNotifierProvider(
      updateId,
    );
  }

  @override
  CommentNotifierProvider getProviderOverride(
    covariant CommentNotifierProvider provider,
  ) {
    return call(
      provider.updateId,
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
  String? get name => r'commentNotifierProvider';
}

/// See also [CommentNotifier].
class CommentNotifierProvider extends AutoDisposeAsyncNotifierProviderImpl<
    CommentNotifier, List<Comment>> {
  /// See also [CommentNotifier].
  CommentNotifierProvider(
    String updateId,
  ) : this._internal(
          () => CommentNotifier()..updateId = updateId,
          from: commentNotifierProvider,
          name: r'commentNotifierProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$commentNotifierHash,
          dependencies: CommentNotifierFamily._dependencies,
          allTransitiveDependencies:
              CommentNotifierFamily._allTransitiveDependencies,
          updateId: updateId,
        );

  CommentNotifierProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.updateId,
  }) : super.internal();

  final String updateId;

  @override
  FutureOr<List<Comment>> runNotifierBuild(
    covariant CommentNotifier notifier,
  ) {
    return notifier.build(
      updateId,
    );
  }

  @override
  Override overrideWith(CommentNotifier Function() create) {
    return ProviderOverride(
      origin: this,
      override: CommentNotifierProvider._internal(
        () => create()..updateId = updateId,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        updateId: updateId,
      ),
    );
  }

  @override
  AutoDisposeAsyncNotifierProviderElement<CommentNotifier, List<Comment>>
      createElement() {
    return _CommentNotifierProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is CommentNotifierProvider && other.updateId == updateId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, updateId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin CommentNotifierRef on AutoDisposeAsyncNotifierProviderRef<List<Comment>> {
  /// The parameter `updateId` of this provider.
  String get updateId;
}

class _CommentNotifierProviderElement
    extends AutoDisposeAsyncNotifierProviderElement<CommentNotifier,
        List<Comment>> with CommentNotifierRef {
  _CommentNotifierProviderElement(super.provider);

  @override
  String get updateId => (origin as CommentNotifierProvider).updateId;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
