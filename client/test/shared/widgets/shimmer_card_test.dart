import 'package:clientpulse/shared/widgets/shimmer_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shimmer/shimmer.dart';

Widget _wrap(Widget child) =>
    MaterialApp(home: Scaffold(body: child));

void main() {
  group('ShimmerCard', () {
    testWidgets('renders without error', (tester) async {
      await tester.pumpWidget(_wrap(
        const ShimmerCard(height: 80),
      ));
      expect(find.byType(ShimmerCard), findsOneWidget);
    });

    testWidgets('uses Shimmer widget', (tester) async {
      await tester.pumpWidget(_wrap(
        const ShimmerCard(height: 80),
      ));
      expect(find.byType(Shimmer), findsOneWidget);
    });

    testWidgets('renders at given height', (tester) async {
      await tester.pumpWidget(_wrap(
        const Center(child: ShimmerCard(height: 60, width: 200)),
      ));
      final box = tester.renderObject<RenderBox>(
        find.byType(Container).first,
      );
      expect(box.size.height, 60);
    });

    testWidgets('exposes Semantics loading label', (tester) async {
      await tester.pumpWidget(_wrap(
        const ShimmerCard(height: 80),
      ));
      expect(
        tester.getSemantics(find.byType(ShimmerCard)),
        matchesSemantics(label: 'Loading'),
      );
    });
  });
}
