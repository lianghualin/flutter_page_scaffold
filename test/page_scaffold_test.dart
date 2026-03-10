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

    testWidgets('maintainState true keeps all tabs mounted', (tester) async {
      await tester.pumpWidget(wrapWithMaterial(
        MainAreaTemplate(
          title: 'KeepAlive',
          maintainState: true,
          tabs: const [
            PageTab(label: 'Tab A', child: Text('content A')),
            PageTab(label: 'Tab B', child: Text('content B')),
          ],
        ),
      ));

      // IndexedStack keeps both children in the tree (offstage but mounted)
      expect(find.text('content A', skipOffstage: false), findsOneWidget);
      expect(find.text('content B', skipOffstage: false), findsOneWidget);
    });

    testWidgets('maintainState false only renders selected tab', (tester) async {
      await tester.pumpWidget(wrapWithMaterial(
        MainAreaTemplate(
          title: 'Lazy',
          maintainState: false,
          tabs: const [
            PageTab(label: 'Tab A', child: Text('content A')),
            PageTab(label: 'Tab B', child: Text('content B')),
          ],
        ),
      ));

      // Only selected tab's content is in the tree
      expect(find.text('content A'), findsOneWidget);
      expect(find.text('content B'), findsNothing);
    });

    testWidgets('maintainState false switches content on tap', (tester) async {
      await tester.pumpWidget(wrapWithMaterial(
        MainAreaTemplate(
          title: 'Lazy Switch',
          maintainState: false,
          tabs: const [
            PageTab(label: 'Tab A', child: Text('content A')),
            PageTab(label: 'Tab B', child: Text('content B')),
          ],
        ),
      ));

      await tester.tap(find.text('Tab B'));
      await tester.pumpAndSettle();

      expect(find.text('content A'), findsNothing);
      expect(find.text('content B'), findsOneWidget);
    });

    testWidgets('no FadeTransition when tabTransitionDuration is null', (tester) async {
      await tester.pumpWidget(wrapWithMaterial(
        MainAreaTemplate(
          title: 'No Animation',
          tabs: const [
            PageTab(label: 'Tab A', child: Text('content A')),
            PageTab(label: 'Tab B', child: Text('content B')),
          ],
        ),
      ));

      final fadeFinder = find.descendant(
        of: find.byType(MainAreaTemplate),
        matching: find.byType(FadeTransition),
      );
      expect(fadeFinder, findsNothing);
    });

    testWidgets('FadeTransition present when tabTransitionDuration is set', (tester) async {
      await tester.pumpWidget(wrapWithMaterial(
        MainAreaTemplate(
          title: 'Animated',
          tabTransitionDuration: const Duration(milliseconds: 200),
          tabs: const [
            PageTab(label: 'Tab A', child: Text('content A')),
            PageTab(label: 'Tab B', child: Text('content B')),
          ],
        ),
      ));

      final fadeFinder = find.descendant(
        of: find.byType(MainAreaTemplate),
        matching: find.byType(FadeTransition),
      );
      expect(fadeFinder, findsOneWidget);
      final fade = tester.widget<FadeTransition>(fadeFinder);
      expect(fade.opacity.value, 1.0);
    });

    testWidgets('tab switch triggers fade animation', (tester) async {
      await tester.pumpWidget(wrapWithMaterial(
        MainAreaTemplate(
          title: 'Animated',
          tabTransitionDuration: const Duration(milliseconds: 200),
          tabs: const [
            PageTab(label: 'Tab A', child: Text('content A')),
            PageTab(label: 'Tab B', child: Text('content B')),
          ],
        ),
      ));

      final fadeFinder = find.descendant(
        of: find.byType(MainAreaTemplate),
        matching: find.byType(FadeTransition),
      );

      // Tap Tab B
      await tester.tap(find.text('Tab B'));
      await tester.pump(); // one frame after setState

      // Mid-animation: opacity should be < 1.0
      final animating = tester.widget<FadeTransition>(fadeFinder);
      expect(animating.opacity.value, lessThan(1.0));

      // Complete animation
      await tester.pumpAndSettle();

      final settled = tester.widget<FadeTransition>(fadeFinder);
      expect(settled.opacity.value, 1.0);
    });

    testWidgets('tabBarBuilder replaces default tab bar', (tester) async {
      await tester.pumpWidget(wrapWithMaterial(
        MainAreaTemplate(
          title: 'Custom Tabs',
          tabs: const [
            PageTab(label: 'Tab A', child: Text('content A')),
            PageTab(label: 'Tab B', child: Text('content B')),
          ],
          tabBarBuilder: (tabs, selectedIndex, onTabSelected) {
            return Container(
              key: const Key('custom-tab-bar'),
              child: Row(
                children: [
                  for (int i = 0; i < tabs.length; i++)
                    TextButton(
                      onPressed: () => onTabSelected(i),
                      child: Text('CUSTOM-${tabs[i].label}'),
                    ),
                ],
              ),
            );
          },
        ),
      ));

      // Custom tab bar renders
      expect(find.byKey(const Key('custom-tab-bar')), findsOneWidget);
      expect(find.text('CUSTOM-Tab A'), findsOneWidget);
      expect(find.text('CUSTOM-Tab B'), findsOneWidget);

      // Default tab labels should NOT be present (replaced by custom)
      expect(find.text('Tab A'), findsNothing);
      expect(find.text('Tab B'), findsNothing);
    });

    testWidgets('tabBarBuilder onTabSelected switches tabs', (tester) async {
      await tester.pumpWidget(wrapWithMaterial(
        MainAreaTemplate(
          title: 'Custom Tabs',
          tabs: const [
            PageTab(label: 'Tab A', child: Text('content A')),
            PageTab(label: 'Tab B', child: Text('content B')),
          ],
          tabBarBuilder: (tabs, selectedIndex, onTabSelected) {
            return Row(
              children: [
                for (int i = 0; i < tabs.length; i++)
                  GestureDetector(
                    onTap: () => onTabSelected(i),
                    child: Text('custom-${tabs[i].label}'),
                  ),
              ],
            );
          },
        ),
      ));

      expect(find.text('content A'), findsOneWidget);

      await tester.tap(find.text('custom-Tab B'));
      await tester.pumpAndSettle();

      expect(find.text('content B'), findsOneWidget);
    });

    testWidgets('showCard false removes card styling', (tester) async {
      await tester.pumpWidget(wrapWithMaterial(
        MainAreaTemplate(
          title: 'Dashboard',
          showCard: false,
          child: const Text('dashboard content'),
        ),
      ));

      expect(find.text('Dashboard'), findsOneWidget);
      expect(find.text('dashboard content'), findsOneWidget);

      // The AnimatedContainer should have transparent background and no visible shadow
      final animatedContainers = tester.widgetList<AnimatedContainer>(
        find.descendant(
          of: find.byType(MainAreaTemplate),
          matching: find.byType(AnimatedContainer),
        ),
      );
      final hasVisibleCard = animatedContainers.any((c) {
        final decoration = c.decoration;
        if (decoration is BoxDecoration) {
          return decoration.color != Colors.transparent;
        }
        return false;
      });
      expect(hasVisibleCard, isFalse);
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
