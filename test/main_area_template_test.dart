import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:main_area_template/main_area_template.dart';

void main() {
  Widget wrapWithMaterial(Widget child) {
    return MaterialApp(
      home: Scaffold(body: child),
    );
  }

  group('MainAreaTemplate', () {
    testWidgets('renders title and description', (tester) async {
      await tester.pumpWidget(wrapWithMaterial(
        MainAreaTemplate(
          title: 'Test Page',
          description: 'A test description',
          child: const Text('body'),
        ),
      ));

      expect(find.text('Test Page'), findsOneWidget);
      expect(find.text('A test description'), findsOneWidget);
      expect(find.text('body'), findsOneWidget);
    });

    testWidgets('renders icon when provided', (tester) async {
      await tester.pumpWidget(wrapWithMaterial(
        MainAreaTemplate(
          title: 'With Icon',
          icon: Icons.router,
          child: const Text('body'),
        ),
      ));

      expect(find.byIcon(Icons.router), findsOneWidget);
    });

    testWidgets('renders actions when provided', (tester) async {
      await tester.pumpWidget(wrapWithMaterial(
        MainAreaTemplate(
          title: 'With Actions',
          actions: [
            ElevatedButton(onPressed: () {}, child: const Text('Save')),
          ],
          child: const Text('body'),
        ),
      ));

      expect(find.text('Save'), findsOneWidget);
    });

    testWidgets('renders without description or icon', (tester) async {
      await tester.pumpWidget(wrapWithMaterial(
        MainAreaTemplate(
          title: 'Minimal',
          child: const Text('body'),
        ),
      ));

      expect(find.text('Minimal'), findsOneWidget);
      expect(find.text('body'), findsOneWidget);
    });
  });
}
