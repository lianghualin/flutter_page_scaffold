import 'package:flutter/material.dart';

/// A page-level template for the main content area.
///
/// Provides:
/// - Large bold page title with optional icon
/// - Subtle description text
/// - Optional action buttons in title row
/// - A content card with rounded corners and shadow
///
/// The [child] is placed inside a themed card container.
/// Use [MainAreaSection] widgets inside the child for grouped content.
class MainAreaTemplate extends StatelessWidget {
  /// Page title, displayed large and bold.
  final String title;

  /// Optional subtitle/description, displayed smaller and muted below title.
  final String? description;

  /// Optional icon displayed before the title.
  final IconData? icon;

  /// Optional action widgets displayed to the right of the title row.
  final List<Widget>? actions;

  /// The main page content. Typically a Column of [MainAreaSection] widgets.
  final Widget child;

  /// Padding around the entire template. Defaults to EdgeInsets.all(24).
  final EdgeInsetsGeometry? outerPadding;

  /// Padding inside the content card. Defaults to EdgeInsets.all(20).
  final EdgeInsetsGeometry? cardPadding;

  const MainAreaTemplate({
    super.key,
    required this.title,
    this.description,
    this.icon,
    this.actions,
    required this.child,
    this.outerPadding,
    this.cardPadding,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      color: theme.scaffoldBackgroundColor,
      padding: outerPadding ?? const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title area
          _TitleArea(
            title: title,
            description: description,
            icon: icon,
            actions: actions,
          ),
          const SizedBox(height: 20),
          // Content card
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
                padding: cardPadding ?? const EdgeInsets.all(20),
                child: child,
              ),
            ),
          ),
        ],
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
