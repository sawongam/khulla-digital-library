// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: MIT

import 'package:khulla_ui/khulla_ui.dart';

/// {@template app_sliver_table}
/// A table as slivers: the heading row pinned to the top of the viewport, the
/// records built lazily beneath it.
///
/// This is the form a catalogue uses. It returns a sliver, so it goes in a
/// [CustomScrollView] alongside the page header and toolbar - never wrapped
/// in a box, and never as a `shrinkWrap` list inside another scrollable,
/// which would build all ten thousand rows before the first frame.
///
/// ```dart
/// CustomScrollView(
///   slivers: [
///     SliverToBoxAdapter(child: header),
///     AppSliverTable<Title>(items: state.titles, columns: _columns),
///   ],
/// )
/// ```
/// {@endtemplate}
class AppSliverTable<T> extends StatelessWidget {
  /// {@macro app_sliver_table}
  const AppSliverTable({
    required this.items,
    required this.columns,
    this.onRowTap,
    this.isSelected,
    this.sort,
    this.onSort,
    this.compactBuilder,
    this.headerHeight,
    this.pinHeader = true,
    super.key,
  });

  /// The records currently loaded, in query order.
  final List<T> items;

  /// The columns, in display order.
  final List<AppTableColumn<T>> columns;

  /// Opens a record.
  final void Function(T item)? onRowTap;

  /// Whether a record is the one open in the detail pane beside the table.
  final bool Function(T item)? isSelected;

  /// The current ordering, reflected in the pinned header.
  final AppTableSort? sort;

  /// Called when a sortable heading is clicked.
  final ValueChanged<AppTableSort>? onSort;

  /// Renders one record as a card on a compact window. When set, the header
  /// is dropped there too - a card list has no columns to label.
  final Widget Function(BuildContext context, T item)? compactBuilder;

  /// Height of the heading row. Null resolves to the density's.
  final double? headerHeight;

  /// Whether the heading row stays on screen as the rows scroll under it.
  final bool pinHeader;

  @override
  Widget build(BuildContext context) {
    final compact = compactBuilder;
    final asCards = context.formFactor.isCompact && compact != null;
    final metrics = context.appMetrics;
    final rowHeight = metrics.tableRowHeight;
    final resolvedHeaderHeight = headerHeight ?? metrics.tableHeaderHeight;

    // Cards size to their own content. They carry a title, an author and a
    // badge row whose height depends on the record and on the reader's text
    // scale, so a fixed `itemExtent` is a guaranteed overflow on the one
    // record whose author wraps. `SliverList` is just as lazy.
    if (asCards) {
      return SliverList.builder(
        itemCount: items.length,
        itemBuilder: (context, index) => compact(context, items[index]),
      );
    }

    final list = SliverFixedExtentList.builder(
      itemExtent: rowHeight,
      itemCount: items.length,
      itemBuilder: (context, index) => AppTableRow<T>(
        item: items[index],
        index: index,
        columns: columns,
        selected: isSelected?.call(items[index]) ?? false,
        onTap: onRowTap == null ? null : () => onRowTap!(items[index]),
      ),
    );

    return SliverMainAxisGroup(
      slivers: [
        SliverPersistentHeader(
          pinned: pinHeader,
          delegate: _TableHeaderDelegate<T>(
            height: resolvedHeaderHeight,
            header: AppTableHeader<T>(
              columns: columns,
              sort: sort,
              onSort: onSort,
              height: resolvedHeaderHeight,
            ),
          ),
        ),
        list,
      ],
    );
  }
}

class _TableHeaderDelegate<T> extends SliverPersistentHeaderDelegate {
  const _TableHeaderDelegate({required this.height, required this.header});

  final double height;
  final Widget header;

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) => header;

  @override
  bool shouldRebuild(covariant _TableHeaderDelegate<T> oldDelegate) =>
      oldDelegate.height != height || oldDelegate.header != header;
}
