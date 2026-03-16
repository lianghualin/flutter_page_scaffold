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

  group('MainAreaTemplate — contentNavigator', () {
    testWidgets('contentNavigator false does not insert Navigator', (tester) async {
      await tester.pumpWidget(wrapWithMaterial(
        MainAreaTemplate(
          title: 'No Nav',
          contentNavigator: false,
          tabs: const [
            PageTab(label: 'Tab A', child: Text('content A')),
          ],
        ),
      ));

      final navigators = tester.widgetList<Navigator>(
        find.descendant(
          of: find.byType(MainAreaTemplate),
          matching: find.byType(Navigator),
        ),
      );
      expect(navigators.length, 0);
    });

    testWidgets('contentNavigator true inserts Navigator in widget tree', (tester) async {
      await tester.pumpWidget(wrapWithMaterial(
        MainAreaTemplate(
          title: 'With Nav',
          contentNavigator: true,
          tabs: const [
            PageTab(label: 'Tab A', child: Text('content A')),
          ],
        ),
      ));

      final navigators = tester.widgetList<Navigator>(
        find.descendant(
          of: find.byType(MainAreaTemplate),
          matching: find.byType(Navigator),
        ),
      );
      expect(navigators.length, 1);
      expect(find.text('content A'), findsOneWidget);
    });

    testWidgets('contentNavigator true works in non-tabbed mode', (tester) async {
      await tester.pumpWidget(wrapWithMaterial(
        MainAreaTemplate(
          title: 'Non-tabbed Nav',
          contentNavigator: true,
          child: const Text('child content'),
        ),
      ));

      final navigators = tester.widgetList<Navigator>(
        find.descendant(
          of: find.byType(MainAreaTemplate),
          matching: find.byType(Navigator),
        ),
      );
      expect(navigators.length, 1);
      expect(find.text('child content'), findsOneWidget);
    });

    testWidgets('Navigator.push renders sub-page inside content area', (tester) async {
      await tester.pumpWidget(wrapWithMaterial(
        MainAreaTemplate(
          title: 'Push Test',
          contentNavigator: true,
          tabs: [
            PageTab(
              label: 'Tab A',
              child: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      settings: const RouteSettings(name: 'Detail Page'),
                      builder: (_) => const Text('detail content'),
                    ),
                  ),
                  child: const Text('Go to detail'),
                ),
              ),
            ),
          ],
        ),
      ));

      expect(find.text('Go to detail'), findsOneWidget);

      await tester.tap(find.text('Go to detail'));
      await tester.pumpAndSettle();

      expect(find.text('detail content'), findsOneWidget);
      expect(find.text('Push Test'), findsOneWidget);
    });

    testWidgets('Navigator.push in non-tabbed mode stays in content area', (tester) async {
      await tester.pumpWidget(wrapWithMaterial(
        MainAreaTemplate(
          title: 'Non-tabbed Push',
          contentNavigator: true,
          child: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const Text('pushed content'),
                ),
              ),
              child: const Text('Push'),
            ),
          ),
        ),
      ));

      await tester.tap(find.text('Push'));
      await tester.pumpAndSettle();

      expect(find.text('pushed content'), findsOneWidget);
      expect(find.text('Non-tabbed Push'), findsOneWidget);
    });

    testWidgets('Navigator.pop at root is rejected', (tester) async {
      await tester.pumpWidget(wrapWithMaterial(
        MainAreaTemplate(
          title: 'Pop Root',
          contentNavigator: true,
          tabs: const [
            PageTab(label: 'Tab A', child: Text('root content')),
          ],
        ),
      ));

      expect(find.text('root content'), findsOneWidget);

      final navigatorState = tester.state<NavigatorState>(
        find.descendant(
          of: find.byType(MainAreaTemplate),
          matching: find.byType(Navigator),
        ),
      );
      navigatorState.maybePop();
      await tester.pumpAndSettle();

      expect(find.text('root content'), findsOneWidget);
    });

    testWidgets('tab switch pops navigation stack to root', (tester) async {
      await tester.pumpWidget(wrapWithMaterial(
        MainAreaTemplate(
          title: 'Tab Pop',
          contentNavigator: true,
          tabs: [
            PageTab(
              label: 'Tab A',
              child: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const Text('detail A'),
                    ),
                  ),
                  child: const Text('Go A'),
                ),
              ),
            ),
            const PageTab(label: 'Tab B', child: Text('content B')),
          ],
        ),
      ));

      await tester.tap(find.text('Go A'));
      await tester.pumpAndSettle();
      expect(find.text('detail A'), findsOneWidget);

      await tester.tap(find.text('Tab B'));
      await tester.pumpAndSettle();
      expect(find.text('content B'), findsOneWidget);
      expect(find.text('detail A'), findsNothing);
    });

    testWidgets('tapping current tab resets navigation stack', (tester) async {
      await tester.pumpWidget(wrapWithMaterial(
        MainAreaTemplate(
          title: 'Same Tab Reset',
          contentNavigator: true,
          tabs: [
            PageTab(
              label: 'Tab A',
              child: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const Text('detail A'),
                    ),
                  ),
                  child: const Text('Go A'),
                ),
              ),
            ),
            const PageTab(label: 'Tab B', child: Text('content B')),
          ],
        ),
      ));

      await tester.tap(find.text('Go A'));
      await tester.pumpAndSettle();
      expect(find.text('detail A'), findsOneWidget);

      // "Tab A" appears in both the tab pill and the breadcrumb root label,
      // so tap the first one (the pill tab).
      await tester.tap(find.text('Tab A').first);
      await tester.pumpAndSettle();
      expect(find.text('Go A'), findsOneWidget);
      expect(find.text('detail A'), findsNothing);
    });

    testWidgets('deep push chain pops all on tab switch', (tester) async {
      await tester.pumpWidget(wrapWithMaterial(
        MainAreaTemplate(
          title: 'Deep Pop',
          contentNavigator: true,
          tabs: [
            PageTab(
              label: 'Tab A',
              child: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (ctx) => ElevatedButton(
                        onPressed: () => Navigator.push(
                          ctx,
                          MaterialPageRoute(
                            builder: (_) => const Text('level 3'),
                          ),
                        ),
                        child: const Text('level 2'),
                      ),
                    ),
                  ),
                  child: const Text('level 1'),
                ),
              ),
            ),
            const PageTab(label: 'Tab B', child: Text('content B')),
          ],
        ),
      ));

      await tester.tap(find.text('level 1'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('level 2'));
      await tester.pumpAndSettle();
      expect(find.text('level 3'), findsOneWidget);

      await tester.tap(find.text('Tab B'));
      await tester.pumpAndSettle();
      expect(find.text('content B'), findsOneWidget);
      expect(find.text('level 3'), findsNothing);
      expect(find.text('level 2'), findsNothing);
    });

    testWidgets('Option A: tabs remain visible when sub-page is pushed', (tester) async {
      await tester.pumpWidget(wrapWithMaterial(
        MainAreaTemplate(
          title: 'Option A',
          contentNavigator: true,
          tabs: [
            PageTab(
              label: 'Tab A',
              child: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const Text('sub-page'),
                    ),
                  ),
                  child: const Text('Navigate'),
                ),
              ),
            ),
            const PageTab(label: 'Tab B', child: Text('content B')),
          ],
        ),
      ));

      await tester.tap(find.text('Navigate'));
      await tester.pumpAndSettle();

      expect(find.text('sub-page'), findsOneWidget);
      // Tab A appears in both the tab pill and the breadcrumb root label
      expect(find.text('Tab A'), findsWidgets);
      expect(find.text('Tab B'), findsOneWidget);
      expect(find.text('Option A'), findsOneWidget);
    });

    testWidgets('Option A: tab switch from sub-page works', (tester) async {
      await tester.pumpWidget(wrapWithMaterial(
        MainAreaTemplate(
          title: 'Option A Switch',
          contentNavigator: true,
          tabs: [
            PageTab(
              label: 'Tab A',
              child: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const Text('sub-page A'),
                    ),
                  ),
                  child: const Text('Navigate A'),
                ),
              ),
            ),
            const PageTab(label: 'Tab B', child: Text('content B')),
          ],
        ),
      ));

      await tester.tap(find.text('Navigate A'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Tab B'));
      await tester.pumpAndSettle();

      expect(find.text('content B'), findsOneWidget);
      expect(find.text('sub-page A'), findsNothing);
    });

    testWidgets('Option A: actions remain visible when sub-page is pushed', (tester) async {
      await tester.pumpWidget(wrapWithMaterial(
        MainAreaTemplate(
          title: 'Option A Actions',
          contentNavigator: true,
          actions: [
            ElevatedButton(onPressed: () {}, child: const Text('Action')),
          ],
          tabs: [
            PageTab(
              label: 'Tab A',
              child: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const Text('sub-page'),
                    ),
                  ),
                  child: const Text('Navigate'),
                ),
              ),
            ),
          ],
        ),
      ));

      await tester.tap(find.text('Navigate'));
      await tester.pumpAndSettle();

      expect(find.text('Action'), findsOneWidget);
    });

    testWidgets('maintainState true keeps all tabs mounted with contentNavigator', (tester) async {
      await tester.pumpWidget(wrapWithMaterial(
        MainAreaTemplate(
          title: 'MaintainState',
          contentNavigator: true,
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

    testWidgets('maintainState false only mounts selected tab with contentNavigator', (tester) async {
      await tester.pumpWidget(wrapWithMaterial(
        MainAreaTemplate(
          title: 'Lazy Nav',
          contentNavigator: true,
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

    testWidgets('breadcrumb hidden when contentNavigator is false', (tester) async {
      await tester.pumpWidget(wrapWithMaterial(
        MainAreaTemplate(
          title: 'No Nav',
          contentNavigator: false,
          tabs: const [
            PageTab(label: 'Tab A', child: Text('content A')),
          ],
        ),
      ));

      expect(find.byIcon(Icons.arrow_back), findsNothing);
    });

    testWidgets('breadcrumb hidden at depth 0', (tester) async {
      await tester.pumpWidget(wrapWithMaterial(
        MainAreaTemplate(
          title: 'Depth 0',
          contentNavigator: true,
          tabs: const [
            PageTab(label: 'Tab A', child: Text('content A')),
          ],
        ),
      ));

      expect(find.byIcon(Icons.arrow_back), findsNothing);
    });

    testWidgets('breadcrumb appears at depth 1 with root label and current page', (tester) async {
      await tester.pumpWidget(wrapWithMaterial(
        MainAreaTemplate(
          title: 'Breadcrumb',
          contentNavigator: true,
          tabs: [
            PageTab(
              label: 'Devices',
              child: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      settings: const RouteSettings(name: 'Device Detail'),
                      builder: (_) => const Text('detail'),
                    ),
                  ),
                  child: const Text('Go'),
                ),
              ),
            ),
          ],
        ),
      ));

      await tester.tap(find.text('Go'));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
      expect(find.text('Devices'), findsWidgets);
      expect(find.text('Device Detail'), findsOneWidget);
    });

    testWidgets('breadcrumb shows full path at depth 3', (tester) async {
      await tester.pumpWidget(wrapWithMaterial(
        MainAreaTemplate(
          title: 'Deep',
          contentNavigator: true,
          tabs: [
            PageTab(
              label: 'Devices',
              child: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      settings: const RouteSettings(name: 'Device Detail'),
                      builder: (ctx) => ElevatedButton(
                        onPressed: () => Navigator.push(
                          ctx,
                          MaterialPageRoute(
                            settings: const RouteSettings(name: 'Port Config'),
                            builder: (ctx2) => ElevatedButton(
                              onPressed: () => Navigator.push(
                                ctx2,
                                MaterialPageRoute(
                                  settings: const RouteSettings(name: 'Port Gi0/1'),
                                  builder: (_) => const Text('port detail'),
                                ),
                              ),
                              child: const Text('Go port'),
                            ),
                          ),
                        ),
                        child: const Text('Go config'),
                      ),
                    ),
                  ),
                  child: const Text('Go detail'),
                ),
              ),
            ),
          ],
        ),
      ));

      await tester.tap(find.text('Go detail'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Go config'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Go port'));
      await tester.pumpAndSettle();

      expect(find.text('port detail'), findsOneWidget);
      expect(find.text('Device Detail'), findsOneWidget);
      expect(find.text('Port Config'), findsOneWidget);
      expect(find.text('Port Gi0/1'), findsOneWidget);
    });

    testWidgets('clicking root breadcrumb segment pops to root', (tester) async {
      await tester.pumpWidget(wrapWithMaterial(
        MainAreaTemplate(
          title: 'Root Pop',
          contentNavigator: true,
          tabs: [
            PageTab(
              label: 'Devices',
              child: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      settings: const RouteSettings(name: 'Detail'),
                      builder: (ctx) => ElevatedButton(
                        onPressed: () => Navigator.push(
                          ctx,
                          MaterialPageRoute(
                            settings: const RouteSettings(name: 'Sub Detail'),
                            builder: (_) => const Text('sub detail'),
                          ),
                        ),
                        child: const Text('Go sub'),
                      ),
                    ),
                  ),
                  child: const Text('Go detail'),
                ),
              ),
            ),
          ],
        ),
      ));

      await tester.tap(find.text('Go detail'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Go sub'));
      await tester.pumpAndSettle();
      expect(find.text('sub detail'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      expect(find.text('Go detail'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back), findsNothing);
    });

    testWidgets('clicking middle breadcrumb segment pops to that level', (tester) async {
      await tester.pumpWidget(wrapWithMaterial(
        MainAreaTemplate(
          title: 'Mid Pop',
          contentNavigator: true,
          tabs: [
            PageTab(
              label: 'Devices',
              child: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      settings: const RouteSettings(name: 'Detail'),
                      builder: (ctx) => ElevatedButton(
                        onPressed: () => Navigator.push(
                          ctx,
                          MaterialPageRoute(
                            settings: const RouteSettings(name: 'Port Config'),
                            builder: (_) => const Text('port content'),
                          ),
                        ),
                        child: const Text('Go port'),
                      ),
                    ),
                  ),
                  child: const Text('Go detail'),
                ),
              ),
            ),
          ],
        ),
      ));

      await tester.tap(find.text('Go detail'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Go port'));
      await tester.pumpAndSettle();
      expect(find.text('port content'), findsOneWidget);

      await tester.tap(find.text('Detail'));
      await tester.pumpAndSettle();

      expect(find.text('Go port'), findsOneWidget);
      expect(find.text('port content'), findsNothing);
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
      expect(find.text('Detail'), findsOneWidget);
    });

    testWidgets('tab switch clears breadcrumb', (tester) async {
      await tester.pumpWidget(wrapWithMaterial(
        MainAreaTemplate(
          title: 'Tab Clear',
          contentNavigator: true,
          tabs: [
            PageTab(
              label: 'Tab A',
              child: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      settings: const RouteSettings(name: 'Detail'),
                      builder: (_) => const Text('detail'),
                    ),
                  ),
                  child: const Text('Go'),
                ),
              ),
            ),
            const PageTab(label: 'Tab B', child: Text('content B')),
          ],
        ),
      ));

      await tester.tap(find.text('Go'));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);

      await tester.tap(find.text('Tab B'));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.arrow_back), findsNothing);
      expect(find.text('content B'), findsOneWidget);
    });

    testWidgets('non-tabbed mode shows Home as root label', (tester) async {
      await tester.pumpWidget(wrapWithMaterial(
        MainAreaTemplate(
          title: 'Non-tabbed',
          contentNavigator: true,
          child: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  settings: const RouteSettings(name: 'Sub Page'),
                  builder: (_) => const Text('sub content'),
                ),
              ),
              child: const Text('Push'),
            ),
          ),
        ),
      ));

      await tester.tap(find.text('Push'));
      await tester.pumpAndSettle();

      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Sub Page'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    });

    testWidgets('null RouteSettings.name shows ... placeholder', (tester) async {
      await tester.pumpWidget(wrapWithMaterial(
        MainAreaTemplate(
          title: 'Null Name',
          contentNavigator: true,
          tabs: [
            PageTab(
              label: 'Tab A',
              child: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const Text('no name'),
                    ),
                  ),
                  child: const Text('Go'),
                ),
              ),
            ),
          ],
        ),
      ));

      await tester.tap(find.text('Go'));
      await tester.pumpAndSettle();

      expect(find.text('...'), findsOneWidget);
    });

    testWidgets('pushReplacement updates breadcrumb correctly', (tester) async {
      await tester.pumpWidget(wrapWithMaterial(
        MainAreaTemplate(
          title: 'Replace Test',
          contentNavigator: true,
          tabs: [
            PageTab(
              label: 'Tab A',
              child: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      settings: const RouteSettings(name: 'Page One'),
                      builder: (ctx) => ElevatedButton(
                        onPressed: () => Navigator.pushReplacement(
                          ctx,
                          MaterialPageRoute(
                            settings: const RouteSettings(name: 'Page Replaced'),
                            builder: (_) => const Text('replaced content'),
                          ),
                        ),
                        child: const Text('Do Replace'),
                      ),
                    ),
                  ),
                  child: const Text('Go'),
                ),
              ),
            ),
          ],
        ),
      ));

      await tester.tap(find.text('Go'));
      await tester.pumpAndSettle();
      expect(find.text('Page One'), findsOneWidget);

      await tester.tap(find.text('Do Replace'));
      await tester.pumpAndSettle();

      expect(find.text('Page Replaced'), findsOneWidget);
      expect(find.text('Page One'), findsNothing);
      expect(find.text('replaced content'), findsOneWidget);
    });
  });
}
