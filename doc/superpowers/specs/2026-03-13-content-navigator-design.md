# Content Navigator Design Spec

**Date:** 2026-03-13
**Status:** Draft
**Package:** flutter_page_scaffold

## Problem

When `MainAreaTemplate` is used inside a sidebar-based layout, child widgets that call `Navigator.push` push onto the root navigator, covering the entire screen (sidebar, title bar, and tabs). Users need sub-page navigation that stays within the content card area.

A manual workaround — wrapping tab content in a nested `Navigator` — works for single-tab layouts but breaks multi-tab layouts because `MaterialPageRoute`'s `ModalRoute` creates a `FocusTrap` that blocks the tab bar's `InkWell` tap events.

## Solution

Add an opt-in `contentNavigator` flag to `MainAreaTemplate` that inserts a single `Navigator` widget below the title/tab bar, wrapping the content area. Consumer code calls `Navigator.push(context, ...)` as usual; pushed routes render inside the card area.

## API

### New parameters on `MainAreaTemplate`

```dart
MainAreaTemplate(
  title: 'Device Monitor',
  contentNavigator: true,          // default: false — opt-in
  contentNavigatorShowTabs: true,   // default: true — tabs stay visible (Option A)
  tabs: [
    PageTab(label: 'Switches', child: SwitchList()),
    PageTab(label: 'Hosts', child: HostList()),
  ],
);
```

- **`contentNavigator`** (`bool`, default `false`) — When `true`, wraps the content area in a `Navigator`. When `false`, behavior is identical to current implementation with zero overhead.
- **`contentNavigatorShowTabs`** (`bool`, default `true`) — Only effective when `contentNavigator: true`. Matches existing `showTabs`/`showTitle`/`showCard` naming convention.
  - `true` (Option A): Tabs remain visible when a sub-page is pushed. Tapping any tab (including the current one) pops the stack to root.
  - `false` (Option B): Tabs are hidden when a sub-page is pushed. A back button and the sub-page title (from `RouteSettings.name`) replace the tab bar.

### Consumer usage

Standard Flutter navigation — no new APIs to learn:

```dart
// Inside a tab's content widget:
Navigator.push(
  context,
  MaterialPageRoute(
    settings: RouteSettings(name: 'Switch Details'), // becomes title bar text in Option B
    builder: (context) => SwitchDetailPage(sw: sw),
  ),
);
```

### Non-tabbed mode

Works identically with `child` instead of `tabs`:

```dart
MainAreaTemplate(
  title: 'Inventory',
  contentNavigator: true,
  child: InventoryList(), // can call Navigator.push safely
);
```

## Architecture

### Widget tree (`contentNavigator: true`)

```
MainAreaTemplate
  ├── _UnifiedBar / _TitleArea  (title + tabs or back button)
  └── Expanded (card container)
      └── Navigator (key: _navigatorKey)
           └── Route: current tab's child (or pushed sub-page)
```

### Internal state in `_MainAreaTemplateState`

| Field | Type | Purpose |
|---|---|---|
| `_navigatorKey` | `GlobalKey<NavigatorState>` | Access to the nested Navigator for programmatic pop/push |
| `_stackDepth` | `int` | Number of routes above root. Updated via `_ContentNavigatorObserver` (`didPush`/`didPop`/`didRemove`). Drives Option B title bar switching |
| `_currentRouteTitle` | `String?` | Extracted from top route's `RouteSettings.name`. Displayed in Option B back-button mode |

### Navigator API paradigm

The implementation uses the **imperative** Navigator API exclusively (`Navigator.push` / `Navigator.pop` / `popUntil`). The declarative `pages` parameter of `Navigator` is **not** used. This avoids subtle bugs from mixing paradigms and matches how consumers will interact with the Navigator.

### `_onTabSelected` modification

The existing `_onTabSelected` guards against same-index taps with `if (index != _selectedIndex)`. When `contentNavigator: true`, this guard must be relaxed: tapping the already-selected tab should still trigger `popUntil` to reset the navigation stack. The guard remains for the non-navigator case to avoid unnecessary rebuilds.

```dart
void _onTabSelected(int index) {
  if (widget.contentNavigator && _stackDepth > 0) {
    // Always pop to root, even if same tab
    _navigatorKey.currentState!.popUntil((route) => route.isFirst);
  }
  if (index != _selectedIndex) {
    setState(() => _selectedIndex = index);
    _animationController?.forward(from: 0.0);
    widget.onTabChanged?.call(index);
  }
}
```

### Tab switching flow

1. User taps a tab (including the currently selected tab)
2. `_onTabSelected` pops the Navigator to root via `popUntil`
3. `setState` updates `_selectedIndex`, causing the root route's builder to rebuild
4. `_stackDepth` resets to 0 (via `NavigatorObserver.didPop` callbacks during `popUntil`)
5. If Option B was active, tabs reappear

### Root route strategy

The Navigator uses `onGenerateRoute` to create the initial root route as a `PageRouteBuilder` with no transition. The root route's `builder` closure references `_selectedIndex` on the live state object, so it rebuilds reactively when `setState` updates the index:

```dart
onGenerateRoute: (_) => PageRouteBuilder(
  pageBuilder: (context, _, __) {
    final content = widget.tabs != null
        ? (widget.maintainState
            ? IndexedStack(
                index: _selectedIndex,
                children: widget.tabs!.map((t) => t.child).toList(),
              )
            : widget.tabs![_selectedIndex].child)
        : widget.child!;
    return content;
  },
  transitionDuration: Duration.zero,
),
```

This ensures tab content swaps happen by rebuilding the existing root route (no push/remove cycle needed). Consumer-pushed `MaterialPageRoute`s retain their normal slide transitions.

### `_stackDepth` tracking via `NavigatorObserver`

A custom `_ContentNavigatorObserver` tracks the navigation stack:

- **`didPush(Route route, Route? previousRoute)`** — increments `_stackDepth` (skipping the initial root route push). Captures `route.settings.name` into `_currentRouteTitle`.
- **`didPop(Route route, Route? previousRoute)`** — decrements `_stackDepth`. Updates `_currentRouteTitle` to `previousRoute.settings.name` (or `null` if back to root).
- **`didRemove(Route route, Route? previousRoute)`** — handles routes removed by `popUntil`. Decrements `_stackDepth` for each removal.

All three callbacks call `setState` to trigger title bar rebuilds.

### FocusTrap resolution

The FocusTrap problem is avoided by design: the `Navigator` sits **below** the tab bar in the widget tree, not beside or around it. The tab bar's `InkWell` widgets are never inside a `ModalRoute`'s focus scope.

## Title Bar Behavior

### Option A (`contentNavigatorShowTabs: true`, default)

```
┌─────────────────────────────────────────────────────────┐
│  icon  Title  (?)  │  [Tab1]  [Tab2]  [Tab3]   actions  │
├─────────────────────────────────────────────────────────┤
│  (sub-page content — tabs still visible above)           │
└─────────────────────────────────────────────────────────┘
```

- Tab bar is always visible regardless of stack depth
- Tapping any tab pops the stack to root and shows that tab's content
- No back button rendered by `MainAreaTemplate` — consumer can include one in their sub-page if desired

### Option B (`contentNavigatorShowTabs: false`)

**Stack depth = 0 (root):**
```
┌─────────────────────────────────────────────────────────┐
│  icon  Title  (?)  │  [Tab1]  [Tab2]  [Tab3]   actions  │
├─────────────────────────────────────────────────────────┤
│  (tab root content)                                      │
└─────────────────────────────────────────────────────────┘
```

**Stack depth > 0 (sub-page pushed):**
```
┌─────────────────────────────────────────────────────────┐
│  ← Back    Sub-page Title                       actions  │
├─────────────────────────────────────────────────────────┤
│  (sub-page content)                                      │
└─────────────────────────────────────────────────────────┘
```

- Back button calls `_navigatorKey.currentState!.pop()`
- Title text comes from the top route's `RouteSettings.name`
- If `RouteSettings.name` is null, falls back to the original `title`
- When stack pops back to root (depth = 0), tabs reappear
- `MainAreaTemplate.actions` remain visible in both states

### Option B visibility matrix with `showTitle` and `icon`

| State | `showTitle` | `icon` | Back button | Title text | Tabs |
|---|---|---|---|---|---|
| Root (depth=0) | `true` | shown | no | original title | visible |
| Root (depth=0) | `false` | hidden | no | hidden | visible |
| Sub-page (depth>0) | any | hidden | yes | `RouteSettings.name` or fallback to original title | hidden |

When a sub-page is pushed in Option B, the back button always appears regardless of `showTitle`. The `icon` is hidden in sub-page state to keep the back-button bar clean.

## Files to Modify

| File | Change |
|---|---|
| `lib/src/page_scaffold.dart` | Main implementation: new parameters, Navigator wrapper, observer, title bar modes |
| `test/page_scaffold_test.dart` | New test groups for contentNavigator feature |
| `example/lib/main.dart` | Playground toggle for contentNavigator demo |
| `CHANGELOG.md` | Version bump + feature entry |
| `pubspec.yaml` | Version bump |

## Edge Cases & Constraints

1. **`maintainState` interaction** — With `contentNavigator: true`, the root route's builder uses `IndexedStack` (when `maintainState: true`) or renders only the selected tab's child (when `false`). When a sub-page is pushed on top of the root route, the root route remains mounted underneath per standard Navigator behavior — this means all tab children in the `IndexedStack` stay alive during sub-page navigation. This is intentional and consistent with how `maintainState` works without `contentNavigator`.

2. **`Navigator.pop` from root** — The Navigator's `onPopPage` rejects pops at the root route (returns `false`) to prevent a blank content area.

3. **Deep push chains** — Multiple levels of `Navigator.push` work naturally (list → detail → sub-detail). Tab tap pops all levels to root. In Option B mode, the back button pops one level at a time; tabs reappear only at depth 0.

4. **`PopScope` support** — Since a real `Navigator` is used, consumer pages using `PopScope` to guard navigation (e.g., "discard unsaved changes?") work out of the box.

5. **Browser back button (web)** — The nested Navigator does not integrate with browser URL history. This keeps scope minimal; URL-based routing can be a future enhancement.

6. **Non-tabbed mode** — `contentNavigator` works with `child`. Navigator wraps the single child. In Option B mode, title bar switches to back button + route title. Tab-related logic is skipped.

7. **Zero external dependencies** — Uses only `Navigator`, `PageRouteBuilder`, `GlobalKey`, `NavigatorObserver` — all Flutter SDK.

## Testing Strategy

### Existing tests unchanged

All current tests pass without modification when `contentNavigator` defaults to `false`.

### New test groups

**1. `contentNavigator: true`, tabbed mode:**
- Navigator is present in widget tree
- `Navigator.push` from tab content renders sub-page inside the card area
- Tab tap pops stack to root and shows correct tab content
- Tapping the already-selected tab resets the stack
- `RouteSettings.name` is accessible from pushed route

**2. `contentNavigator: true`, non-tabbed mode:**
- Navigator wraps `child`
- Push/pop works within the card area

**3. Option A (`contentNavigatorShowTabs: true`):**
- Tabs remain visible when sub-page is pushed
- Tab switching while sub-page is pushed works correctly

**4. Option B (`contentNavigatorShowTabs: false`):**
- Tabs hidden when stack depth > 0
- Back button appears with correct title from `RouteSettings.name`
- Back button pops one level
- Tabs reappear when stack returns to root
- Null `RouteSettings.name` falls back to original title

**5. Edge cases:**
- `Navigator.pop` at root is rejected (no blank screen)
- Deep push chain (3+ levels) pops correctly on tab switch
- `maintainState` interaction with `contentNavigator`
