# Tab Enhancements Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add three tab enhancements to `MainAreaTemplate`: lazy tab rendering (`maintainState`), tab switch animation (`tabTransitionDuration`), and custom tab bar builder (`tabBarBuilder`).

**Architecture:** All three features are additive parameters on the existing `MainAreaTemplate` widget. `maintainState` controls whether `IndexedStack` (keep all tabs alive) or direct child rendering (only mount selected tab) is used. `tabTransitionDuration` adds a `FadeTransition` powered by an `AnimationController` with `SingleTickerProviderStateMixin`. `tabBarBuilder` is a callback that replaces the default `_PageTabBar` widget for full customization.

**Tech Stack:** Flutter, Dart

---

## Background

Current codebase state:
- `lib/src/page_scaffold.dart` — `MainAreaTemplate` (StatefulWidget), `PageTab`, `_PageTabBar`, `_PageTabChip`, `_TitleArea` (368 lines)
- `test/page_scaffold_test.dart` — 13 widget tests (192 lines)
- `example/lib/main.dart` — playground app with 3 demo pages (1174 lines)
- Version: 0.2.1
- All 15 tests pass

### New API Surface

```dart
/// Typedef for custom tab bar builder (goes at top of page_scaffold.dart)
typedef TabBarBuilder = Widget Function(
  List<PageTab> tabs,
  int selectedIndex,
  ValueChanged<int> onTabSelected,
);

// New parameters on MainAreaTemplate:
final bool maintainState;             // default: true (IndexedStack behavior)
final Duration? tabTransitionDuration; // default: null (no animation)
final TabBarBuilder? tabBarBuilder;    // default: null (use built-in _PageTabBar)
```

---

### Task 1: Add `maintainState` parameter

**Files:**
- Modify: `test/page_scaffold_test.dart`
- Modify: `lib/src/page_scaffold.dart`

**Step 1: Write the failing tests**

Add these tests inside the `group('MainAreaTemplate', () {` block, after the existing `'respects initialTabIndex'` test (line 153), in `test/page_scaffold_test.dart`:

```dart
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

      // IndexedStack keeps both children in the tree
      expect(find.text('content A'), findsOneWidget);
      expect(find.text('content B'), findsOneWidget);
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
```

**Step 2: Run tests to verify they fail**

Run: `flutter test test/page_scaffold_test.dart`
Expected: FAIL — `maintainState` parameter doesn't exist yet.

**Step 3: Implement `maintainState` parameter**

In `lib/src/page_scaffold.dart`, add the parameter to `MainAreaTemplate`:

After line 67 (`final ValueChanged<int>? onTabChanged;`), add:

```dart
  /// Whether to keep all tab children mounted when switching tabs.
  /// When true (default), uses [IndexedStack] to preserve tab state.
  /// When false, only the selected tab's child is mounted.
  final bool maintainState;
```

In the constructor (after `this.onTabChanged,` on line 82), add:

```dart
    this.maintainState = true,
```

In `_MainAreaTemplateState.build()`, replace the `contentChild` logic (lines 113-118):

```dart
    Widget contentChild;
    if (widget.tabs != null) {
      if (widget.maintainState) {
        contentChild = IndexedStack(
          index: _selectedIndex,
          children: widget.tabs!.map((t) => t.child).toList(),
        );
      } else {
        contentChild = widget.tabs![_selectedIndex].child;
      }
    } else {
      contentChild = widget.child!;
    }
```

**Step 4: Run tests to verify they pass**

Run: `flutter test test/page_scaffold_test.dart`
Expected: All 18 tests PASS (15 existing + 3 new).

**Step 5: Commit**

```bash
git add test/page_scaffold_test.dart lib/src/page_scaffold.dart
git commit -m "feat: add maintainState parameter for lazy tab rendering"
```

---

### Task 2: Add `tabTransitionDuration` parameter

**Files:**
- Modify: `test/page_scaffold_test.dart`
- Modify: `lib/src/page_scaffold.dart`

**Step 1: Write the failing tests**

Add these tests inside the `group('MainAreaTemplate', () {` block, after the `maintainState` tests, in `test/page_scaffold_test.dart`:

```dart
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

      expect(find.byType(FadeTransition), findsNothing);
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

      expect(find.byType(FadeTransition), findsOneWidget);
      final fade = tester.widget<FadeTransition>(find.byType(FadeTransition));
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

      // Tap Tab B
      await tester.tap(find.text('Tab B'));
      await tester.pump(); // one frame after setState

      // Mid-animation: opacity should be < 1.0
      final animating = tester.widget<FadeTransition>(find.byType(FadeTransition));
      expect(animating.opacity.value, lessThan(1.0));

      // Complete animation
      await tester.pumpAndSettle();

      final settled = tester.widget<FadeTransition>(find.byType(FadeTransition));
      expect(settled.opacity.value, 1.0);
    });
```

**Step 2: Run tests to verify they fail**

Run: `flutter test test/page_scaffold_test.dart`
Expected: FAIL — `tabTransitionDuration` parameter doesn't exist yet.

**Step 3: Implement `tabTransitionDuration` parameter**

In `lib/src/page_scaffold.dart`:

**3a.** Add the parameter to `MainAreaTemplate` (after `maintainState`):

```dart
  /// Duration of the fade animation when switching tabs.
  /// When null (default), tab switches are instant with no animation.
  /// Set to a duration (e.g. `Duration(milliseconds: 200)`) to enable a fade-in transition.
  final Duration? tabTransitionDuration;
```

In the constructor (after `this.maintainState = true,`), add:

```dart
    this.tabTransitionDuration,
```

**3b.** Add `SingleTickerProviderStateMixin` and animation fields to `_MainAreaTemplateState`:

Change the class declaration from:
```dart
class _MainAreaTemplateState extends State<MainAreaTemplate> {
```
to:
```dart
class _MainAreaTemplateState extends State<MainAreaTemplate>
    with SingleTickerProviderStateMixin {
```

Add animation fields after `late int _selectedIndex;`:

```dart
  AnimationController? _animationController;
  Animation<double>? _fadeAnimation;
```

**3c.** Add `_initAnimation()` method and update lifecycle methods:

Add after `_selectedIndex = widget.initialTabIndex;` in `initState()`:

```dart
    _initAnimation();
```

Add a new method after `initState()`:

```dart
  void _initAnimation() {
    final duration = widget.tabTransitionDuration;
    if (duration != null && duration > Duration.zero) {
      _animationController = AnimationController(
        duration: duration,
        vsync: this,
      );
      _fadeAnimation = CurvedAnimation(
        parent: _animationController!,
        curve: Curves.easeInOut,
      );
      _animationController!.value = 1.0;
    }
  }
```

Add `didUpdateWidget` and `dispose` methods:

```dart
  @override
  void didUpdateWidget(MainAreaTemplate oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.tabTransitionDuration != oldWidget.tabTransitionDuration) {
      _animationController?.dispose();
      _animationController = null;
      _fadeAnimation = null;
      _initAnimation();
    }
  }

  @override
  void dispose() {
    _animationController?.dispose();
    super.dispose();
  }
```

**3d.** Update `_onTabSelected` to trigger animation:

```dart
  void _onTabSelected(int index) {
    if (index != _selectedIndex) {
      setState(() => _selectedIndex = index);
      _animationController?.forward(from: 0.0);
      widget.onTabChanged?.call(index);
    }
  }
```

**3e.** Wrap content in `FadeTransition` in `build()`:

After the `contentChild` logic (the `if/else` block that sets `contentChild`), add:

```dart
    if (_fadeAnimation != null && widget.tabs != null) {
      contentChild = FadeTransition(
        opacity: _fadeAnimation!,
        child: contentChild,
      );
    }
```

**Step 4: Run tests to verify they pass**

Run: `flutter test test/page_scaffold_test.dart`
Expected: All 21 tests PASS (18 previous + 3 new).

**Step 5: Commit**

```bash
git add test/page_scaffold_test.dart lib/src/page_scaffold.dart
git commit -m "feat: add tabTransitionDuration for fade animation on tab switch"
```

---

### Task 3: Add `tabBarBuilder` parameter

**Files:**
- Modify: `test/page_scaffold_test.dart`
- Modify: `lib/src/page_scaffold.dart`

**Step 1: Write the failing tests**

Add these tests inside the `group('MainAreaTemplate', () {` block, after the animation tests, in `test/page_scaffold_test.dart`:

```dart
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
```

**Step 2: Run tests to verify they fail**

Run: `flutter test test/page_scaffold_test.dart`
Expected: FAIL — `tabBarBuilder` parameter doesn't exist yet.

**Step 3: Implement `tabBarBuilder` parameter**

In `lib/src/page_scaffold.dart`:

**3a.** Add the `TabBarBuilder` typedef after the `PageTab` class (after line 15):

```dart
/// Signature for a function that builds a custom tab bar widget.
///
/// Receives the list of [tabs], the current [selectedIndex], and an
/// [onTabSelected] callback to invoke when a tab is tapped.
typedef TabBarBuilder = Widget Function(
  List<PageTab> tabs,
  int selectedIndex,
  ValueChanged<int> onTabSelected,
);
```

**3b.** Add the parameter to `MainAreaTemplate` (after `tabTransitionDuration`):

```dart
  /// Optional builder for a custom tab bar widget.
  /// When provided, replaces the default underline tab bar.
  /// When null (default), uses the built-in tab bar.
  final TabBarBuilder? tabBarBuilder;
```

In the constructor (after `this.tabTransitionDuration,`), add:

```dart
    this.tabBarBuilder,
```

**3c.** Update `build()` to use `tabBarBuilder` when provided.

Replace the tab bar rendering block. Find this code in `build()`:

```dart
                    if (showTabBarInCard)
                      _PageTabBar(
                        tabs: widget.tabs!,
                        selectedIndex: _selectedIndex,
                        onTabSelected: _onTabSelected,
                      ),
```

Replace with:

```dart
                    if (showTabBarInCard)
                      widget.tabBarBuilder != null
                          ? widget.tabBarBuilder!(
                              widget.tabs!,
                              _selectedIndex,
                              _onTabSelected,
                            )
                          : _PageTabBar(
                              tabs: widget.tabs!,
                              selectedIndex: _selectedIndex,
                              onTabSelected: _onTabSelected,
                            ),
```

**Step 4: Run tests to verify they pass**

Run: `flutter test test/page_scaffold_test.dart`
Expected: All 23 tests PASS (21 previous + 2 new).

**Step 5: Run flutter analyze**

Run: `flutter analyze`
Expected: No issues found.

**Step 6: Commit**

```bash
git add test/page_scaffold_test.dart lib/src/page_scaffold.dart
git commit -m "feat: add tabBarBuilder for custom tab bar widget"
```

---

### Task 4: Update example app

**Files:**
- Modify: `example/lib/main.dart`

**Step 1: Add state variables to `_PlaygroundAppState`**

In `example/lib/main.dart`, add two new state variables to `_PlaygroundAppState` (after line 100 `bool _showTabs = true;`):

```dart
  bool _maintainState = true;
  bool _animate = false;
```

**Step 2: Add toggle chips to `_ControlBar`**

Add two new parameters to `_ControlBar`:

```dart
  final bool maintainState;
  final ValueChanged<bool> onMaintainStateChanged;
  final bool animate;
  final ValueChanged<bool> onAnimateChanged;
```

Add to the `_ControlBar` constructor:

```dart
    required this.maintainState,
    required this.onMaintainStateChanged,
    required this.animate,
    required this.onAnimateChanged,
```

In `_ControlBar.build()`, add two more `_ToggleChip` widgets after the existing `Tabs` toggle (after line 232):

```dart
          const SizedBox(width: 8),
          _ToggleChip(
            label: 'Keep Alive',
            value: maintainState,
            onChanged: onMaintainStateChanged,
          ),
          const SizedBox(width: 8),
          _ToggleChip(
            label: 'Animate',
            value: animate,
            onChanged: onAnimateChanged,
          ),
```

**Step 3: Wire up new toggles in `_PlaygroundAppState.build()`**

Update the `_ControlBar` call in `build()` to pass the new parameters:

```dart
            _ControlBar(
              currentTheme: _currentTheme,
              onThemeChanged: (t) => setState(() => _currentTheme = t),
              showTitle: _showTitle,
              onShowTitleChanged: (v) => setState(() => _showTitle = v),
              showTabs: _showTabs,
              onShowTabsChanged: (v) => setState(() => _showTabs = v),
              maintainState: _maintainState,
              onMaintainStateChanged: (v) => setState(() => _maintainState = v),
              animate: _animate,
              onAnimateChanged: (v) => setState(() => _animate = v),
            ),
```

Update the `MainAreaTemplate` call to use the new parameters:

```dart
              child: MainAreaTemplate(
                title: 'Network Manager',
                description: 'Manage network infrastructure.',
                icon: Icons.router,
                showTitle: _showTitle,
                showTabs: _showTabs,
                maintainState: _maintainState,
                tabTransitionDuration: _animate
                    ? const Duration(milliseconds: 200)
                    : null,
                tabs: const [
                  // ... (existing PageTab list unchanged)
                ],
              ),
```

**Step 4: Run the example app to verify**

Run: `cd example && flutter run -d chrome`
Expected: Two new toggle chips appear in the control bar ("Keep Alive" and "Animate"). Toggling them changes behavior:
- "Keep Alive" OFF → switching tabs doesn't preserve state (e.g., settings dropdowns reset)
- "Animate" ON → tabs fade in when switching

**Step 5: Commit**

```bash
git add example/lib/main.dart
git commit -m "feat: add maintainState and animate toggles to example app"
```

---

### Task 5: Update README, CHANGELOG, and version

**Files:**
- Modify: `README.md`
- Modify: `CHANGELOG.md`
- Modify: `pubspec.yaml`

**Step 1: Update README.md**

Add a new example after the "Tabs without title" section (after line 121), before "## API Reference":

```markdown
### Tabs with animation and lazy rendering

```dart
MainAreaTemplate(
  title: 'Dashboard',
  tabTransitionDuration: const Duration(milliseconds: 200),
  maintainState: false,  // only mount selected tab
  tabs: [
    PageTab(label: 'Overview', child: OverviewContent()),
    PageTab(label: 'Analytics', child: AnalyticsContent()),
  ],
)
```

### Custom tab bar

```dart
MainAreaTemplate(
  title: 'Custom',
  tabs: [
    PageTab(label: 'Tab A', child: ContentA()),
    PageTab(label: 'Tab B', child: ContentB()),
  ],
  tabBarBuilder: (tabs, selectedIndex, onTabSelected) {
    return MyCustomTabBar(
      tabs: tabs,
      selectedIndex: selectedIndex,
      onTabSelected: onTabSelected,
    );
  },
)
```
```

Update the API Reference table for `MainAreaTemplate` — add three new rows after the `onTabChanged` row:

```markdown
| `maintainState` | `bool` | No | Keep all tab children mounted (default: true). Set false to dispose unselected tabs |
| `tabTransitionDuration` | `Duration?` | No | Fade animation duration on tab switch. Null = instant (default) |
| `tabBarBuilder` | `TabBarBuilder?` | No | Custom builder replacing the default tab bar |
```

**Step 2: Update CHANGELOG.md**

Add to the top of `CHANGELOG.md`:

```markdown
## 0.3.0

- Feat: Add `maintainState` parameter — set to `false` to dispose unselected tabs instead of keeping all alive via `IndexedStack`
- Feat: Add `tabTransitionDuration` parameter — enables fade-in animation when switching tabs
- Feat: Add `tabBarBuilder` callback — replace the default tab bar with a fully custom widget
- Feat: Add `TabBarBuilder` typedef for custom tab bar builder signature
```

**Step 3: Bump version in `pubspec.yaml`**

Change line 3 from:
```yaml
version: 0.2.1
```
to:
```yaml
version: 0.3.0
```

**Step 4: Run full verification**

Run: `flutter analyze`
Expected: No issues found.

Run: `flutter test`
Expected: All 23 tests pass.

**Step 5: Commit**

```bash
git add README.md CHANGELOG.md pubspec.yaml
git commit -m "chore: bump version to 0.3.0, update README and CHANGELOG"
```

---

## Verification Checklist

After all tasks are complete, verify:

1. `flutter test` — all 23 tests pass
2. `flutter analyze` — no issues
3. `cd example && flutter run -d chrome` — example app works with all toggles
4. Backward compatibility: existing code using `MainAreaTemplate` without new params works unchanged
