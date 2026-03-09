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

    testWidgets('existing behavior unchanged when tabs is null', (tester) async {
      await tester.pumpWidget(wrapWithMaterial(
        MainAreaTemplate(
          title: 'No Tabs',
          showTitle: true,
          child: const Text('single page'),
        ),
      ));

      expect(find.text('No Tabs'), findsOneWidget);
      expect(find.text('single page'), findsOneWidget);
    });

    testWidgets('hides title when showTitle is false', (tester) async {
      await tester.pumpWidget(wrapWithMaterial(
        MainAreaTemplate(
          title: 'Hidden Title',
          showTitle: false,
          child: const Text('body'),
        ),
      ));

      expect(find.text('Hidden Title'), findsNothing);
      expect(find.text('body'), findsOneWidget);
    });

    testWidgets('renders tabs when provided', (tester) async {
      await tester.pumpWidget(wrapWithMaterial(
        MainAreaTemplate(
          title: 'Tabbed',
          tabs: const [
            PageTab(label: 'Devices', icon: Icons.router, child: Text('devices content')),
            PageTab(label: 'Settings', icon: Icons.settings, child: Text('settings content')),
          ],
        ),
      ));

      expect(find.text('Devices'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('devices content'), findsOneWidget);
    });

    testWidgets('switches tab content on tap', (tester) async {
      int? changedIndex;

      await tester.pumpWidget(wrapWithMaterial(
        MainAreaTemplate(
          title: 'Tabbed',
          tabs: const [
            PageTab(label: 'Tab A', child: Text('content A')),
            PageTab(label: 'Tab B', child: Text('content B')),
          ],
          onTabChanged: (i) => changedIndex = i,
        ),
      ));

      // Tab A is visible initially (IndexedStack shows both but only first is "visible")
      expect(find.text('content A'), findsOneWidget);

      // Tap Tab B
      await tester.tap(find.text('Tab B'));
      await tester.pumpAndSettle();

      expect(changedIndex, 1);
      expect(find.text('content B'), findsOneWidget);
    });

    testWidgets('hides tab bar when showTabs is false', (tester) async {
      await tester.pumpWidget(wrapWithMaterial(
        MainAreaTemplate(
          title: 'Hidden Tabs',
          showTabs: false,
          tabs: const [
            PageTab(label: 'Tab A', child: Text('content A')),
            PageTab(label: 'Tab B', child: Text('content B')),
          ],
        ),
      ));

      expect(find.text('Tab A'), findsNothing);
      expect(find.text('Tab B'), findsNothing);
      // Content still renders (first tab)
      expect(find.text('content A'), findsOneWidget);
    });

    testWidgets('respects initialTabIndex', (tester) async {
      await tester.pumpWidget(wrapWithMaterial(
        MainAreaTemplate(
          title: 'Initial Tab',
          initialTabIndex: 1,
          tabs: const [
            PageTab(label: 'Tab A', child: Text('content A')),
            PageTab(label: 'Tab B', child: Text('content B')),
          ],
        ),
      ));

      // Both exist in IndexedStack, but index 1 is shown
      // Verify Tab B's text is present
      expect(find.text('content B'), findsOneWidget);
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
