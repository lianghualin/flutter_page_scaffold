# flutter_page_scaffold

A reusable Flutter widget package for consistent, theme-aware main content area layouts. Provides structured page templates with bold titles, section headers with accent bars, and grouped content cards.

![example](https://raw.githubusercontent.com/lianghualin/flutter_page_scaffold/main/example/example.gif)

## Features

- **MainAreaTemplate** -- Page-level wrapper with large title, description, icon, and action buttons
- **MainAreaSection** -- Grouped content card with accent-bar section headers
- **Unified title-tab bar** -- Pill-style tabs merged into the title row for compact navigation
- **Nested navigation** -- `contentNavigator: true` keeps pushed pages inside the card with breadcrumb navigation
- **Card-free mode** -- `showCard: false` for dashboard-style floating layouts
- **Fully theme-aware** -- All colors derived from `Theme.of(context)`, works with any `ThemeData`
- **Zero dependencies** -- Only requires Flutter SDK

## Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  flutter_page_scaffold: ^0.6.0
```

Then run:

```bash
flutter pub get
```

## Usage

### Basic page layout

```dart
import 'package:flutter_page_scaffold/flutter_page_scaffold.dart';

MainAreaTemplate(
  title: 'Network Devices',
  description: 'Manage network switches across all domains.',
  icon: Icons.router,
  actions: [
    FilledButton.icon(
      onPressed: () {},
      icon: const Icon(Icons.add),
      label: const Text('Add'),
    ),
  ],
  child: Column(
    children: [
      MainAreaSection(
        label: 'TOOLBAR',
        child: Row(children: [/* toolbar content */]),
      ),
      const SizedBox(height: 12),
      MainAreaSection(
        label: 'DATA',
        expanded: true,
        child: MyDataTable(),
      ),
    ],
  ),
)
```

### Tabbed page layout (unified bar)

When `tabs` is provided, the title and tabs merge into a single unified bar with pill-style tab chips. The description text becomes a tooltip (hover the `?` icon).

```dart
MainAreaTemplate(
  title: 'Network Manager',
  description: 'Manage network infrastructure.',  // shown as tooltip
  icon: Icons.router,
  actions: [
    FilledButton.icon(
      onPressed: () {},
      icon: const Icon(Icons.add),
      label: const Text('Add Device'),
    ),
  ],
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

### Tab animation and state control

```dart
MainAreaTemplate(
  title: 'Manager',
  maintainState: false,                              // dispose unselected tabs
  tabTransitionDuration: const Duration(milliseconds: 200), // fade animation
  tabs: [
    PageTab(label: 'Tab A', child: ContentA()),
    PageTab(label: 'Tab B', child: ContentB()),
  ],
)
```

### Custom tab bar

```dart
MainAreaTemplate(
  title: 'Custom',
  tabs: [
    PageTab(label: 'One', child: ContentOne()),
    PageTab(label: 'Two', child: ContentTwo()),
  ],
  tabBarBuilder: (tabs, selectedIndex, onTabSelected) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 0; i < tabs.length; i++)
          TextButton(
            onPressed: () => onTabSelected(i),
            child: Text(tabs[i].label),
          ),
      ],
    );
  },
)
```

### Dashboard layout (no card)

```dart
MainAreaTemplate(
  title: 'Dashboard',
  icon: Icons.home_rounded,
  showCard: false,    // content floats directly on page background
  child: Column(
    children: [
      Expanded(child: Row(children: [Card(...), Card(...), Card(...)])),
      Expanded(child: Row(children: [Card(...), Card(...)])),
    ],
  ),
)
```

When `showCard` is `false`, `MainAreaSection` widgets automatically switch from grey to white backgrounds with individual shadows via `PageScaffoldScope`.

### Nested navigation (contentNavigator)

When `contentNavigator` is enabled, `Navigator.push` calls from within tab content render sub-pages **inside the card area** instead of going full-screen. A breadcrumb pill appears on the title bar's divider line showing the navigation path.

```dart
MainAreaTemplate(
  title: 'Network Manager',
  icon: Icons.router,
  contentNavigator: true,  // enable nested navigation
  tabs: [
    PageTab(
      label: 'Devices',
      icon: Icons.table_chart_outlined,
      child: Builder(
        builder: (context) => Column(
          children: [
            MainAreaSection(
              label: 'TOOLBAR',
              child: OutlinedButton.icon(
                onPressed: () {
                  // Push a sub-page — renders inside the card,
                  // not full-screen. Breadcrumb shows automatically.
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      settings: const RouteSettings(name: 'Device Detail'),
                      builder: (_) => const DeviceDetailPage(),
                    ),
                  );
                },
                icon: const Icon(Icons.open_in_new),
                label: const Text('View Detail'),
              ),
            ),
          ],
        ),
      ),
    ),
    PageTab(label: 'Settings', child: SettingsPage()),
  ],
)
```

**How it works:**

- Sub-pages pushed via `Navigator.push` stay inside the content card
- A breadcrumb pill (`← Devices / Device Detail / ...`) floats on the title bar divider line
- Each breadcrumb segment is clickable to pop directly to that level
- Tapping any tab (including the current one) pops the entire navigation stack back to root
- Set `RouteSettings(name: 'Page Title')` on your routes to label breadcrumb segments
- Works in both tabbed and non-tabbed modes (root label shows tab name or "Home")

### Visibility control

The unified bar responds to `showTitle` and `showTabs` independently:

```dart
// Tabs only (no title/icon)
MainAreaTemplate(
  title: 'Manager',        // still required but hidden
  showTitle: false,
  tabs: [
    PageTab(label: 'Tab A', child: ContentA()),
    PageTab(label: 'Tab B', child: ContentB()),
  ],
)

// Title only (tabs hidden, content still switches via initialTabIndex)
MainAreaTemplate(
  title: 'Manager',
  showTabs: false,
  tabs: [...],
)

// Both hidden (just the card content)
MainAreaTemplate(
  title: 'Manager',
  showTitle: false,
  showTabs: false,
  tabs: [...],
)
```

## API Reference

### MainAreaTemplate

| Property | Type | Default | Description |
|---|---|---|---|
| `title` | `String` | *required* | Large bold page title |
| `description` | `String?` | `null` | Tooltip in tabbed mode; visible subtitle in no-tabs mode |
| `icon` | `IconData?` | `null` | Icon displayed before the title in a tinted container |
| `actions` | `List<Widget>?` | `null` | Action buttons at the trailing edge of the title bar |
| `child` | `Widget?` | `null` | Main content (required when `tabs` is null) |
| `outerPadding` | `EdgeInsetsGeometry?` | `EdgeInsets.all(24)` | Padding around the template |
| `cardPadding` | `EdgeInsetsGeometry?` | `EdgeInsets.all(20)` | Padding inside the content card |
| `tabs` | `List<PageTab>?` | `null` | Tab definitions; enables unified title-tab bar |
| `showTitle` | `bool` | `true` | Show/hide title, icon, and description in the bar |
| `showTabs` | `bool` | `true` | Show/hide tab pills (only when `tabs` is provided) |
| `showCard` | `bool` | `true` | Wrap content in a card container with rounded corners and shadow |
| `initialTabIndex` | `int` | `0` | Starting tab index |
| `onTabChanged` | `ValueChanged<int>?` | `null` | Callback when selected tab changes |
| `maintainState` | `bool` | `true` | Keep all tab children mounted via `IndexedStack` |
| `tabTransitionDuration` | `Duration?` | `null` | Fade animation duration when switching tabs |
| `tabBarBuilder` | `TabBarBuilder?` | `null` | Custom tab bar widget builder (replaces pill tabs) |
| `contentNavigator` | `bool` | `false` | Wrap content in a nested Navigator for in-card sub-page navigation with breadcrumb |

### PageTab

| Property | Type | Default | Description |
|---|---|---|---|
| `label` | `String` | *required* | Tab label displayed in the pill chip |
| `icon` | `IconData?` | `null` | Icon displayed before the label inside the pill |
| `child` | `Widget` | *required* | Content widget shown when this tab is selected |

### MainAreaSection

| Property | Type | Default | Description |
|---|---|---|---|
| `label` | `String?` | `null` | Uppercase section header with accent bar |
| `child` | `Widget` | *required* | Section content |
| `padding` | `EdgeInsetsGeometry?` | `EdgeInsets.all(16)` | Padding around content |
| `expanded` | `bool` | `false` | If true, fills remaining space in a Column |

### PageScaffoldScope

An `InheritedWidget` provided by `MainAreaTemplate` that exposes configuration to descendant widgets. `MainAreaSection` reads this automatically to adjust its appearance when `showCard` changes.

```dart
final scope = PageScaffoldScope.maybeOf(context);
if (scope != null && !scope.showCard) {
  // card-free mode — sections use surface color with shadow
}
```

## Theme Integration

All colors are pulled from `Theme.of(context).colorScheme`:

| Widget element | Color token |
|---|---|
| Page background | `scaffoldBackgroundColor` |
| Content card | `surface` |
| Section background | `surfaceContainerHighest` (or `surface` when `showCard: false`) |
| Accent bar | `primary` |
| Title text | `onSurface` |
| Description text | `onSurfaceVariant` |
| Section header text | `onSurfaceVariant` |
| Card shadow | `shadow` (6% opacity) |
| Selected tab pill | `primary` (8% alpha bg, solid text) |
| Unselected tab text | `onSurfaceVariant` |
| Bar separator | `outlineVariant` |
| Breadcrumb pill background | `scaffoldBackgroundColor` |
| Breadcrumb pill border | `outline` |
| Breadcrumb clickable text | `primary` |
| Breadcrumb current page | `onSurface` (bold) |

Works out of the box with light, dark, or any custom `ThemeData`.

## Example

A playground app is included in `example/`. Run it with:

```bash
cd example
flutter run -d chrome
```

The playground demonstrates three page layouts (table, settings, dashboard) with toggles for title, tabs, keep-alive, animation, card mode, nested navigator, and a theme switcher for light, dark, and sunshine themes. Enable the Navigator toggle and click "Detail Demo" to explore multi-level nested navigation with breadcrumb.

## License

MIT
