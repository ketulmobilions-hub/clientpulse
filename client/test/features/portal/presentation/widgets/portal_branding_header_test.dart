import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:clientpulse/features/portal/presentation/widgets/portal_branding_header.dart';
import 'package:clientpulse/shared/models/portal_overview.dart';

Widget _wrap(PortalBrandingHeader header) =>
    MaterialApp(home: Scaffold(appBar: header));

PortalWorkspace _workspace({String name = 'Acme Agency', String? logoUrl}) =>
    PortalWorkspace(name: name, slug: 'acme', logoUrl: logoUrl);

void main() {
  group('PortalBrandingHeader', () {
    testWidgets('no logo — renders agency name, no Image widget',
        (tester) async {
      await tester.pumpWidget(_wrap(PortalBrandingHeader(
        workspace: _workspace(),
      )));

      expect(find.text('Acme Agency'), findsOneWidget);
      expect(find.byType(Image), findsNothing);
    });

    testWidgets(
        'with logo URL — renders ClipRRect + Image.network + agency name',
        (tester) async {
      await tester.pumpWidget(_wrap(PortalBrandingHeader(
        workspace: _workspace(logoUrl: 'https://example.com/logo.png'),
      )));

      expect(find.byType(ClipRRect), findsOneWidget);
      expect(find.byType(Image), findsOneWidget);
      expect(find.text('Acme Agency'), findsOneWidget);
    });

    testWidgets(
        'image load failure — agency name appears exactly once, no duplicate',
        (tester) async {
      await tester.pumpWidget(_wrap(PortalBrandingHeader(
        workspace: _workspace(logoUrl: 'https://example.com/bad.png'),
      )));
      // Allow image loading attempt to resolve in test environment.
      await tester.pump();

      // errorBuilder returns SizedBox.shrink(); name rendered by Flexible(Text) only.
      expect(find.text('Acme Agency'), findsOneWidget);
    });

    testWidgets('empty name — renders fallback text "Portal"', (tester) async {
      await tester.pumpWidget(_wrap(PortalBrandingHeader(
        workspace: _workspace(name: ''),
      )));

      expect(find.text('Portal'), findsOneWidget);
    });

    testWidgets('long name — no RenderFlex overflow exception', (tester) async {
      const longName =
          'Southeastern Digital Marketing & Growth Agency LLC International';
      await tester.pumpWidget(_wrap(PortalBrandingHeader(
        workspace: _workspace(name: longName),
      )));

      expect(tester.takeException(), isNull);
      expect(find.byType(AppBar), findsOneWidget);
    });

    test('preferredSize returns kToolbarHeight', () {
      const header = PortalBrandingHeader(
        workspace: PortalWorkspace(name: 'Test', slug: 'test'),
      );
      expect(header.preferredSize, const Size.fromHeight(kToolbarHeight));
    });
  });
}
