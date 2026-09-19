// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: MIT

import 'package:khulla_ui/khulla_ui.dart';

/// {@template app_toolbar}
/// The row above a collection: a search field that takes the room, filters
/// beside it, and actions on the trailing edge.
///
/// It wraps rather than overflowing. On a phone the search field takes the
/// full width and the filter and action rows fall below it, which is the only
/// arrangement that keeps a four-control toolbar usable at 360px.
/// {@endtemplate}
class AppToolbar extends StatelessWidget {
  /// {@macro app_toolbar}
  const AppToolbar({
    this.search,
    this.filters = const [],
    this.actions = const [],
    this.searchWidth = 360,
    super.key,
  });

  /// The search field, given the flexible width.
  final Widget? search;

  /// Filter controls - chips, a segmented control, a dropdown.
  final List<Widget> filters;

  /// Actions on the trailing edge, primary last.
  final List<Widget> actions;

  /// Preferred search width on a wide toolbar. It still shrinks to fit.
  final double searchWidth;

  @override
  Widget build(BuildContext context) {
    final spacing = context.appSpacing;
    final searchField = search;

    return LayoutBuilder(
      builder: (context, constraints) {
        final stacked = constraints.maxWidth < searchWidth + 240;

        final filterRow = Wrap(
          spacing: spacing.xs,
          runSpacing: spacing.xs,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: filters,
        );
        final actionRow = Wrap(
          spacing: spacing.xs,
          runSpacing: spacing.xs,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: actions,
        );

        if (stacked) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (searchField != null) ...[
                searchField,
                SizedBox(height: spacing.sm),
              ],
              if (filters.isNotEmpty) ...[
                filterRow,
                SizedBox(height: spacing.sm),
              ],
              if (actions.isNotEmpty)
                Align(alignment: Alignment.centerLeft, child: actionRow),
            ],
          );
        }

        return Row(
          children: [
            if (searchField != null) ...[
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: searchWidth),
                child: searchField,
              ),
              SizedBox(width: spacing.sm),
            ],
            Expanded(child: filterRow),
            if (actions.isNotEmpty) ...[SizedBox(width: spacing.sm), actionRow],
          ],
        );
      },
    );
  }
}
