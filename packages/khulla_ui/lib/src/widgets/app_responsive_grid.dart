// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: MIT

import 'package:khulla_ui/khulla_ui.dart';

/// {@template app_responsive_grid}
/// An equal-column grid whose column count follows the window class: one on a
/// phone, four on a maximised desktop window by default.
///
/// For a **bounded** set of cards - a dashboard's stat row, a settings page's
/// option cards - where the child count is known and small. A collection that
/// comes back from a query goes in a `SliverGrid` instead, so the viewport
/// only builds the tiles it can see.
/// {@endtemplate}
class AppResponsiveGrid extends StatelessWidget {
  /// {@macro app_responsive_grid}
  const AppResponsiveGrid({
    required this.children,
    this.compactColumns = 1,
    this.mediumColumns = 2,
    this.expandedColumns = 3,
    this.largeColumns = 4,
    this.spacing,
    super.key,
  });

  /// The tiles, in reading order.
  final List<Widget> children;

  /// Columns below 600px.
  final int compactColumns;

  /// Columns from 600px to 839px.
  final int mediumColumns;

  /// Columns from 840px to 1199px.
  final int expandedColumns;

  /// Columns at 1200px and above.
  final int largeColumns;

  /// Gap between tiles, both axes. Defaults to [AppSpacing.md].
  final double? spacing;

  @override
  Widget build(BuildContext context) {
    final gap = spacing ?? context.appSpacing.md;
    final columns = context.formFactor.columns(
      compact: compactColumns,
      medium: mediumColumns,
      expanded: expandedColumns,
      large: largeColumns,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final available = constraints.maxWidth;
        final itemWidth = (available - gap * (columns - 1)) / columns;

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final child in children)
              SizedBox(width: itemWidth.clamp(0, available), child: child),
          ],
        );
      },
    );
  }
}
