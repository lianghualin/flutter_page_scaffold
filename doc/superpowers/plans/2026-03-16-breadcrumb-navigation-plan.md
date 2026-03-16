# Breadcrumb Navigation Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the dual Option A/B navigation modes with a single breadcrumb strip inside the content card, and delete the `contentNavigatorShowTabs` parameter and `_BackButtonBar` widget.

**Architecture:** The `_ContentNavigatorObserver` is upgraded to track a full route stack (list of route names) instead of just depth + title. A new `_BreadcrumbBar` widget renders inside the card above the Navigator when depth > 0, with clickable segments that pop to specific levels. The `_BackButtonBar` widget and `contentNavigatorShowTabs` parameter are deleted entirely.

**Tech Stack:** Flutter SDK only (zero external dependencies)

**Spec:** `doc/superpowers/specs/2026-03-16-breadcrumb-navigation-design.md`

---

## Chunk 1: Delete Old Code, Upgrade Observer, Add Breadcrumb Widget

### Task 1: Remove `contentNavigatorShowTabs` and `_BackButtonBar`

**Files:**
- Modify: `lib/src/page_scaffold.dart`

- [ ] **Step 1: Remove `contentNavigatorShowTabs` parameter from `MainAreaTemplate`**

Delete the field declaration (line 140), constructor parameter (line 161), and the `_shouldShowBackBar` getter (lines 180-183).

```dart
// DELETE these lines:
// final bool contentNavigatorShowTabs;  (line 140)
// this.contentNavigatorShowTabs = true, (line 161)
// bool get _shouldShowBackBar => ...     (lines 180-183)
```

- [ ] **Step 2: Remove `_BackButtonBar` widget**

Delete the entire `_BackButtonBar` class (lines 684-761).

- [ ] **Step 3: Remove `_shouldShowBackBar` references from build method**

In `_MainAreaTemplateState.build()`, remove:
- The `if (_shouldShowBackBar)` branch (lines 280-285)
- The `_shouldShowBackBar ||` from the SizedBox condition (line 306)

The build method title-bar section should become:

```dart
if (showBar && hasTabs)
  _UnifiedBar(...)
else if (showBar && !hasTabs)
  _TitleArea(...),
if (showBar) const SizedBox(height: 16),
```

- [ ] **Step 4: Verify it compiles**

Run: `flutter analyze`
Expected: No issues (some tests will fail, that's expected)

- [ ] **Step 5: Commit**

```bash
git add lib/src/page_scaffold.dart
git commit -m "refactor: remove contentNavigatorShowTabs and _BackButtonBar"
```

---

### Task 2: Upgrade `_ContentNavigatorObserver` to track full route stack

**Files:**
- Modify: `lib/src/page_scaffold.dart`

- [ ] **Step 1: Replace observer state with route stack list**

Replace the `_depth` and `_currentTitle` fields with a `_routeStack` list. Update getters.

```dart
class _ContentNavigatorObserver extends NavigatorObserver {
  final VoidCallback onStackChanged;
  final List<String?> _routeStack = [];

  _ContentNavigatorObserver({required this.onStackChanged});

  int get depth => _routeStack.length;
  String? get currentTitle => _routeStack.lastOrNull;
  List<String?> get routeStack => List.unmodifiable(_routeStack);

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (previousRoute != null) {
      _routeStack.add(route.settings.name);
      onStackChanged();
    }
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (_routeStack.isNotEmpty) _routeStack.removeLast();
    onStackChanged();
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (_routeStack.isNotEmpty) _routeStack.removeLast();
    onStackChanged();
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    if (_routeStack.isNotEmpty) _routeStack.removeLast();
    _routeStack.add(newRoute?.settings.name);
    onStackChanged();
  }
}
```

- [ ] **Step 2: Clean up `_MainAreaTemplateState` getters**

Remove the `_currentRouteTitle` getter (line 179) — it's dead code after `_BackButtonBar` deletion. Keep `_stackDepth` which is still used by `_onTabSelected` and the breadcrumb visibility check.

```dart
// DELETE this line:
// String? get _currentRouteTitle => _navigatorObserver.currentTitle;
```

- [ ] **Step 3: Verify it compiles**

Run: `flutter analyze`
Expected: No issues

- [ ] **Step 4: Commit**

```bash
git add lib/src/page_scaffold.dart
git commit -m "refactor: upgrade observer to track full route stack"
```

---

### Task 3: Add `_BreadcrumbBar` widget and integrate into build method

**Files:**
- Modify: `lib/src/page_scaffold.dart`

- [ ] **Step 1: Add `_BreadcrumbBar` widget**

Add after the `_TitleArea` class (around line 682, after BackButtonBar deletion):

```dart
class _BreadcrumbBar extends StatelessWidget {
  final String rootLabel;
  final List<String?> routeStack;
  final VoidCallback onPopToRoot;
  final void Function(int depth) onPopToDepth;

  const _BreadcrumbBar({
    required this.rootLabel,
    required this.routeStack,
    required this.onPopToRoot,
    required this.onPopToDepth,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh,
        border: Border(
          bottom: BorderSide(color: colorScheme.outline, width: 1),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Root segment: ← TabName
            InkWell(
              onTap: onPopToRoot,
              borderRadius: BorderRadius.circular(4),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.arrow_back, size: 16, color: colorScheme.primary),
                    const SizedBox(width: 4),
                    Text(
                      rootLabel,
                      style: TextStyle(
                        fontSize: 13,
                        color: colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Ancestor + current segments
            for (int i = 0; i < routeStack.length; i++) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  '/',
                  style: TextStyle(
                    fontSize: 14,
                    color: colorScheme.outlineVariant,
                  ),
                ),
              ),
              if (i < routeStack.length - 1)
                // Clickable ancestor
                InkWell(
                  onTap: () => onPopToDepth(i + 1),
                  borderRadius: BorderRadius.circular(4),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    child: Text(
                      routeStack[i] ?? '...',
                      style: TextStyle(
                        fontSize: 13,
                        color: colorScheme.primary,
                      ),
                    ),
                  ),
                )
              else
                // Current page (last, non-clickable, bold)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: Text(
                    routeStack[i] ?? '...',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Add `_popToDepth` helper to `_MainAreaTemplateState`**

```dart
void _popToDepth(int targetDepth) {
  final popCount = _stackDepth - targetDepth;
  var count = 0;
  _navigatorKey.currentState!.popUntil((route) {
    if (count >= popCount) return true;
    count++;
    return false;
  });
}
```

- [ ] **Step 3: Restructure card interior to place breadcrumb outside cardPadding**

The current structure is:
```
AnimatedContainer > Padding(cardPadding) > Navigator
```

Change to:
```
AnimatedContainer > Column > [_BreadcrumbBar, Expanded > Padding(cardPadding) > Navigator]
```

Replace the card's child (lines 330-372) with:

```dart
child: widget.contentNavigator
    ? Column(
        children: [
          if (_stackDepth > 0)
            _BreadcrumbBar(
              rootLabel: widget.tabs != null
                  ? widget.tabs![_selectedIndex].label
                  : 'Home',
              routeStack: _navigatorObserver.routeStack,
              onPopToRoot: () =>
                  _navigatorKey.currentState!.popUntil((route) => route.isFirst),
              onPopToDepth: _popToDepth,
            ),
          Expanded(
            child: Padding(
              padding: widget.cardPadding ?? const EdgeInsets.all(20),
              child: Navigator(
                key: _navigatorKey,
                observers: [_navigatorObserver],
                onGenerateRoute: (_) => PageRouteBuilder(
                  pageBuilder: (context, _, __) {
                    Widget child;
                    if (widget.tabs != null) {
                      if (widget.maintainState) {
                        child = IndexedStack(
                          index: _selectedIndex,
                          children: widget.tabs!
                              .map((t) => t.child)
                              .toList(),
                        );
                      } else {
                        child =
                            widget.tabs![_selectedIndex].child;
                      }
                    } else {
                      child = widget.child!;
                    }
                    if (_fadeAnimation != null &&
                        widget.tabs != null) {
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
                onDidRemovePage: (page) {},
              ),
            ),
          ),
        ],
      )
    : Padding(
        padding: widget.cardPadding ?? const EdgeInsets.all(20),
        child: contentChild,
      ),
```

Note: The `Padding` wrapper moves inside the Column for the `contentNavigator` branch, and the existing `Padding` around the non-navigator path remains but is now explicit here. The outer `Padding(cardPadding)` wrapping both branches (line 330-332) must be removed — each branch now manages its own padding.

- [ ] **Step 4: Verify it compiles**

Run: `flutter analyze`
Expected: No issues

- [ ] **Step 5: Commit**

```bash
git add lib/src/page_scaffold.dart
git commit -m "feat: add _BreadcrumbBar widget with multi-level navigation"
```

---

## Chunk 2: Tests

### Task 4: Delete old Option B tests and rewrite as breadcrumb tests

**Files:**
- Modify: `test/page_scaffold_test.dart`

- [ ] **Step 1: Delete all Option B tests**

Delete the following tests (lines 864-1107):
- `'Option B: tabs hidden when sub-page pushed, back button shown'`
- `'Option B: back button pops one level'`
- `'Option B: null RouteSettings.name falls back to original title'`
- `'Option B: actions remain visible during sub-page'`
- `'Option B: non-tabbed mode shows back button on push'`
- `'Option B: back button appears even when showTitle is false'`
- `'Option B: icon is not shown during sub-page navigation'`

- [ ] **Step 2: Remove `contentNavigatorShowTabs` from Option A tests**

In the remaining Option A tests (lines 759-862), remove `contentNavigatorShowTabs: true` parameter since it no longer exists. The tests otherwise stay the same — they verify tabs remain visible on push.

- [ ] **Step 3: Add breadcrumb visibility tests**

Add new tests to the `contentNavigator` group:

```dart
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
  expect(find.text('Devices'), findsWidgets); // tab + breadcrumb root
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
```

- [ ] **Step 4: Add breadcrumb click tests**

```dart
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

  // Tap the back arrow (root segment)
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

  // Tap "Detail" (middle breadcrumb segment) to pop one level
  await tester.tap(find.text('Detail'));
  await tester.pumpAndSettle();

  expect(find.text('Go port'), findsOneWidget);
  expect(find.text('port content'), findsNothing);
  // Breadcrumb should still show depth 1
  expect(find.byIcon(Icons.arrow_back), findsOneWidget);
  expect(find.text('Detail'), findsOneWidget);
});
```

- [ ] **Step 5: Add breadcrumb edge case tests**

```dart
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
      title: 'Replace',
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
                    child: const Text('Replace'),
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

  await tester.tap(find.text('Replace'));
  await tester.pumpAndSettle();

  // Breadcrumb should show replaced name, not appended
  expect(find.text('Page Replaced'), findsOneWidget);
  expect(find.text('Page One'), findsNothing);
  expect(find.text('replaced content'), findsOneWidget);
});
```

Note: The removal of `contentNavigatorShowTabs` is verified implicitly — the Option A tests in Step 2 are updated to remove `contentNavigatorShowTabs: true`, and the code compiles without it. If the parameter still existed, these tests would fail to compile.

- [ ] **Step 6: Run all tests**

Run: `flutter test`
Expected: All tests pass

- [ ] **Step 7: Commit**

```bash
git add test/page_scaffold_test.dart
git commit -m "test: replace Option B tests with breadcrumb navigation tests"
```

---

## Chunk 3: Example Playground Update, Version Bump

### Task 5: Update example playground

**Files:**
- Modify: `example/lib/main.dart`

- [ ] **Step 1: Remove `_contentNavigatorShowTabs` state and "Nav Tabs" toggle**

In `_PlaygroundAppState`, delete:
- `bool _contentNavigatorShowTabs = true;` (line 105)
- The `contentNavigatorShowTabs` prop on `MainAreaTemplate` (line 155)
- The `contentNavigatorShowTabs` / `onContentNavigatorShowTabsChanged` props on `_ControlBar` (lines 143-144)

In `_ControlBar`, delete:
- The `contentNavigatorShowTabs` field and `onContentNavigatorShowTabsChanged` callback (lines 212, 230)
- The constructor parameters for them
- The "Nav Tabs" `_ToggleChip` (lines 308-311)

- [ ] **Step 2: Verify it compiles**

Run: `flutter analyze`
Expected: No issues

- [ ] **Step 3: Commit**

```bash
git add example/lib/main.dart
git commit -m "feat: remove Nav Tabs toggle from example playground"
```

---

### Task 6: Version bump and changelog

**Files:**
- Modify: `pubspec.yaml`
- Modify: `CHANGELOG.md`

- [ ] **Step 1: Bump version to 0.6.0**

In `pubspec.yaml`, change `version: 0.5.0` to `version: 0.6.0`.

- [ ] **Step 2: Update CHANGELOG.md**

Add at the top:

```markdown
## 0.6.0

### Breaking
- **REMOVED** `contentNavigatorShowTabs` parameter — the breadcrumb strip now provides navigation unconditionally when `contentNavigator` is true. Remove this parameter from call sites.

### Added
- Breadcrumb navigation strip inside the content card — appears when sub-pages are pushed via `contentNavigator`
- Each breadcrumb segment is clickable to pop directly to that navigation level
- Root segment shows tab label (tabbed mode) or "Home" (non-tabbed mode)
- Horizontal scroll for long breadcrumb trails

### Removed
- `_BackButtonBar` widget (replaced by breadcrumb strip)
```

- [ ] **Step 3: Run final verification**

```bash
flutter analyze && flutter test
```
Expected: No issues, all tests pass

- [ ] **Step 4: Commit**

```bash
git add pubspec.yaml CHANGELOG.md
git commit -m "chore: bump version to 0.6.0, update CHANGELOG"
```
