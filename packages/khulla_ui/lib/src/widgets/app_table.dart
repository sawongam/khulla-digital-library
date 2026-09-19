// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: MIT

import 'package:khulla_ui/khulla_ui.dart';

/// {@template app_table}
/// A bounded table: a header and every row laid out in a [Column].
///
/// **For short, known-length collections only** - a title's copies, a
/// member's open loans, the last ten accessions. It builds every row up
/// front, so a catalogue query goes in [AppSliverTable] instead, which builds
/// only the rows the viewport can see.
///
/// Below [FormFactor.medium] the table drops to [compactBuilder] when one is
/// given, because five columns at 360px is four columns of ellipses. Without
/// one it keeps the columns whose [AppTableColumn.showFrom] allows it.
/// {@endtemplate}
class AppTable<T> extends StatelessWidget {
  /// {@macro app_table}
  const AppTable({
    required this.items,
    required this.columns,
    this.onRowTap,
    this.isSelected,
    this.sort,
    this.onSort,
    this.compactBuilder,
    this.headerHeight,
    this.showHeader = true,
    super.key,
  });

  /// The records, in the order they should appear. Sorting happens in the
  /// query that produced them, not here.
  final List<T> items;

  /// The columns, in display order.
  final List<AppTableColumn<T>> columns;

  /// Opens a record.
  final void Function(T item)? onRowTap;

  /// Whether a record is the one currently open in a detail pane.
  final bool Function(T item)? isSelected;

  /// The current ordering, reflected in the header.
  final AppTableSort? sort;

  /// Called when a sortable heading is clicked.
  final ValueChanged<AppTableSort>? onSort;

  /// Renders one record as a card on a compact window, in place of a row.
  final Widget Function(BuildContext context, T item)? compactBuilder;

  /// Height of the heading row. Null resolves to the density's header height.
  final double? headerHeight;

  /// Whether to render the heading row at all. Turn it off for a two-column
  /// summary table inside a card, where the headings say nothing.
  final bool showHeader;

  @override
  Widget build(BuildContext context) {
    final spacing = context.appSpacing;
    final compact = compactBuilder;

    if (context.formFactor.isCompact && compact != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final (index, item) in items.indexed) ...[
            if (index > 0) SizedBox(height: spacing.sm),
            compact(context, item),
          ],
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showHeader)
          AppTableHeader<T>(
            columns: columns,
            sort: sort,
            onSort: onSort,
            height: headerHeight,
          ),
        for (final (index, item) in items.indexed)
          AppTableRow<T>(
            item: item,
            index: index,
            columns: columns,
            selected: isSelected?.call(item) ?? false,
            onTap: onRowTap == null ? null : () => onRowTap!(item),
          ),
      ],
    );
  }
}
