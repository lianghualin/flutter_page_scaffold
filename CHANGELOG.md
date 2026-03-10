## 0.2.3

- Feat: Add `showCard` parameter — set to `false` to disable the card container for dashboard-style layouts
- Feat: Add `PageScaffoldScope` InheritedWidget — `MainAreaSection` automatically switches to white background with shadow when card is disabled
- Feat: Animated transitions when toggling `showCard` on both `MainAreaTemplate` and `MainAreaSection` (300ms ease-in-out)

## 0.2.2

- Feat: Add `maintainState` parameter — set to `false` to dispose unselected tabs instead of keeping all alive via `IndexedStack`
- Feat: Add `tabTransitionDuration` parameter — enables fade-in animation when switching tabs
- Feat: Add `tabBarBuilder` callback and `TabBarBuilder` typedef — replace the default tab bar with a fully custom widget
- Fix: Use `TickerProviderStateMixin` to support runtime animation toggling without ticker errors

## 0.2.1

- Redesign tab bar: moved inside the content card with underline indicator for better visibility
- Increased tab text (14px) and icon (18px) sizes for improved readability
- Added full-width divider between tab bar and content
- Fixed sharp corner artifact on first tab's ink ripple in rounded card

## 0.2.0

- Feat: Add multi-page tab navigation with `tabs` parameter and `PageTab` class
- Feat: Add `showTitle` parameter to toggle title row visibility
- Feat: Add `showTabs` parameter to toggle tab bar visibility
- Feat: Add `initialTabIndex` and `onTabChanged` for tab state management
- Uses `IndexedStack` to preserve tab state across switches
- Fully backward compatible — existing single-page usage unchanged

## 0.1.1

- Fix: Wrap root widget with `Material` to provide Material ancestor for child widgets (e.g. `DropdownButton`, `InkWell`, `TextField`)

## 0.1.0

- Initial release
- `MainAreaTemplate` widget for page-level layouts with title, description, icon, and actions
- `MainAreaSection` widget for grouped content cards with accent-bar headers
- Theme-aware styling using `ColorScheme` tokens
- `expanded` parameter for sections that fill remaining space
