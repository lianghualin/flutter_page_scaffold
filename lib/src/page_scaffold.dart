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

/// Signature for a function that builds a custom tab bar widget.
///
/// Receives the list of [tabs], the current [selectedIndex], and an
/// [onTabSelected] callback to invoke when a tab is tapped.
typedef TabBarBuilder = Widget Function(
  List<PageTab> tabs,
  int selectedIndex,
  ValueChanged<int> onTabSelected,
);

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

  /// Whether to keep all tab children mounted when switching tabs.
  /// When true (default), uses [IndexedStack] to preserve tab state.
  /// When false, only the selected tab's child is mounted.
  final bool maintainState;

  /// Optional builder for a custom tab bar widget.
  /// When provided, replaces the default underline tab bar.
  /// When null (default), uses the built-in tab bar.
  final TabBarBuilder? tabBarBuilder;

  /// Duration of the fade animation when switching tabs.
  /// When null (default), tab switches are instant with no animation.
  /// Set to a duration (e.g. `Duration(milliseconds: 200)`) to enable a fade-in transition.
  final Duration? tabTransitionDuration;

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
    this.maintainState = true,
    this.tabBarBuilder,
    this.tabTransitionDuration,
  }) : assert(
         tabs != null || child != null,
         'Either tabs or child must be provided',
       );

  @override
  State<MainAreaTemplate> createState() => _MainAreaTemplateState();
}

class _MainAreaTemplateState extends State<MainAreaTemplate>
    with TickerProviderStateMixin {
  late int _selectedIndex;
  AnimationController? _animationController;
  Animation<double>? _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialTabIndex;
    _initAnimation();
  }

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

  void _onTabSelected(int index) {
    if (index != _selectedIndex) {
      setState(() => _selectedIndex = index);
      _animationController?.forward(from: 0.0);
      widget.onTabChanged?.call(index);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

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

    if (_fadeAnimation != null && widget.tabs != null) {
      contentChild = FadeTransition(
        opacity: _fadeAnimation!,
        child: contentChild,
      );
    }

    final showTabBarInCard = widget.tabs != null && widget.showTabs;

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
            if (widget.showTitle) const SizedBox(height: 16),
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                    Expanded(
                      child: Padding(
                        padding:
                            widget.cardPadding ?? const EdgeInsets.all(20),
                        child: contentChild,
                      ),
                    ),
                  ],
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
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: colorScheme.outlineVariant,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          for (int i = 0; i < tabs.length; i++)
            _PageTabChip(
              label: tabs[i].label,
              icon: tabs[i].icon,
              selected: selectedIndex == i,
              onTap: () => onTabSelected(i),
              isFirst: i == 0,
            ),
        ],
      ),
    );
  }
}

class _PageTabChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool selected;
  final VoidCallback onTap;
  final bool isFirst;

  const _PageTabChip({
    required this.label,
    this.icon,
    required this.selected,
    required this.onTap,
    this.isFirst = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final cornerRadius =
        isFirst ? const BorderRadius.only(topLeft: Radius.circular(12)) : null;

    return InkWell(
      onTap: onTap,
      borderRadius: cornerRadius,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: selected ? colorScheme.primary : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 18,
                color: selected
                    ? colorScheme.primary
                    : colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                color: selected
                    ? colorScheme.primary
                    : colorScheme.onSurfaceVariant,
              ),
            ),
          ],
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
