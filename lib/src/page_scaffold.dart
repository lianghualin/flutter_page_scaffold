import 'package:flutter/material.dart';

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

/// A page-level template for the main content area.
///
/// Provides:
/// - Large bold page title with optional icon
/// - Subtle description text
/// - Optional action buttons in title row
/// - A content card with rounded corners and shadow
/// - Optional tabbed navigation via [tabs] parameter
///
/// The [child] is placed inside a themed card container.
/// Use [MainAreaSection] widgets inside the child for grouped content.
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

class _TitleArea extends StatelessWidget {
  final String title;
  final String? description;
  final IconData? icon;
  final List<Widget>? actions;

  const _TitleArea({
    required this.title,
    this.description,
    this.icon,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (icon != null) ...[
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        icon,
                        color: colorScheme.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurface,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
              if (description != null) ...[
                const SizedBox(height: 6),
                Padding(
                  padding: EdgeInsets.only(left: icon != null ? 48 : 0),
                  child: Text(
                    description!,
                    style: TextStyle(
                      fontSize: 14,
                      color: colorScheme.onSurfaceVariant,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        if (actions != null && actions!.isNotEmpty)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (int i = 0; i < actions!.length; i++) ...[
                if (i > 0) const SizedBox(width: 8),
                actions![i],
              ],
            ],
          ),
      ],
    );
  }
}
