import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_page_scaffold/flutter_page_scaffold.dart';

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

  group('PageTab', () {
    test('stores label, icon, and child', () {
      const tab = PageTab(
        label: 'Devices',
        icon: Icons.router,
        child: Text('content'),
      );

      expect(tab.label, 'Devices');
      expect(tab.icon, Icons.router);
      expect(tab.child, isA<Text>());
    });

    test('icon is optional', () {
      const tab = PageTab(
        label: 'Settings',
        child: Text('settings'),
      );

      expect(tab.label, 'Settings');
      expect(tab.icon, isNull);
    });
  });
}
