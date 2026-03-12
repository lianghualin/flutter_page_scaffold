# Tabbed Pages Design

## Goal

Add multi-page tab navigation to `MainAreaTemplate` with toggleable title and tab bar visibility.

## API

New data class:

```dart
class PageTab {
  final String label;
  final IconData? icon;
  final Widget child;
  const PageTab({required this.label, this.icon, required this.child});
}
```

New parameters on `MainAreaTemplate`:

| Parameter | Type | Default | Description |
|---|---|---|---|
| `tabs` | `List<PageTab>?` | `null` | Tab definitions. Null = single page (current behavior) |
| `showTitle` | `bool` | `true` | Show/hide title row |
| `showTabs` | `bool` | `true` | Show/hide tab bar (only when `tabs != null`) |
| `initialTabIndex` | `int` | `0` | Starting tab index |
| `onTabChanged` | `ValueChanged<int>?` | `null` | Callback on tab switch |

## Layout Matrix

| `tabs` | `showTitle` | `showTabs` | Result |
|---|---|---|---|
| null | true | * | Current behavior (single page with title) |
| null | false | * | Single page, no title (just content card) |
| provided | true | true | Title + Tabs + Content (layout B) |
| provided | false | true | Tabs + Content (layout A) |
| provided | true | false | Title + Content of active tab |
| provided | false | false | Content card of active tab only |

## Tab Bar Visual Design

- Sits between title area and content card
- Tab chips: rounded 6px corners, 4px spacing
- Selected: `primary` at 12% alpha bg, `primary` text, `w600`
- Unselected: transparent bg, `onSurfaceVariant` text, `w400`
- Icon: 15px, color follows text
- Gap: 12px below title, 16px above content card

## State Management

- `MainAreaTemplate` becomes `StatefulWidget`
- Tracks selected tab index internally
- Uses `IndexedStack` to preserve child state across tab switches
- `onTabChanged` fires on every tab switch

## Backward Compatibility

- All new parameters are optional with sensible defaults
- When `tabs` is null, behavior is identical to v0.1.1
- `child` is used for single-page mode, ignored when `tabs` is provided

## Color Tokens (unchanged)

Same token mapping as existing design — no new tokens needed. Tab chips use `primary` and `onSurfaceVariant` already in the palette.

## Deliverables

1. Add `PageTab` class to `lib/src/page_scaffold.dart`
2. Update `MainAreaTemplate` with new parameters
3. Convert to `StatefulWidget`
4. Add `_TabBar` private widget
5. Update barrel export (if needed)
6. Add tests for new tab functionality
7. Update example app to use built-in tabs
8. Update README.md with tabbed pages documentation
9. Bump version, update CHANGELOG
