# Unified Title-Tab Bar Design

## Summary

Replace the current two-layer layout (separate title area above + tab bar inside card) with a single unified bar where the title, pill-style tabs, and action buttons share one horizontal band. This is a visual/behavioral breaking change — no public parameters are removed, but the rendering of tabs and description changes significantly.

## Current Layout

```
┌─────────────────────────────────────────────┐
│ [icon] Title                     [actions]  │  ← _TitleArea (above card)
│         Description text                    │
├─────────────────────────────────────────────┤
│ ┌─────────────────────────────────────────┐ │
│ │ Devices | Settings | Dashboard          │ │  ← _PageTabBar (inside card)
│ │─────────────────────────────────────────│ │
│ │ Content area                            │ │
│ └─────────────────────────────────────────┘ │
└─────────────────────────────────────────────┘
```

## New Layout

```
┌─────────────────────────────────────────────┐
│ [icon] Title (?) │ [Devices] Settings Dash  │  ← Unified bar (when tabs != null)
│─────────────────────────────────────────────│
│ ┌─────────────────────────────────────────┐ │
│ │ Content area                            │ │  ← Card (no tab bar)
│ └─────────────────────────────────────────┘ │
└─────────────────────────────────────────────┘
```

## Design Decisions

### 1. Pill-style tabs

Selected tab uses a rounded pill with subtle primary background tint (`colorScheme.primary` at 8% alpha). Unselected tabs are plain text. This replaces the underline indicator. `PageTab.icon` is rendered inside the pill before the label, same as current behavior.

### 2. Description as tooltip (tabs mode only)

When `tabs != null`: description moves to a `Tooltip` widget behind a small `?` icon next to the title. When `description` is null, the `?` icon is not shown.

When `tabs == null` (no-tabs mode): description renders as visible text below the title, exactly as today (24px title, 36x36 icon, etc.). No changes to the no-tabs layout.

### 3. Vertical separator

A 1px vertical line (`colorScheme.outlineVariant`) separates the title group from the tab group. Only shown when both `showTitle` and `showTabs` are true and tabs are provided.

### 4. Complete replacement (breaking change)

The old `_PageTabBar` and `_PageTabChip` widgets are removed. There is no `tabPosition` parameter — the unified bar is the only layout. No public API parameters are removed — this is a visual/behavioral breaking change only.

### 5. No-tabs mode unchanged

When `tabs` is null (single-page mode), the existing `_TitleArea` layout is preserved exactly as-is: big title (24px), description below, actions right, icon 36x36. The unified bar visual specs (19px title, 34x34 icon) only apply when `tabs` is provided.

### 6. `showCard: false` interaction

The unified bar renders the same regardless of `showCard`. The bar's bottom border (`colorScheme.outlineVariant`, 1px) provides visual separation from content in both card and no-card modes. The `AnimatedContainer` for the card area continues to handle `showCard` toggling independently.

## Three Layout Modes

The widget operates in three distinct modes based on `tabs`:

| Mode | Condition | Title area rendering |
|---|---|---|
| **No-tabs** | `tabs == null` | Existing `_TitleArea` (24px title, description visible, unchanged) |
| **Tabs visible** | `tabs != null && showTabs == true` | Unified bar (19px title, pill tabs, description as tooltip) |
| **Tabs hidden** | `tabs != null && showTabs == false` | Unified bar title section only (no pills, no separator) |

## Visibility Matrix (applies only when `tabs != null`)

| `showTitle` | `showTabs` | Result |
|---|---|---|
| `true` | `true` | Full bar: icon + title + `?` + separator + pill tabs + actions |
| `true` | `false` | Title + actions only, no tab pills, no separator |
| `false` | `true` | Tabs + actions only, no title/icon/separator |
| `false` | `false` | Entire bar hidden |

## API Changes

### Removed (internal only)

- `_PageTabBar` widget (private)
- `_PageTabChip` widget (private)

### Modified (internal)

- `_TitleArea` widget — kept for no-tabs mode, unchanged
- `description` parameter — rendered as tooltip when `tabs != null`, visible text when `tabs == null`

### Kept (public, unchanged)

- `showTitle` (bool, default true)
- `showTabs` (bool, default true)
- `showCard` (bool, default true)
- `tabBarBuilder` (TabBarBuilder?) — replaces the pill tabs section only. The separator still appears (between title and custom builder output). The builder output is placed inside a `Flexible` widget to prevent overflow. Actions remain at the trailing edge after a `Spacer`.
- `maintainState`, `tabTransitionDuration`, `onTabChanged`, `initialTabIndex` — unchanged
- `actions` — always rendered at the trailing edge of the bar via a `Spacer`, regardless of which combination of title/tabs is visible
- `outerPadding`, `cardPadding` — unchanged, bar sits inside `outerPadding`
- `PageScaffoldScope` InheritedWidget — unchanged

### New Internal Widgets

- `_UnifiedBar` — renders the merged title+tabs+actions bar (used only when `tabs != null`)
- `_PillTab` — single pill tab chip
- `_TooltipIcon` — small `?` circle that shows description via `Tooltip`

## Color Token Mapping (unified bar)

| Element | Token |
|---|---|
| Selected pill bg | `colorScheme.primary` at 8% alpha |
| Selected pill text | `colorScheme.primary` |
| Unselected pill text | `colorScheme.onSurfaceVariant` |
| Pill icon (selected) | `colorScheme.primary` |
| Pill icon (unselected) | `colorScheme.onSurfaceVariant` |
| Bar separator | `colorScheme.outlineVariant` |
| Bar bottom border | `colorScheme.outlineVariant`, 1px |
| Tooltip `?` icon | `colorScheme.onSurfaceVariant` at 35% alpha |

## Visual Specs (unified bar only — no-tabs mode retains existing dimensions)

- Title font: 19px, weight 700, `colorScheme.onSurface`
- Icon container: 34x34px, 9px border radius, primary at 8% alpha
- Gap between icon and title: 10px
- Gap between title and `?` icon: 8px
- Pill padding: 6px vertical, 14px horizontal
- Pill border radius: 18px
- Pill font: 13px, weight 600 (selected) / 400 (unselected)
- Pill icon: 14px, before label with 5px gap
- Pill gap between pills: 4px
- Separator: 1px wide, 22px tall, 20px horizontal margin
- Bar padding: 14px vertical
- Bar bottom border: 1px, rendered as bottom `BorderSide` on the bar `Container`
- `?` icon: 14px diameter circle, only shown when `description != null`. Uses Flutter `Tooltip` widget (provides built-in semantics and long-press on mobile).
- Pill tabs use `InkWell` with `borderRadius` matching pill radius for hover/focus/ripple feedback. Visual height is ~25px (desktop-oriented); `InkWell` handles focus/keyboard automatically.

## Migration Guide

No public API parameters are removed. Existing code using `MainAreaTemplate` with `tabs` will compile without changes. The visual differences are:

1. Tabs move from inside the card to the title bar
2. Tab indicator changes from underline to pill
3. Description becomes a tooltip (hover `?` icon) when tabs are present
4. Title font shrinks from 24px to 19px in tabbed mode

Consumers using `tabBarBuilder` get their custom widget placed in the same position (after the separator, before actions). The callback signature is unchanged.

## Files to Modify

1. `lib/src/page_scaffold.dart` — Add `_UnifiedBar`, `_PillTab`, `_TooltipIcon`. Remove `_PageTabBar`, `_PageTabChip`. Keep `_TitleArea` for no-tabs mode. Update `_MainAreaTemplateState.build()` to branch on `tabs != null`.
2. `test/page_scaffold_test.dart` — Update tests for new layout structure. Add tests for visibility matrix and tooltip behavior.
3. `example/lib/main.dart` — Update playground to reflect new layout.
4. `CHANGELOG.md` — Add breaking change entry.
5. `pubspec.yaml` — Version bump.
