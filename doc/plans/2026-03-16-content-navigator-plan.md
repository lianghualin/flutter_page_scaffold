# Content Navigator Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add opt-in nested navigation within `MainAreaTemplate`'s content area so that `Navigator.push` renders sub-pages inside the card area instead of going full-screen.

**Architecture:** A single `Navigator` widget is inserted below the title/tab bar when `contentNavigator: true`. A `_ContentNavigatorObserver` tracks stack depth and current route title. The root route's builder closure reads `_selectedIndex` from live state for reactive tab content swaps. Two modes: Option A (tabs stay visible, default) and Option B (tabs hide, back button + route title shown).

**Tech Stack:** Flutter, Dart

---

## Background

Current codebase state:
- `lib/src/page_scaffold.dart` — `MainAreaTemplate` (StatefulWidget), `PageTab`, `_UnifiedBar`, `_PillTab`, `_TitleArea`, `_TooltipIcon`, `PageScaffoldScope` (607 lines)
- `test/page_scaffold_test.dart` — widget tests covering tabs, visibility matrix, animation, maintainState, tabBarBuilder (497 lines)
- `example/lib/main.dart` — playground app with control bar + 3 demo pages (1225 lines)
- Version: 0.4.1
- All tests pass

### New API Surface

```dart
// New parameters on MainAreaTemplate:
final bool contentNavigator;          // default: false — opt-in nested navigation
final bool contentNavigatorShowTabs;  // default: true — Option A (tabs stay visible)
```

### Spec Reference

Full design spec: `doc/superpowers/specs/2026-03-13-content-navigator-design.md`

---

## Chunk 1: Core Navigator Infrastructure

### Task 1: Add `_ContentNavigatorObserver` and new parameters

**Files:**
- Modify: `lib/src/page_scaffold.dart`
- Modify: `test/page_scaffold_test.dart`

- [ ] **Step 1: Write the failing tests for Navigator presence**

Add a new group at the end of `test/page_scaffold_test.dart`, after the `PageTab` group:

```dart
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

      // There's always a root Navigator from MaterialApp, but there should
      // be no additional Navigator descendant of MainAreaTemplate's content area.
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
  });
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `flutter test test/page_scaffold_test.dart`
Expected: FAIL — `contentNavigator` parameter does not exist.

- [ ] **Step 3: Add new parameters to `MainAreaTemplate`**

In `lib/src/page_scaffold.dart`, add two new fields to the `MainAreaTemplate` class after the `showCard` field (line 127):

```dart
  /// Whether to wrap the content area in a nested [Navigator].
  /// When true, [Navigator.push] calls from within tab/child content
  /// render sub-pages inside the card area instead of going full-screen.
  /// Defaults to false.
  final bool contentNavigator;

  /// Whether to keep tabs visible when a sub-page is pushed.
  /// Only effective when [contentNavigator] is true.
  /// When true (default), tabs remain visible and tapping any tab pops the
  /// navigation stack to root. When false, tabs are hidden when a sub-page
  /// is pushed and a back button with the route title is shown instead.
  final bool contentNavigatorShowTabs;
```

Add them to the constructor (after `this.showCard = true`):

```dart
    this.contentNavigator = false,
    this.contentNavigatorShowTabs = true,
```

- [ ] **Step 4: Add `_ContentNavigatorObserver` class**

Add this class at the end of `lib/src/page_scaffold.dart` (after `_TitleArea`):

```dart
class _ContentNavigatorObserver extends NavigatorObserver {
  final VoidCallback onStackChanged;
  int _depth = 0;
  String? _currentTitle;

  _ContentNavigatorObserver({required this.onStackChanged});

  int get depth => _depth;
  String? get currentTitle => _currentTitle;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (previousRoute != null) {
      // Skip the initial root route push (previousRoute == null)
      _depth++;
      _currentTitle = route.settings.name;
      onStackChanged();
    }
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _depth--;
    if (_depth < 0) _depth = 0;
    _currentTitle = _depth > 0 ? previousRoute?.settings.name : null;
    onStackChanged();
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _depth--;
    if (_depth < 0) _depth = 0;
    onStackChanged();
  }
}
```

- [ ] **Step 5: Add Navigator to the build method**

In `_MainAreaTemplateState`, add new state fields after `_fadeAnimation` (line 160):

```dart
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  late final _ContentNavigatorObserver _navigatorObserver;
  int get _stackDepth => _navigatorObserver.depth;
  String? get _currentRouteTitle => _navigatorObserver.currentTitle;
```

In `initState`, after `_initAnimation()` (line 166), add:

```dart
    _navigatorObserver = _ContentNavigatorObserver(
      onStackChanged: () {
        if (mounted) setState(() {});
      },
    );
```

In the `build` method, replace the line `child: contentChild,` (inside the card Padding, line 296) with:

```dart
                    child: widget.contentNavigator
                        ? Navigator(
                            key: _navigatorKey,
                            observers: [_navigatorObserver],
                            onGenerateRoute: (_) => PageRouteBuilder(
                              pageBuilder: (context, _, __) {
                                // IMPORTANT: Build content inside the closure so it
                                // reads _selectedIndex from live state on each rebuild.
                                // Navigator only calls onGenerateRoute once for the
                                // initial route, but the pageBuilder is called on
                                // every rebuild of the route's widget subtree.
                                Widget child;
                                if (widget.tabs != null) {
                                  if (widget.maintainState) {
                                    child = IndexedStack(
                                      index: _selectedIndex,
                                      children: widget.tabs!.map((t) => t.child).toList(),
                                    );
                                  } else {
                                    child = widget.tabs![_selectedIndex].child;
                                  }
                                } else {
                                  child = widget.child!;
                                }
                                if (_fadeAnimation != null && widget.tabs != null) {
                                  child = FadeTransition(
                                    opacity: _fadeAnimation!,
                                    child: child,
                                  );
                                }
                                return child;
                              },
                              transitionDuration: Duration.zero,
                              reverseTransitionDuration: Duration.zero,
                            ),
                            onPopPage: (route, result) {
                              if (route.isFirst) return false;
                              return route.didPop(result);
                            },
                          )
                        : contentChild,
```

**Note:** The `contentChild` variable computed earlier in `build()` is still used for the non-navigator path (`contentNavigator: false`). The Navigator path builds its own content inside the `pageBuilder` closure to ensure it reads `_selectedIndex` from live state on each rebuild. This is critical because `Navigator` only invokes `onGenerateRoute` once for the initial route creation, but `pageBuilder` is re-invoked whenever the route's subtree rebuilds (triggered by `setState`).

- [ ] **Step 6: Run tests to verify they pass**

Run: `flutter test test/page_scaffold_test.dart`
Expected: ALL PASS (existing + 3 new tests).

- [ ] **Step 7: Commit**

```bash
git add lib/src/page_scaffold.dart test/page_scaffold_test.dart
git commit -m "feat: add contentNavigator parameter with Navigator wrapper and observer"
```

---

### Task 2: Push/pop within content area (tabbed + non-tabbed)

**Files:**
- Modify: `test/page_scaffold_test.dart`
- Modify: `lib/src/page_scaffold.dart` (if needed)

- [ ] **Step 1: Write failing tests for push/pop behavior**

Add inside the `contentNavigator` group:

```dart
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
      // Title bar should still be visible
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

      // Content should be visible
      expect(find.text('root content'), findsOneWidget);

      // Try to pop — should be rejected since we're at root
      final navigatorState = tester.state<NavigatorState>(
        find.descendant(
          of: find.byType(MainAreaTemplate),
          matching: find.byType(Navigator),
        ),
      );
      navigatorState.maybePop();
      await tester.pumpAndSettle();

      // Root content should still be visible
      expect(find.text('root content'), findsOneWidget);
    });
```

- [ ] **Step 2: Run tests to verify they pass**

Run: `flutter test test/page_scaffold_test.dart`
Expected: ALL PASS. The Navigator infrastructure from Task 1 should handle push/pop correctly. If any fail, fix the `build` method or `onPopPage` callback.

- [ ] **Step 3: Commit**

```bash
git add test/page_scaffold_test.dart
git commit -m "test: add push/pop tests for contentNavigator"
```

---

### Task 3: Tab switching pops navigation stack to root

**Files:**
- Modify: `test/page_scaffold_test.dart`
- Modify: `lib/src/page_scaffold.dart`

- [ ] **Step 1: Write failing tests for tab switch + pop**

Add inside the `contentNavigator` group:

```dart
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

      // Push a sub-page on Tab A
      await tester.tap(find.text('Go A'));
      await tester.pumpAndSettle();
      expect(find.text('detail A'), findsOneWidget);

      // Switch to Tab B — should pop the stack and show Tab B content
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

      // Push a sub-page on Tab A
      await tester.tap(find.text('Go A'));
      await tester.pumpAndSettle();
      expect(find.text('detail A'), findsOneWidget);

      // Tap Tab A again — should pop back to root content
      await tester.tap(find.text('Tab A'));
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

      // Push to level 2
      await tester.tap(find.text('level 1'));
      await tester.pumpAndSettle();
      // Push to level 3
      await tester.tap(find.text('level 2'));
      await tester.pumpAndSettle();
      expect(find.text('level 3'), findsOneWidget);

      // Switch tab — should pop entire stack
      await tester.tap(find.text('Tab B'));
      await tester.pumpAndSettle();
      expect(find.text('content B'), findsOneWidget);
      expect(find.text('level 3'), findsNothing);
      expect(find.text('level 2'), findsNothing);
    });
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `flutter test test/page_scaffold_test.dart`
Expected: FAIL — `_onTabSelected` does not pop the Navigator yet.

- [ ] **Step 3: Modify `_onTabSelected` to pop Navigator on tab switch**

In `_MainAreaTemplateState`, replace the `_onTabSelected` method:

```dart
  void _onTabSelected(int index) {
    if (widget.contentNavigator && _stackDepth > 0) {
      _navigatorKey.currentState!.popUntil((route) => route.isFirst);
    }
    if (index != _selectedIndex) {
      setState(() => _selectedIndex = index);
      _animationController?.forward(from: 0.0);
      widget.onTabChanged?.call(index);
    }
  }
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `flutter test test/page_scaffold_test.dart`
Expected: ALL PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/src/page_scaffold.dart test/page_scaffold_test.dart
git commit -m "feat: tab switch pops contentNavigator stack to root"
```

---

## Chunk 2: Option A & Option B Title Bar Modes

### Task 4: Option A — tabs stay visible during sub-page navigation

**Files:**
- Modify: `test/page_scaffold_test.dart`

- [ ] **Step 1: Write tests for Option A behavior**

Add inside the `contentNavigator` group:

```dart
    testWidgets('Option A: tabs remain visible when sub-page is pushed', (tester) async {
      await tester.pumpWidget(wrapWithMaterial(
        MainAreaTemplate(
          title: 'Option A',
          contentNavigator: true,
          contentNavigatorShowTabs: true,
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

      // Sub-page is visible
      expect(find.text('sub-page'), findsOneWidget);
      // Tabs are still visible
      expect(find.text('Tab A'), findsOneWidget);
      expect(find.text('Tab B'), findsOneWidget);
      // Title is still visible
      expect(find.text('Option A'), findsOneWidget);
    });

    testWidgets('Option A: tab switch from sub-page works', (tester) async {
      await tester.pumpWidget(wrapWithMaterial(
        MainAreaTemplate(
          title: 'Option A Switch',
          contentNavigator: true,
          contentNavigatorShowTabs: true,
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

      // Push sub-page
      await tester.tap(find.text('Navigate A'));
      await tester.pumpAndSettle();

      // Switch to Tab B
      await tester.tap(find.text('Tab B'));
      await tester.pumpAndSettle();

      expect(find.text('content B'), findsOneWidget);
      expect(find.text('sub-page A'), findsNothing);
    });
```

- [ ] **Step 2: Run tests to verify they pass**

Run: `flutter test test/page_scaffold_test.dart`
Expected: ALL PASS. Option A is the default behavior — tabs are always shown. The existing _UnifiedBar already renders tabs regardless of stack depth.

- [ ] **Step 3: Commit**

```bash
git add test/page_scaffold_test.dart
git commit -m "test: add Option A (tabs stay visible) tests for contentNavigator"
```

---

### Task 5: Option B — back button bar widget

**Files:**
- Modify: `lib/src/page_scaffold.dart`
- Modify: `test/page_scaffold_test.dart`

- [ ] **Step 1: Write failing tests for Option B**

Add inside the `contentNavigator` group:

```dart
    testWidgets('Option B: tabs hidden when sub-page pushed, back button shown', (tester) async {
      await tester.pumpWidget(wrapWithMaterial(
        MainAreaTemplate(
          title: 'Option B',
          contentNavigator: true,
          contentNavigatorShowTabs: false,
          tabs: [
            PageTab(
              label: 'Tab A',
              child: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      settings: const RouteSettings(name: 'Detail View'),
                      builder: (_) => const Text('detail content'),
                    ),
                  ),
                  child: const Text('Go detail'),
                ),
              ),
            ),
            const PageTab(label: 'Tab B', child: Text('content B')),
          ],
        ),
      ));

      // Initially tabs are visible
      expect(find.text('Tab A'), findsOneWidget);
      expect(find.text('Tab B'), findsOneWidget);

      // Push sub-page
      await tester.tap(find.text('Go detail'));
      await tester.pumpAndSettle();

      // Tabs should be hidden
      expect(find.text('Tab A'), findsNothing);
      expect(find.text('Tab B'), findsNothing);
      // Back button and route title should appear
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
      expect(find.text('Detail View'), findsOneWidget);
      // Detail content visible
      expect(find.text('detail content'), findsOneWidget);
    });

    testWidgets('Option B: back button pops one level', (tester) async {
      await tester.pumpWidget(wrapWithMaterial(
        MainAreaTemplate(
          title: 'Option B Pop',
          contentNavigator: true,
          contentNavigatorShowTabs: false,
          tabs: [
            PageTab(
              label: 'Tab A',
              child: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      settings: const RouteSettings(name: 'Detail'),
                      builder: (_) => const Text('detail content'),
                    ),
                  ),
                  child: const Text('Go detail'),
                ),
              ),
            ),
            const PageTab(label: 'Tab B', child: Text('content B')),
          ],
        ),
      ));

      // Push sub-page
      await tester.tap(find.text('Go detail'));
      await tester.pumpAndSettle();

      // Tap back button
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      // Tabs should reappear
      expect(find.text('Tab A'), findsOneWidget);
      expect(find.text('Tab B'), findsOneWidget);
      // Back to root content
      expect(find.text('Go detail'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back), findsNothing);
    });

    testWidgets('Option B: null RouteSettings.name falls back to original title', (tester) async {
      await tester.pumpWidget(wrapWithMaterial(
        MainAreaTemplate(
          title: 'Fallback Title',
          contentNavigator: true,
          contentNavigatorShowTabs: false,
          tabs: [
            PageTab(
              label: 'Tab A',
              child: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const Text('no-name detail'),
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

      // Should fall back to original title
      expect(find.text('Fallback Title'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    });

    testWidgets('Option B: actions remain visible during sub-page', (tester) async {
      await tester.pumpWidget(wrapWithMaterial(
        MainAreaTemplate(
          title: 'Option B Actions',
          contentNavigator: true,
          contentNavigatorShowTabs: false,
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
                      settings: const RouteSettings(name: 'Detail'),
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

      expect(find.text('Action'), findsOneWidget);
    });

    testWidgets('Option B: non-tabbed mode shows back button on push', (tester) async {
      await tester.pumpWidget(wrapWithMaterial(
        MainAreaTemplate(
          title: 'Non-tabbed B',
          contentNavigator: true,
          contentNavigatorShowTabs: false,
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

      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
      expect(find.text('Sub Page'), findsOneWidget);
      expect(find.text('sub content'), findsOneWidget);
    });

    testWidgets('Option B: back button appears even when showTitle is false', (tester) async {
      await tester.pumpWidget(wrapWithMaterial(
        MainAreaTemplate(
          title: 'Hidden Title',
          showTitle: false,
          contentNavigator: true,
          contentNavigatorShowTabs: false,
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
          ],
        ),
      ));

      await tester.tap(find.text('Go'));
      await tester.pumpAndSettle();

      // Back button should appear regardless of showTitle
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
      expect(find.text('Detail'), findsOneWidget);
    });

    testWidgets('Option B: icon is not shown during sub-page navigation', (tester) async {
      await tester.pumpWidget(wrapWithMaterial(
        MainAreaTemplate(
          title: 'With Icon',
          icon: Icons.router,
          contentNavigator: true,
          contentNavigatorShowTabs: false,
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
          ],
        ),
      ));

      // Icon should be visible at root
      expect(find.byIcon(Icons.router), findsOneWidget);

      await tester.tap(find.text('Go'));
      await tester.pumpAndSettle();

      // Icon should be hidden in back-button state, only back arrow visible
      expect(find.byIcon(Icons.router), findsNothing);
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    });

    testWidgets('Option A: actions remain visible when sub-page is pushed', (tester) async {
      await tester.pumpWidget(wrapWithMaterial(
        MainAreaTemplate(
          title: 'Option A Actions',
          contentNavigator: true,
          contentNavigatorShowTabs: true,
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
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `flutter test test/page_scaffold_test.dart`
Expected: FAIL — back button bar and tab hiding logic not implemented.

- [ ] **Step 3: Add `_BackButtonBar` widget**

Add this widget in `lib/src/page_scaffold.dart` after `_TitleArea`:

```dart
class _BackButtonBar extends StatelessWidget {
  final String title;
  final VoidCallback onBack;
  final List<Widget>? actions;

  const _BackButtonBar({
    required this.title,
    required this.onBack,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: colorScheme.outlineVariant,
            width: 1,
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          InkWell(
            onTap: onBack,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.arrow_back,
                    size: 20,
                    color: colorScheme.onSurface,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Back',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface,
            ),
          ),
          const Spacer(),
          if (actions != null && actions!.isNotEmpty)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (int i = 0; i < actions!.length; i++) ...[
                  if (i > 0) const SizedBox(width: 8),
                  actions![i],
                ],
              ],
            ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 4: Integrate Option B into the build method**

In `_MainAreaTemplateState.build`, modify the title bar section. Replace the block that renders the bar (the `if (showBar && hasTabs)` / `if (showBar && !hasTabs)` / `if (showBar)` section) with:

```dart
              if (_shouldShowBackBar)
                _BackButtonBar(
                  title: _currentRouteTitle ?? widget.title,
                  onBack: () => _navigatorKey.currentState!.pop(),
                  actions: widget.actions,
                )
              else if (showBar && hasTabs)
                _UnifiedBar(
                  title: widget.title,
                  description: widget.description,
                  icon: widget.icon,
                  actions: widget.actions,
                  tabs: widget.tabs!,
                  selectedIndex: _selectedIndex,
                  onTabSelected: _onTabSelected,
                  showTitle: widget.showTitle,
                  showTabs: widget.showTabs,
                  tabBarBuilder: widget.tabBarBuilder,
                )
              else if (showBar && !hasTabs)
                _TitleArea(
                  title: widget.title,
                  description: widget.description,
                  icon: widget.icon,
                  actions: widget.actions,
                ),
              if (_shouldShowBackBar || showBar) const SizedBox(height: 16),
```

Add this getter to `_MainAreaTemplateState`:

```dart
  bool get _shouldShowBackBar =>
      widget.contentNavigator &&
      !widget.contentNavigatorShowTabs &&
      _stackDepth > 0;
```

- [ ] **Step 5: Run tests to verify they pass**

Run: `flutter test test/page_scaffold_test.dart`
Expected: ALL PASS.

- [ ] **Step 6: Commit**

```bash
git add lib/src/page_scaffold.dart test/page_scaffold_test.dart
git commit -m "feat: add Option B back-button bar for contentNavigator"
```

---

## Chunk 3: Edge Cases, Example, and Release

### Task 6: maintainState interaction with contentNavigator

**Files:**
- Modify: `test/page_scaffold_test.dart`

- [ ] **Step 1: Write tests for maintainState + contentNavigator**

Add inside the `contentNavigator` group:

```dart
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
```

- [ ] **Step 2: Run tests to verify they pass**

Run: `flutter test test/page_scaffold_test.dart`
Expected: ALL PASS. The root route's builder already uses `IndexedStack` / direct child based on `maintainState`.

- [ ] **Step 3: Commit**

```bash
git add test/page_scaffold_test.dart
git commit -m "test: verify maintainState interaction with contentNavigator"
```

---

### Task 7: Update example playground

**Files:**
- Modify: `example/lib/main.dart`

- [ ] **Step 1: Add contentNavigator toggle to the control bar**

In `_PlaygroundAppState`, add two new state fields after `_showCard` (line 104):

```dart
  bool _contentNavigator = false;
  bool _contentNavigatorShowTabs = true;
```

In the `MainAreaTemplate` widget (around line 140), add the new parameters:

```dart
                contentNavigator: _contentNavigator,
                contentNavigatorShowTabs: _contentNavigatorShowTabs,
```

In `_ControlBar`, add two new toggle chip parameters and pass them through. Add after the Card toggle chip:

```dart
          const SizedBox(width: 8),
          _ToggleChip(
            label: 'Navigator',
            value: contentNavigator,
            onChanged: onContentNavigatorChanged,
          ),
          const SizedBox(width: 8),
          _ToggleChip(
            label: 'Nav Tabs',
            value: contentNavigatorShowTabs,
            onChanged: onContentNavigatorShowTabsChanged,
          ),
```

Add the required fields and constructor parameters to `_ControlBar`:

```dart
  final bool contentNavigator;
  final ValueChanged<bool> onContentNavigatorChanged;
  final bool contentNavigatorShowTabs;
  final ValueChanged<bool> onContentNavigatorShowTabsChanged;
```

Wire them up in `_PlaygroundAppState.build` where `_ControlBar` is constructed:

```dart
              contentNavigator: _contentNavigator,
              onContentNavigatorChanged: (v) => setState(() => _contentNavigator = v),
              contentNavigatorShowTabs: _contentNavigatorShowTabs,
              onContentNavigatorShowTabsChanged: (v) => setState(() => _contentNavigatorShowTabs = v),
```

- [ ] **Step 2: Add a navigation button to the table demo**

In `TableDemoContent`, modify a `_SmallIconButton` to demonstrate push navigation. Replace the edit button's `onTap: () {}` with a `Builder` pattern that pushes a detail page. Alternatively, add an "Enter" button to each row.

For simplicity, add a button in the toolbar section:

In `TableDemoContent.build`, after the "Add Device" button:

```dart
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      settings: const RouteSettings(name: 'Device Detail'),
                      builder: (_) => const Center(
                        child: Text(
                          'Device Detail Page\n(pushed via contentNavigator)',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.open_in_new, size: 16),
                label: const Text('Detail Demo'),
              ),
```

- [ ] **Step 3: Run the example to verify**

Run: `cd example && flutter run -d chrome`
Expected: Toggle "Navigator" on, click "Detail Demo" — sub-page renders inside the card. Tabs remain visible (Option A). Toggle "Nav Tabs" off and repeat — tabs hide, back button appears (Option B).

- [ ] **Step 4: Commit**

```bash
git add example/lib/main.dart
git commit -m "feat: add contentNavigator demo to example playground"
```

---

### Task 8: Run full test suite and verify existing tests

**Files:** None (verification only)

- [ ] **Step 1: Run full test suite**

Run: `flutter test`
Expected: ALL PASS — all existing tests unchanged, all new tests pass.

- [ ] **Step 2: Run lint analysis**

Run: `flutter analyze`
Expected: No issues found.

- [ ] **Step 3: Commit any fixes if needed**

If any lint or test issues, fix and commit.

---

### Task 9: Version bump and changelog

**Files:**
- Modify: `pubspec.yaml`
- Modify: `CHANGELOG.md`

- [ ] **Step 1: Bump version in pubspec.yaml**

Change version from `0.4.1` to `0.5.0` (new feature = minor bump).

- [ ] **Step 2: Update CHANGELOG.md**

Add at the top:

```markdown
## 0.5.0

### Added
- `contentNavigator` parameter on `MainAreaTemplate` — opt-in nested navigation that keeps pushed pages within the content card area
- `contentNavigatorShowTabs` parameter — controls whether tabs stay visible (Option A, default) or hide with a back button (Option B) when sub-pages are pushed
- `_BackButtonBar` widget for Option B title bar mode
- Example playground toggle for contentNavigator demo
```

- [ ] **Step 3: Commit**

```bash
git add pubspec.yaml CHANGELOG.md
git commit -m "chore: bump version to 0.5.0, update CHANGELOG"
```
