import 'package:clientpulse/shared/widgets/empty_state_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) =>
    MaterialApp(home: Scaffold(body: child));

void main() {
  group('EmptyStateWidget', () {
    testWidgets('renders icon and message', (tester) async {
      await tester.pumpWidget(_wrap(
        const EmptyStateWidget(
          icon: Icons.folder_open_outlined,
          message: 'Nothing here',
        ),
      ));

      expect(find.byIcon(Icons.folder_open_outlined), findsOneWidget);
      expect(find.text('Nothing here'), findsOneWidget);
    });

    testWidgets('shows CTA button when actionLabel provided', (tester) async {
      await tester.pumpWidget(_wrap(
        EmptyStateWidget(
          icon: Icons.folder_open_outlined,
          message: 'Nothing here',
          actionLabel: 'Add Item',
          onAction: () {},
        ),
      ));

      expect(find.text('Add Item'), findsOneWidget);
    });

    testWidgets('CTA button fires onAction callback', (tester) async {
      var tapped = false;
      await tester.pumpWidget(_wrap(
        EmptyStateWidget(
          icon: Icons.folder_open_outlined,
          message: 'Nothing here',
          actionLabel: 'Add Item',
          onAction: () => tapped = true,
        ),
      ));

      await tester.tap(find.text('Add Item'));
      expect(tapped, isTrue);
    });

    testWidgets('no CTA button when actionLabel is null', (tester) async {
      await tester.pumpWidget(_wrap(
        const EmptyStateWidget(
          icon: Icons.folder_open_outlined,
          message: 'Nothing here',
        ),
      ));

      expect(find.byType(FilledButton), findsNothing);
    });
  });
}
