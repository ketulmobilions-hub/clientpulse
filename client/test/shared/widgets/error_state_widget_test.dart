import 'package:clientpulse/shared/widgets/error_state_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) =>
    MaterialApp(home: Scaffold(body: child));

void main() {
  group('ErrorStateWidget', () {
    testWidgets('renders error icon and message', (tester) async {
      await tester.pumpWidget(_wrap(
        ErrorStateWidget(
          message: 'Network failed',
          onRetry: () {},
        ),
      ));

      expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);
      expect(find.text('Network failed'), findsOneWidget);
    });

    testWidgets('renders custom icon when provided', (tester) async {
      await tester.pumpWidget(_wrap(
        ErrorStateWidget(
          message: 'No internet',
          onRetry: () {},
          icon: Icons.wifi_off_rounded,
        ),
      ));

      expect(find.byIcon(Icons.wifi_off_rounded), findsOneWidget);
    });

    testWidgets('renders Retry button', (tester) async {
      await tester.pumpWidget(_wrap(
        ErrorStateWidget(
          message: 'Network failed',
          onRetry: () {},
        ),
      ));

      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('Retry button fires onRetry callback', (tester) async {
      var retried = false;
      await tester.pumpWidget(_wrap(
        ErrorStateWidget(
          message: 'Network failed',
          onRetry: () => retried = true,
        ),
      ));

      await tester.tap(find.text('Retry'));
      expect(retried, isTrue);
    });
  });
}
