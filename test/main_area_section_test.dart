import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_page_scaffold/flutter_page_scaffold.dart';

void main() {
  Widget wrapWithMaterial(Widget child) {
    return MaterialApp(
      home: Scaffold(body: child),
    );
  }

  group('MainAreaSection', () {
    testWidgets('renders label when provided', (tester) async {
      await tester.pumpWidget(wrapWithMaterial(
        const MainAreaSection(
          label: 'TOOLBAR',
          child: Text('content'),
        ),
      ));

      expect(find.text('TOOLBAR'), findsOneWidget);
      expect(find.text('content'), findsOneWidget);
    });

    testWidgets('renders without label', (tester) async {
      await tester.pumpWidget(wrapWithMaterial(
        const MainAreaSection(
          child: Text('content only'),
        ),
      ));

      expect(find.text('content only'), findsOneWidget);
    });

    testWidgets('wraps child in Expanded when expanded=true', (tester) async {
      await tester.pumpWidget(wrapWithMaterial(
        Column(
          children: [
            MainAreaSection(
              expanded: true,
              child: Container(),
            ),
          ],
        ),
      ));

      expect(find.byType(Expanded), findsWidgets);
    });
  });
}
