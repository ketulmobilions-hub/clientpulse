import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:clientpulse/main.dart';
import 'package:clientpulse/shared/providers/auth_state_provider.dart';

void main() {
  testWidgets('app renders without error and shows login when unauthenticated', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          // Override to avoid real SharedPreferences platform channel in tests.
          isAuthenticatedProvider.overrideWith((_) async => false),
        ],
        child: const ClientPulseApp(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Login'), findsOneWidget);
  });
}
