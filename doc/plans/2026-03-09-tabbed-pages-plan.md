# Tabbed Pages Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add multi-page tab navigation to `MainAreaTemplate` with toggleable title and tab bar visibility, fully backward compatible.

**Architecture:** Add optional `tabs` parameter to `MainAreaTemplate`. When provided, renders a tab strip (between title and content card) and swaps content via `IndexedStack`. Widget converts from `StatelessWidget` to `StatefulWidget` to track selected tab index internally. When `tabs` is null, behavior is identical to current v0.1.1.

**Tech Stack:** Flutter SDK only (no new dependencies)

---

### Task 1: Add `PageTab` data class

**Files:**
- Modify: `lib/src/page_scaffold.dart:1-3` (add class before `MainAreaTemplate`)
- Test: `test/page_scaffold_test.dart`

**Step 1: Write the failing test**

Add to `test/page_scaffold_test.dart` inside `main()`, after the existing group:

```dart
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
```

**Step 2: Run test to verify it fails**

Run: `flutter test test/page_scaffold_test.dart`
Expected: FAIL — `PageTab` is not defined

**Step 3: Write minimal implementation**

Add at the top of `lib/src/page_scaffold.dart`, after the import:

```dart
/// Data class representing a single tab in a [MainAreaTemplate].
class PageTab {
  /// The tab label displayed in the tab bar.
  final String label;

  /// Optional icon displayed before the label.
  final IconData? icon;

  /// The content widget shown when this tab is selected.
  final Widget child;

  const PageTab({required this.label, this.icon, required this.child});
}
```

**Step 4: Run test to verify it passes**

Run: `flutter test test/page_scaffold_test.dart`
Expected: ALL PASS

**Step 5: Commit**

```bash
git add lib/src/page_scaffold.dart test/page_scaffold_test.dart
git commit -m "feat: add PageTab data class"
```

---

### Task 2: Add new parameters and convert to StatefulWidget

**Files:**
- Modify: `lib/src/page_scaffold.dart:13-93` (`MainAreaTemplate` class)
- Test: `test/page_scaffold_test.dart`

**Step 1: Write the failing test**

Add to `test/page_scaffold_test.dart` inside the `MainAreaTemplate` group:

```dart
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
```

**Step 2: Run test to verify it fails**

Run: `flutter test test/page_scaffold_test.dart`
Expected: FAIL — `showTitle` parameter does not exist

**Step 3: Convert `MainAreaTemplate` to StatefulWidget and add parameters**

Replace the `MainAreaTemplate` class in `lib/src/page_scaffold.dart`:

```dart
class MainAreaTemplate extends StatefulWidget {
  /// Page title, displayed large and bold.
  final String title;

  /// Optional subtitle/description, displayed smaller and muted below title.
  final String? description;

  /// Optional icon displayed before the title.
  final IconData? icon;

  /// Optional action widgets displayed to the right of the title row.
  final List<Widget>? actions;

  /// The main page content. Used when [tabs] is null.
  /// Ignored when [tabs] is provided.
  final Widget? child;

  /// Padding around the entire template. Defaults to EdgeInsets.all(24).
  final EdgeInsetsGeometry? outerPadding;

  /// Padding inside the content card. Defaults to EdgeInsets.all(20).
  final EdgeInsetsGeometry? cardPadding;

  /// Optional list of tabs for multi-page navigation.
  /// When provided, renders a tab bar and uses [IndexedStack] to swap content.
  /// When null, falls back to single-page mode using [child].
  final List<PageTab>? tabs;

  /// Whether to show the title row. Defaults to true.
  final bool showTitle;

  /// Whether to show the tab bar. Defaults to true.
  /// Only has effect when [tabs] is provided.
  final bool showTabs;

  /// The initial tab index. Defaults to 0.
  final int initialTabIndex;

  /// Called when the selected tab changes.
  final ValueChanged<int>? onTabChanged;

  const MainAreaTemplate({
    super.key,
    required this.title,
    this.description,
    this.icon,
    this.actions,
    this.child,
    this.outerPadding,
    this.cardPadding,
    this.tabs,
    this.showTitle = true,
    this.showTabs = true,
    this.initialTabIndex = 0,
    this.onTabChanged,
  }) : assert(
         tabs != null || child != null,
         'Either tabs or child must be provided',
       );

  @override
  State<MainAreaTemplate> createState() => _MainAreaTemplateState();
}

class _MainAreaTemplateState extends State<MainAreaTemplate> {
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialTabIndex;
  }

  void _onTabSelected(int index) {
    if (index != _selectedIndex) {
      setState(() => _selectedIndex = index);
      widget.onTabChanged?.call(index);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final contentChild = widget.tabs != null
        ? IndexedStack(
            index: _selectedIndex,
            children: widget.tabs!.map((t) => t.child).toList(),
          )
        : widget.child!;

    return Material(
      color: theme.scaffoldBackgroundColor,
      child: Padding(
        padding: widget.outerPadding ?? const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.showTitle)
              _TitleArea(
                title: widget.title,
                description: widget.description,
                icon: widget.icon,
                actions: widget.actions,
              ),
            if (widget.showTitle &&
                (widget.tabs != null && widget.showTabs))
              const SizedBox(height: 12),
            if (widget.tabs != null && widget.showTabs)
              _PageTabBar(
                tabs: widget.tabs!,
                selectedIndex: _selectedIndex,
                onTabSelected: _onTabSelected,
              ),
            if (widget.showTitle || (widget.tabs != null && widget.showTabs))
              const SizedBox(height: 16),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.shadow.withValues(alpha: 0.06),
                      offset: const Offset(0, 2),
                      blurRadius: 12,
                      spreadRadius: 0,
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: Padding(
                  padding: widget.cardPadding ?? const EdgeInsets.all(20),
                  child: contentChild,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

**Step 4: Run test to verify it passes**

Run: `flutter test test/page_scaffold_test.dart`
Expected: ALL PASS (including all 4 existing tests — backward compatible)

**Step 5: Run analyze**

Run: `flutter analyze`
Expected: No issues found

**Step 6: Commit**

```bash
git add lib/src/page_scaffold.dart test/page_scaffold_test.dart
git commit -m "feat: convert MainAreaTemplate to StatefulWidget with showTitle parameter"
```

---

### Task 3: Add `_PageTabBar` private widget

**Files:**
- Modify: `lib/src/page_scaffold.dart` (add `_PageTabBar` and `_PageTabChip` after `_TitleArea`)
- Test: `test/page_scaffold_test.dart`

**Step 1: Write the failing test**

Add to `test/page_scaffold_test.dart` inside the `MainAreaTemplate` group:

```dart
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
```

**Step 2: Run test to verify it fails**

Run: `flutter test test/page_scaffold_test.dart`
Expected: FAIL — `_PageTabBar` is not defined (build method references it)

**Step 3: Write `_PageTabBar` and `_PageTabChip`**

Add to `lib/src/page_scaffold.dart` after the `_TitleArea` class:

```dart
class _PageTabBar extends StatelessWidget {
  final List<PageTab> tabs;
  final int selectedIndex;
  final ValueChanged<int> onTabSelected;

  const _PageTabBar({
    required this.tabs,
    required this.selectedIndex,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (int i = 0; i < tabs.length; i++) ...[
          if (i > 0) const SizedBox(width: 4),
          _PageTabChip(
            label: tabs[i].label,
            icon: tabs[i].icon,
            selected: selectedIndex == i,
            onTap: () => onTabSelected(i),
          ),
        ],
      ],
    );
  }
}

class _PageTabChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool selected;
  final VoidCallback onTap;

  const _PageTabChip({
    required this.label,
    this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: selected
          ? colorScheme.primary.withValues(alpha: 0.12)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 15,
                  color: selected
                      ? colorScheme.primary
                      : colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 5),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  color: selected
                      ? colorScheme.primary
                      : colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

**Step 4: Run test to verify it passes**

Run: `flutter test test/page_scaffold_test.dart`
Expected: ALL PASS

**Step 5: Run analyze**

Run: `flutter analyze`
Expected: No issues found

**Step 6: Commit**

```bash
git add lib/src/page_scaffold.dart test/page_scaffold_test.dart
git commit -m "feat: add tab bar navigation to MainAreaTemplate"
```

---

### Task 4: Update barrel export

**Files:**
- Check: `lib/flutter_page_scaffold.dart`

**Step 1: Verify `PageTab` is exported**

`PageTab` lives in `lib/src/page_scaffold.dart` which is already exported by the barrel file. No changes needed — verify by checking the import works in tests.

Run: `flutter test`
Expected: ALL PASS

**Step 2: Commit (skip if no changes)**

No commit needed.

---

### Task 5: Update example app to use built-in tabs

**Files:**
- Modify: `example/lib/main.dart`

**Step 1: Refactor example to use `MainAreaTemplate` tabs**

The example app currently uses an external `_ControlBar` + `IndexedStack` to switch between three separate `MainAreaTemplate` pages. Refactor to use a single `MainAreaTemplate` with `tabs`.

Replace the `_PlaygroundAppState.build` method body from line 113 onwards. The `_ControlBar` changes to only have the theme switcher (no page tabs), and the three demo pages become `PageTab` children inside a single `MainAreaTemplate`.

Replace `_PlaygroundAppState.build`:

```dart
@override
Widget build(BuildContext context) {
  return MaterialApp(
    title: 'Flutter Page Scaffold Playground',
    debugShowCheckedModeBanner: false,
    theme: _themeData,
    home: Scaffold(
      body: Column(
        children: [
          _ThemeBar(
            currentTheme: _currentTheme,
            onThemeChanged: (t) => setState(() => _currentTheme = t),
          ),
          Expanded(
            child: MainAreaTemplate(
              title: 'Network Manager',
              description: 'Manage network infrastructure.',
              icon: Icons.router,
              tabs: const [
                PageTab(
                  label: 'Devices',
                  icon: Icons.table_chart_outlined,
                  child: TableDemoContent(),
                ),
                PageTab(
                  label: 'Settings',
                  icon: Icons.settings_outlined,
                  child: SettingsDemoContent(),
                ),
                PageTab(
                  label: 'Dashboard',
                  icon: Icons.dashboard_outlined,
                  child: DashboardDemoContent(),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
```

Remove `_selectedPage` state. Simplify `_ControlBar` to `_ThemeBar` (theme switcher only — remove page tabs). Refactor the three demo page classes (`TableDemoPage`, `SettingsDemoPage`, `DashboardDemoPage`) from full `MainAreaTemplate` wrappers into content-only widgets (`TableDemoContent`, `SettingsDemoContent`, `DashboardDemoContent`) that return just the `Column` of `MainAreaSection` children.

**Step 2: Run the example**

Run: `cd example && flutter run -d chrome`
Verify: Tabs render, switching works, all three page contents display correctly, theme switcher still works.

**Step 3: Commit**

```bash
git add example/lib/main.dart
git commit -m "refactor: update example app to use built-in tab navigation"
```

---

### Task 6: Update README.md

**Files:**
- Modify: `README.md`

**Step 1: Add tabbed pages documentation**

Add a new section after "Settings page layout" in the Usage section:

```markdown
### Tabbed page layout

```dart
MainAreaTemplate(
  title: 'Network Manager',
  description: 'Manage network infrastructure.',
  icon: Icons.router,
  tabs: [
    PageTab(
      label: 'Devices',
      icon: Icons.table_chart_outlined,
      child: Column(children: [/* device list content */]),
    ),
    PageTab(
      label: 'Settings',
      icon: Icons.settings_outlined,
      child: Column(children: [/* settings content */]),
    ),
  ],
  onTabChanged: (index) => print('Switched to tab $index'),
)
```

### Tabs without title (compact mode)

```dart
MainAreaTemplate(
  title: 'Manager',        // still required but hidden
  showTitle: false,
  tabs: [
    PageTab(label: 'Tab A', child: ContentA()),
    PageTab(label: 'Tab B', child: ContentB()),
  ],
)
```
```

Update the API Reference table for `MainAreaTemplate` to add new parameters:

```markdown
| `tabs` | `List<PageTab>?` | No | Tab definitions for multi-page navigation. When null, uses `child` |
| `showTitle` | `bool` | No | Show/hide the title row (default: true) |
| `showTabs` | `bool` | No | Show/hide the tab bar (default: true, only when `tabs` is provided) |
| `initialTabIndex` | `int` | No | Starting tab index (default: 0) |
| `onTabChanged` | `ValueChanged<int>?` | No | Callback when selected tab changes |
```

Add a `PageTab` API reference table:

```markdown
### PageTab

| Property | Type | Required | Description |
|---|---|---|---|
| `label` | `String` | Yes | Tab label displayed in the tab bar |
| `icon` | `IconData?` | No | Icon displayed before the label |
| `child` | `Widget` | Yes | Content widget shown when this tab is selected |
```

Change `child` from `Yes` to `No*` in the `MainAreaTemplate` table and add footnote: `* Required when tabs is null`

**Step 2: Commit**

```bash
git add README.md
git commit -m "docs: add tabbed pages documentation to README"
```

---

### Task 7: Bump version and update CHANGELOG

**Files:**
- Modify: `pubspec.yaml:3`
- Modify: `CHANGELOG.md`

**Step 1: Bump version to 0.2.0**

In `pubspec.yaml`, change `version: 0.1.1` to `version: 0.2.0` (new feature = minor bump).

**Step 2: Add changelog entry**

Prepend to `CHANGELOG.md`:

```markdown
## 0.2.0

- Feat: Add multi-page tab navigation with `tabs` parameter and `PageTab` class
- Feat: Add `showTitle` parameter to toggle title row visibility
- Feat: Add `showTabs` parameter to toggle tab bar visibility
- Feat: Add `initialTabIndex` and `onTabChanged` for tab state management
- Uses `IndexedStack` to preserve tab state across switches
- Fully backward compatible — existing single-page usage unchanged
```

**Step 3: Run all tests**

Run: `flutter test`
Expected: ALL PASS

**Step 4: Run analyze**

Run: `flutter analyze`
Expected: No issues found

**Step 5: Commit**

```bash
git add pubspec.yaml CHANGELOG.md
git commit -m "chore: bump version to 0.2.0, update CHANGELOG"
```
