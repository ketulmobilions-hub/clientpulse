import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:clientpulse/shared/providers/auth_state_provider.dart';

part 'router_notifier.g.dart';

// Synchronous Notifier<void> — build() sets up the auth listener and returns
// immediately. Keeping it sync prevents a silent failure mode where an async
// build() that throws would brick the notifier before the listener is registered.
@Riverpod(keepAlive: true)
class RouterNotifier extends _$RouterNotifier implements Listenable {
  final List<VoidCallback> _listeners = [];

  @override
  void build() {
    ref.listen(isAuthenticatedProvider, (_, __) => notifyListeners());
  }

  @override
  void addListener(VoidCallback listener) => _listeners.add(listener);

  @override
  void removeListener(VoidCallback listener) => _listeners.remove(listener);

  void notifyListeners() {
    for (final listener in List.of(_listeners)) {
      listener();
    }
  }
}
