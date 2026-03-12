import 'package:flutter/material.dart';

/// Inherited widget that exposes [MainAreaTemplate] configuration to descendants.
///
/// Used by [MainAreaSection] to automatically adjust its appearance
/// based on whether the parent template has card mode enabled.
class PageScaffoldScope extends InheritedWidget {
  /// Whether the parent [MainAreaTemplate] wraps content in a card container.
  final bool showCard;

  const PageScaffoldScope({
    super.key,
    required this.showCard,
    required super.child,
  });

  /// Returns the nearest [PageScaffoldScope] ancestor, or null.
  static PageScaffoldScope? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<PageScaffoldScope>();
  }

  @override
  bool updateShouldNotify(PageScaffoldScope oldWidget) {
    return showCard != oldWidget.showCard;
  }
}

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
/// When [tabs] is provided, the title and tabs merge into a unified bar
/// with pill-style tab indicators. The [description] is shown as a tooltip.
///
/// When [tabs] is null, the title area renders in classic mode with
/// visible description text below the title.
class MainAreaTemplate extends StatefulWidget {
  /// Page title, displayed large and bold.
  final String title;

  /// Optional subtitle/description.
  /// When [tabs] is provided, shown as tooltip on hover.
  /// When [tabs] is null, shown as visible text below the title.
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
  /// When provided, renders a unified title+tab bar with pill-style tabs.
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
  /// When provided, replaces the default pill tab bar.
  /// When null (default), uses the built-in pill tabs.
  final TabBarBuilder? tabBarBuilder;

  /// Duration of the fade animation when switching tabs.
  /// When null (default), tab switches are instant with no animation.
  /// Set to a duration (e.g. `Duration(milliseconds: 200)`) to enable a fade-in transition.
  final Duration? tabTransitionDuration;

  /// Whether to wrap content in a card container with rounded corners and shadow.
  /// Defaults to true. Set to false for dashboard-style layouts where content
  /// cards should float directly on the page background.
  final bool showCard;

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
    this.showCard = true,
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

    final hasTabs = widget.tabs != null;
    final showBar = hasTabs
        ? (widget.showTitle || widget.showTabs)
        : widget.showTitle;

    return PageScaffoldScope(
      showCard: widget.showCard,
      child: Material(
        color: theme.scaffoldBackgroundColor,
        child: Padding(
          padding: widget.outerPadding ?? const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (showBar && hasTabs)
                _UnifiedBar(
                  title: widget.title,
                  description: widget.description,
                  icon: widget.icon,
                  actions: widget.actions,
                  tabs: widget.tabs!,
                  selectedIndex: _selectedIndex,
                  onTabSelected: _onTabSelected,
                  showTitle: widget.showTitle,
                  showTabs: widget.showTabs,
                  tabBarBuilder: widget.tabBarBuilder,
                ),
              if (showBar && !hasTabs)
                _TitleArea(
                  title: widget.title,
                  description: widget.description,
                  icon: widget.icon,
                  actions: widget.actions,
                ),
              if (showBar) const SizedBox(height: 16),
              Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  decoration: BoxDecoration(
                    color: widget.showCard
                        ? colorScheme.surface
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(
                        widget.showCard ? 12 : 0),
                    boxShadow: [
                      BoxShadow(
                        color: widget.showCard
                            ? colorScheme.shadow.withValues(alpha: 0.06)
                            : Colors.transparent,
                        offset: const Offset(0, 2),
                        blurRadius: widget.showCard ? 12 : 0,
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  clipBehavior:
                      widget.showCard ? Clip.antiAlias : Clip.none,
                  child: Padding(
                    padding: widget.cardPadding ??
                        const EdgeInsets.all(20),
                    child: contentChild,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UnifiedBar extends StatelessWidget {
  final String title;
  final String? description;
  final IconData? icon;
  final List<Widget>? actions;
  final List<PageTab> tabs;
  final int selectedIndex;
  final ValueChanged<int> onTabSelected;
  final bool showTitle;
  final bool showTabs;
  final TabBarBuilder? tabBarBuilder;

  const _UnifiedBar({
    required this.title,
    this.description,
    this.icon,
    this.actions,
    required this.tabs,
    required this.selectedIndex,
    required this.onTabSelected,
    required this.showTitle,
    required this.showTabs,
    this.tabBarBuilder,
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
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          if (showTitle) ...[
            if (icon != null) ...[
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(
                  icon,
                  color: colorScheme.primary,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
            ],
            Text(
              title,
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurface,
                letterSpacing: -0.3,
              ),
            ),
            if (description != null) ...[
              const SizedBox(width: 8),
              _TooltipIcon(description: description!),
            ],
          ],
          if (showTitle && showTabs) ...[
            Container(
              width: 1,
              height: 22,
              margin: const EdgeInsets.symmetric(horizontal: 20),
              color: colorScheme.outlineVariant,
            ),
          ],
          if (showTabs)
            tabBarBuilder != null
                ? Flexible(
                    child: tabBarBuilder!(
                      tabs,
                      selectedIndex,
                      onTabSelected,
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (int i = 0; i < tabs.length; i++) ...[
                        if (i > 0) const SizedBox(width: 4),
                        _PillTab(
                          label: tabs[i].label,
                          icon: tabs[i].icon,
                          selected: selectedIndex == i,
                          onTap: () => onTabSelected(i),
                        ),
                      ],
                    ],
                  ),
          const Spacer(),
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
      ),
    );
  }
}

class _PillTab extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool selected;
  final VoidCallback onTap;

  const _PillTab({
    required this.label,
    this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? colorScheme.primary.withValues(alpha: 0.08)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 14,
                color: selected
                    ? colorScheme.primary
                    : colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
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

class _TooltipIcon extends StatelessWidget {
  final String description;

  const _TooltipIcon({required this.description});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Tooltip(
      message: description,
      child: Container(
        width: 14,
        height: 14,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.35),
            width: 1.5,
          ),
        ),
        child: Center(
          child: Text(
            '?',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.35),
              height: 1,
            ),
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
