// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'portal_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$portalOverviewHash() => r'f132f80a7da304d40a58922c52dd25632ea627e9';

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

/// See also [portalOverview].
@ProviderFor(portalOverview)
const portalOverviewProvider = PortalOverviewFamily();

/// See also [portalOverview].
class PortalOverviewFamily extends Family<AsyncValue<PortalOverview>> {
  /// See also [portalOverview].
  const PortalOverviewFamily();

  /// See also [portalOverview].
  PortalOverviewProvider call(
    String token,
  ) {
    return PortalOverviewProvider(
      token,
    );
  }

  @override
  PortalOverviewProvider getProviderOverride(
    covariant PortalOverviewProvider provider,
  ) {
    return call(
      provider.token,
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
  String? get name => r'portalOverviewProvider';
}

/// See also [portalOverview].
class PortalOverviewProvider extends FutureProvider<PortalOverview> {
  /// See also [portalOverview].
  PortalOverviewProvider(
    String token,
  ) : this._internal(
          (ref) => portalOverview(
            ref as PortalOverviewRef,
            token,
          ),
          from: portalOverviewProvider,
          name: r'portalOverviewProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$portalOverviewHash,
          dependencies: PortalOverviewFamily._dependencies,
          allTransitiveDependencies:
              PortalOverviewFamily._allTransitiveDependencies,
          token: token,
        );

  PortalOverviewProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.token,
  }) : super.internal();

  final String token;

  @override
  Override overrideWith(
    FutureOr<PortalOverview> Function(PortalOverviewRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: PortalOverviewProvider._internal(
        (ref) => create(ref as PortalOverviewRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        token: token,
      ),
    );
  }

  @override
  FutureProviderElement<PortalOverview> createElement() {
    return _PortalOverviewProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is PortalOverviewProvider && other.token == token;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, token.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin PortalOverviewRef on FutureProviderRef<PortalOverview> {
  /// The parameter `token` of this provider.
  String get token;
}

class _PortalOverviewProviderElement
    extends FutureProviderElement<PortalOverview> with PortalOverviewRef {
  _PortalOverviewProviderElement(super.provider);

  @override
  String get token => (origin as PortalOverviewProvider).token;
}

String _$portalUpdatesNotifierHash() =>
    r'93ff799a5d4a936c37039995c2a38f3c35bf219c';

abstract class _$PortalUpdatesNotifier
    extends BuildlessAutoDisposeAsyncNotifier<PortalUpdatesState> {
  late final String token;

  FutureOr<PortalUpdatesState> build(
    String token,
  );
}

/// See also [PortalUpdatesNotifier].
@ProviderFor(PortalUpdatesNotifier)
const portalUpdatesNotifierProvider = PortalUpdatesNotifierFamily();

/// See also [PortalUpdatesNotifier].
class PortalUpdatesNotifierFamily
    extends Family<AsyncValue<PortalUpdatesState>> {
  /// See also [PortalUpdatesNotifier].
  const PortalUpdatesNotifierFamily();

  /// See also [PortalUpdatesNotifier].
  PortalUpdatesNotifierProvider call(
    String token,
  ) {
    return PortalUpdatesNotifierProvider(
      token,
    );
  }

  @override
  PortalUpdatesNotifierProvider getProviderOverride(
    covariant PortalUpdatesNotifierProvider provider,
  ) {
    return call(
      provider.token,
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
  String? get name => r'portalUpdatesNotifierProvider';
}

/// See also [PortalUpdatesNotifier].
class PortalUpdatesNotifierProvider
    extends AutoDisposeAsyncNotifierProviderImpl<PortalUpdatesNotifier,
        PortalUpdatesState> {
  /// See also [PortalUpdatesNotifier].
  PortalUpdatesNotifierProvider(
    String token,
  ) : this._internal(
          () => PortalUpdatesNotifier()..token = token,
          from: portalUpdatesNotifierProvider,
          name: r'portalUpdatesNotifierProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$portalUpdatesNotifierHash,
          dependencies: PortalUpdatesNotifierFamily._dependencies,
          allTransitiveDependencies:
              PortalUpdatesNotifierFamily._allTransitiveDependencies,
          token: token,
        );

  PortalUpdatesNotifierProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.token,
  }) : super.internal();

  final String token;

  @override
  FutureOr<PortalUpdatesState> runNotifierBuild(
    covariant PortalUpdatesNotifier notifier,
  ) {
    return notifier.build(
      token,
    );
  }

  @override
  Override overrideWith(PortalUpdatesNotifier Function() create) {
    return ProviderOverride(
      origin: this,
      override: PortalUpdatesNotifierProvider._internal(
        () => create()..token = token,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        token: token,
      ),
    );
  }

  @override
  AutoDisposeAsyncNotifierProviderElement<PortalUpdatesNotifier,
      PortalUpdatesState> createElement() {
    return _PortalUpdatesNotifierProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is PortalUpdatesNotifierProvider && other.token == token;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, token.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin PortalUpdatesNotifierRef
    on AutoDisposeAsyncNotifierProviderRef<PortalUpdatesState> {
  /// The parameter `token` of this provider.
  String get token;
}

class _PortalUpdatesNotifierProviderElement
    extends AutoDisposeAsyncNotifierProviderElement<PortalUpdatesNotifier,
        PortalUpdatesState> with PortalUpdatesNotifierRef {
  _PortalUpdatesNotifierProviderElement(super.provider);

  @override
  String get token => (origin as PortalUpdatesNotifierProvider).token;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
