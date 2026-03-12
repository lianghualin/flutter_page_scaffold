import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_page_scaffold/flutter_page_scaffold.dart';

void main() {
  Widget wrapWithMaterial(Widget child) {
    return MaterialApp(
      home: Scaffold(body: child),
    );
  }

  group('MainAreaTemplate — no-tabs mode', () {
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
  });

  group('MainAreaTemplate — unified bar (tabs mode)', () {
    testWidgets('renders tabs as pill-style chips', (tester) async {
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

    testWidgets('description shown as tooltip, not visible text', (tester) async {
      await tester.pumpWidget(wrapWithMaterial(
        MainAreaTemplate(
          title: 'Tabbed',
          description: 'A tooltip description',
          tabs: const [
            PageTab(label: 'Tab A', child: Text('content A')),
          ],
        ),
      ));

      // Description should be in a Tooltip, not visible as plain text
      expect(find.byType(Tooltip), findsOneWidget);
      final tooltip = tester.widget<Tooltip>(find.byType(Tooltip));
      expect(tooltip.message, 'A tooltip description');
    });

    testWidgets('no tooltip icon when description is null', (tester) async {
      await tester.pumpWidget(wrapWithMaterial(
        MainAreaTemplate(
          title: 'No Desc',
          tabs: const [
            PageTab(label: 'Tab A', child: Text('content A')),
          ],
        ),
      ));

      expect(find.byType(Tooltip), findsNothing);
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

      expect(find.text('content A'), findsOneWidget);

      await tester.tap(find.text('Tab B'));
      await tester.pumpAndSettle();

      expect(changedIndex, 1);
      expect(find.text('content B'), findsOneWidget);
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

      expect(find.text('content B'), findsOneWidget);
    });

    testWidgets('renders tab icons inside pills', (tester) async {
      await tester.pumpWidget(wrapWithMaterial(
        MainAreaTemplate(
          title: 'With Icons',
          tabs: const [
            PageTab(label: 'Devices', icon: Icons.router, child: Text('content')),
          ],
        ),
      ));

      expect(find.byIcon(Icons.router), findsOneWidget);
    });
  });

  group('MainAreaTemplate — visibility matrix', () {
    testWidgets('showTitle=true showTabs=true shows full bar', (tester) async {
      await tester.pumpWidget(wrapWithMaterial(
        MainAreaTemplate(
          title: 'Full Bar',
          description: 'desc',
          showTitle: true,
          showTabs: true,
          tabs: const [
            PageTab(label: 'Tab A', child: Text('content A')),
          ],
        ),
      ));

      expect(find.text('Full Bar'), findsOneWidget);
      expect(find.text('Tab A'), findsOneWidget);
      expect(find.byType(Tooltip), findsOneWidget);
    });

    testWidgets('showTitle=true showTabs=false hides tabs keeps title', (tester) async {
      await tester.pumpWidget(wrapWithMaterial(
        MainAreaTemplate(
          title: 'Title Only',
          showTitle: true,
          showTabs: false,
          tabs: const [
            PageTab(label: 'Tab A', child: Text('content A')),
            PageTab(label: 'Tab B', child: Text('content B')),
          ],
        ),
      ));

      expect(find.text('Title Only'), findsOneWidget);
      expect(find.text('Tab A'), findsNothing);
      expect(find.text('Tab B'), findsNothing);
      // Content still renders (first tab)
      expect(find.text('content A'), findsOneWidget);
    });

    testWidgets('showTitle=false showTabs=true hides title keeps tabs', (tester) async {
      await tester.pumpWidget(wrapWithMaterial(
        MainAreaTemplate(
          title: 'Hidden Title',
          showTitle: false,
          showTabs: true,
          tabs: const [
            PageTab(label: 'Tab A', child: Text('content A')),
            PageTab(label: 'Tab B', child: Text('content B')),
          ],
        ),
      ));

      expect(find.text('Hidden Title'), findsNothing);
      expect(find.text('Tab A'), findsOneWidget);
      expect(find.text('Tab B'), findsOneWidget);
    });

    testWidgets('showTitle=false showTabs=false hides entire bar', (tester) async {
      await tester.pumpWidget(wrapWithMaterial(
        MainAreaTemplate(
          title: 'Hidden',
          showTitle: false,
          showTabs: false,
          tabs: const [
            PageTab(label: 'Tab A', child: Text('content A')),
          ],
        ),
      ));

      expect(find.text('Hidden'), findsNothing);
      expect(find.text('Tab A'), findsNothing);
      // Content still renders
      expect(find.text('content A'), findsOneWidget);
    });
  });

  group('MainAreaTemplate — maintainState', () {
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
  });

  group('MainAreaTemplate — animation', () {
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

      await tester.tap(find.text('Tab B'));
      await tester.pump();

      final animating = tester.widget<FadeTransition>(fadeFinder);
      expect(animating.opacity.value, lessThan(1.0));

      await tester.pumpAndSettle();

      final settled = tester.widget<FadeTransition>(fadeFinder);
      expect(settled.opacity.value, 1.0);
    });
  });

  group('MainAreaTemplate — tabBarBuilder', () {
    testWidgets('tabBarBuilder replaces default pill tabs', (tester) async {
      await tester.pumpWidget(wrapWithMaterial(
        MainAreaTemplate(
          title: 'Test',
          tabs: const [
            PageTab(label: 'A', child: Text('content A')),
            PageTab(label: 'B', child: Text('content B')),
          ],
          tabBarBuilder: (tabs, selectedIndex, onTabSelected) {
            return Row(
              key: const Key('custom-tab-bar'),
              mainAxisSize: MainAxisSize.min,
              children: [
                for (int i = 0; i < tabs.length; i++)
                  GestureDetector(
                    onTap: () => onTabSelected(i),
                    child: Text('C${tabs[i].label}'),
                  ),
              ],
            );
          },
        ),
      ));

      expect(find.byKey(const Key('custom-tab-bar')), findsOneWidget);
      expect(find.text('CA'), findsOneWidget);
      expect(find.text('CB'), findsOneWidget);
      // Default pill labels should NOT be present
      expect(find.text('A'), findsNothing);
      expect(find.text('B'), findsNothing);
    });

    testWidgets('tabBarBuilder onTabSelected switches tabs', (tester) async {
      await tester.pumpWidget(wrapWithMaterial(
        MainAreaTemplate(
          title: 'Test',
          tabs: const [
            PageTab(label: 'A', child: Text('content A')),
            PageTab(label: 'B', child: Text('content B')),
          ],
          tabBarBuilder: (tabs, selectedIndex, onTabSelected) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (int i = 0; i < tabs.length; i++)
                  GestureDetector(
                    onTap: () => onTabSelected(i),
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Text('t${tabs[i].label}'),
                    ),
                  ),
              ],
            );
          },
        ),
      ));

      expect(find.text('content A'), findsOneWidget);

      await tester.tap(find.text('tB'));
      await tester.pumpAndSettle();

      expect(find.text('content B'), findsOneWidget);
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
