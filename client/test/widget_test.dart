import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:clientpulse/main.dart';

void main() {
  testWidgets('app renders without error', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: ClientPulseApp()));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('home_label')), findsOneWidget);
  });
}
