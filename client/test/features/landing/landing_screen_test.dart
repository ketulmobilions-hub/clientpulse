import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:clientpulse/features/landing/presentation/screens/landing_screen.dart';

void main() {
  testWidgets('LandingScreen renders hero headline and FAQ items', (tester) async {
    tester.view.physicalSize = const Size(1280, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: LandingScreen()),
      ),
    );
    await tester.pump();

    expect(find.text('Stop chasing client status. Show it.'), findsOneWidget);
    expect(find.text("Three steps. That's the product."), findsOneWidget);
    expect(find.text('What you get on every plan'), findsOneWidget);
    expect(find.text('Pricing'), findsOneWidget);
    expect(find.text('Common questions'), findsOneWidget);
    expect(find.text('ClientPulse · Built in Mumbai'), findsOneWidget);
  });

  testWidgets('Renders on narrow mobile viewport without overflow', (tester) async {
    tester.view.physicalSize = const Size(375, 4800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: LandingScreen()),
      ),
    );
    await tester.pump();

    expect(find.text('Stop chasing client status. Show it.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
