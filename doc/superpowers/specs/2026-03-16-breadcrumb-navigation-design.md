# Breadcrumb Navigation for contentNavigator

**Date:** 2026-03-16
**Status:** Approved
**Replaces:** Back button bar (Option B) from 0.5.0

## Problem

When `contentNavigator: true` and a sub-page is pushed, there is no back button in Option A (tabs visible). Users have no way to navigate back except clicking a tab. The previous Option B (`contentNavigatorShowTabs: false`) provided a back button but hid tabs and only showed the current route title — no breadcrumb trail. Two separate navigation modes added complexity without solving the core UX issue: users need to see where they are in the stack and navigate to any ancestor level.

## Solution

Replace both Option A and Option B with a single breadcrumb strip inside the content card. Delete `contentNavigatorShowTabs` parameter and `_BackButtonBar` widget entirely.

## API Changes

### Removed
- `contentNavigatorShowTabs` parameter on `MainAreaTemplate`
- `_BackButtonBar` private widget
- `_shouldShowBackBar` getter

### Unchanged
- `contentNavigator` parameter (default: `false`)

### Breaking Change

Removing `contentNavigatorShowTabs` is a breaking API change. Callers using `contentNavigatorShowTabs: false` should simply remove the parameter — the breadcrumb strip now provides the same navigation affordance unconditionally. Requires a version bump to **0.6.0**.

## Breadcrumb Strip Widget

A new `_BreadcrumbBar` widget renders inside the card, between the card's top edge and the Navigator content. It appears only when navigation depth > 0.

### Visual Design

- Background: `colorScheme.surfaceContainerHigh`
- Bottom border: `colorScheme.outline` at 1px
- Padding: 8px vertical, 20px horizontal (hardcoded, not inherited from cardPadding)
- Height: auto (single line)
- Overflow: horizontal scroll via `SingleChildScrollView(scrollDirection: Axis.horizontal)` for long breadcrumb trails

### Segments

Format: `← Root / Ancestor1 / Ancestor2 / Current`

| Segment | Style | Behavior |
|---------|-------|----------|
| Root (first) | `← label` in `colorScheme.primary`, 13px | Pops entire stack to root (`popUntil isFirst`) |
| Ancestors (middle) | `colorScheme.primary`, 13px, clickable via `InkWell` | Pops to that specific level |
| Current (last) | `colorScheme.onSurface`, 13px, **bold** | Non-clickable |
| Separator | `/` in `colorScheme.outlineVariant`, 14px | Non-interactive |

Each clickable segment is wrapped in an `InkWell` for tap handling and accessibility.

### Root Label

- **Tabbed mode:** Active tab's label (e.g., "Devices")
- **Non-tabbed mode:** "Home"

### Current Page Label

From `RouteSettings.name` of each pushed route. If `RouteSettings.name` is null, the segment displays `"..."` as a placeholder (never empty, never skipped — preserves positional consistency for click-to-pop).

## Observer Changes

`_ContentNavigatorObserver` must track the full route stack, not just depth and current title.

### Current State
```dart
int _depth = 0;
String? _currentTitle;
```

### New State
```dart
final List<String?> _routeStack = [];
```

- `depth` → `_routeStack.length`
- `currentTitle` → `_routeStack.lastOrNull`
- New: `routeStack` getter returns unmodifiable list for breadcrumb rendering

### Stack Operations

- `didPush`: if `previousRoute != null` (not the initial root route), append `route.settings.name` to `_routeStack`
- `didPop`: remove last entry from `_routeStack`
- `didRemove`: remove last entry from `_routeStack`
- `didReplace`: remove last entry from `_routeStack`, append `newRoute.settings.name`

## Navigation Behavior

### Breadcrumb Segment Click

The breadcrumb has visual positions: 0 = root, 1..N-1 = ancestors, N = current (non-clickable).

Clicking ancestor at visual position `p` (where `p` >= 1) corresponds to `_routeStack[p-1]`. It pops `(_routeStack.length - p + 1)` routes. Implementation: use `popUntil` with a counter that decrements on each pop and stops when zero.

### Root Segment Click (← label)

Equivalent to `popUntil((route) => route.isFirst)`.

### Tab Click

Unchanged — pops entire stack to root, then switches tab. Same-tab re-click also pops to root.

## Widget Tree

```
AnimatedContainer (card)
  └ Column
      ├ _BreadcrumbBar (conditional: depth > 0, own padding)
      └ Expanded
          └ Padding (cardPadding)
              └ Navigator (contentNavigator: true)
                  └ PageRouteBuilder (root route)
                      └ content child
```

The breadcrumb sits **outside** the Navigator and **outside** the card padding, but **inside** the card container. It manages its own padding (20px horizontal, 8px vertical) to render edge-to-edge within the card with a distinct background strip. The Navigator content below gets the normal `cardPadding`.

## Edge Cases

- **Depth 0:** Breadcrumb strip completely hidden
- **Missing RouteSettings.name:** Segment displays `"..."` placeholder
- **Tab switch while deep:** Stack pops to root, breadcrumb disappears
- **showCard: false:** Breadcrumb still renders (has its own background)
- **showTitle: false, showTabs: false:** Breadcrumb still works — independent of title bar
- **contentNavigator: false:** Breadcrumb never renders (feature fully gated)
- **pushReplacement:** Observer `didReplace` updates the last stack entry

## Color Token Mapping

| Element | Token |
|---------|-------|
| Breadcrumb strip background | `colorScheme.surfaceContainerHigh` |
| Breadcrumb strip border | `colorScheme.outline` |
| Clickable segment text | `colorScheme.primary` |
| Current segment text | `colorScheme.onSurface` |
| Separator `/` | `colorScheme.outlineVariant` |
| Back arrow `←` | `colorScheme.primary` |

## Test Plan

- Breadcrumb hidden at depth 0
- Breadcrumb hidden when `contentNavigator: false`
- Breadcrumb appears at depth 1 with correct root label + current page
- Breadcrumb shows full path at depth 3
- Clicking root segment pops to root
- Clicking middle segment pops to that specific level
- Tab switch clears breadcrumb
- Non-tabbed mode shows "Home" as root label
- Missing RouteSettings.name shows "..." placeholder
- `contentNavigatorShowTabs` parameter no longer exists (breaking change)
- pushReplacement updates breadcrumb correctly
