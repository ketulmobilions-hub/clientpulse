import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:clientpulse/main.dart';
import 'package:clientpulse/shared/providers/auth_state_provider.dart';
import 'helpers/router_test_helpers.dart';

void main() {
  testWidgets('app renders without error and shows login when unauthenticated', (WidgetTester tester) async {
    // Pre-resolve auth before building — prevents GoRouter from landing on
    // /loading (CircularProgressIndicator), which would block pumpAndSettle.
    final container = containerWithAuth(false);
    await container.read(isAuthenticatedProvider.future);
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const ClientPulseApp(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Sign In'), findsOneWidget);
  });
}
