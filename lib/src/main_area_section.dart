import 'package:flutter/material.dart';

/// A grouped content section with an optional accent-bar section header.
///
/// Used inside [MainAreaTemplate] to visually group related content
/// (toolbar, data table, settings group, etc).
///
/// Design: rounded container with surfaceContainerHighest background.
/// Section header has a 4px accent bar on the left + uppercase label.
class MainAreaSection extends StatelessWidget {
  /// Uppercase label displayed in the section header.
  /// If null, no header is shown.
  final String? label;

  /// The section content.
  final Widget child;

  /// Padding around the child content. Defaults to EdgeInsets.all(16).
  final EdgeInsetsGeometry? padding;

  /// If true, wraps this section in an Expanded widget.
  /// Useful inside a Column when the section should fill remaining space.
  final bool expanded;

  const MainAreaSection({
    super.key,
    this.label,
    required this.child,
    this.padding,
    this.expanded = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final section = Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: expanded ? MainAxisSize.max : MainAxisSize.min,
        children: [
          if (label != null)
            _SectionHeader(label: label!, accentColor: colorScheme.primary),
          expanded
              ? Expanded(
                  child: Padding(
                    padding: padding ?? const EdgeInsets.all(16),
                    child: child,
                  ),
                )
              : Padding(
                  padding: padding ?? const EdgeInsets.all(16),
                  child: child,
                ),
        ],
      ),
    );

    return expanded ? Expanded(child: section) : section;
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  final Color accentColor;

  const _SectionHeader({
    required this.label,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 18,
            decoration: BoxDecoration(
              color: accentColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
