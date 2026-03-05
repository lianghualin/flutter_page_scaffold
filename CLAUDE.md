# CLAUDE.md

## Project Overview

`flutter_page_scaffold` is a standalone Flutter widget package that provides reusable main content area layouts. It is designed to be consumed by `lnm_frontend` (and potentially other projects) as a path dependency.

## Build Commands

```bash
flutter pub get              # Install dependencies
flutter test                 # Run all tests (7 tests)
flutter analyze              # Lint analysis

# Example playground
cd example && flutter run -d chrome
```

## Architecture

```
lib/
├── flutter_page_scaffold.dart          # Barrel file (exports everything)
└── src/
    ├── flutter_page_scaffold.dart      # MainAreaTemplate widget
    └── main_area_section.dart       # MainAreaSection widget
test/
├── page_scaffold_test.dart     # 4 widget tests
└── main_area_section_test.dart      # 3 widget tests
example/
└── lib/main.dart                    # Playground app (table, settings, dashboard demos)
```

## Key Design Decisions

- **Zero external dependencies** -- only Flutter SDK. Keeps the package lightweight.
- **Theme-aware only** -- all colors come from `Theme.of(context).colorScheme`. No hardcoded colors in widget code.
- **Two widgets only** -- `MainAreaTemplate` (page wrapper) and `MainAreaSection` (grouped card). Intentionally minimal API.
- **`expanded` parameter** -- `MainAreaSection(expanded: true)` wraps itself in `Expanded` for filling remaining Column space (common for data tables).

## Color Token Mapping

| Element | Token |
|---|---|
| Page background | `scaffoldBackgroundColor` |
| Content card bg | `colorScheme.surface` |
| Section card bg | `colorScheme.surfaceContainerHighest` |
| Accent bar | `colorScheme.primary` |
| Title | `colorScheme.onSurface` |
| Description / section label | `colorScheme.onSurfaceVariant` |
| Shadow | `colorScheme.shadow` at 6% alpha |

## Conventions

- Classes: `PascalCase`
- Files: `snake_case`
- Private widgets: `_Prefixed` (e.g., `_TitleArea`, `_SectionHeader`)
- No `library` directive in barrel file
- Use `withValues(alpha:)` instead of deprecated `withOpacity()`
