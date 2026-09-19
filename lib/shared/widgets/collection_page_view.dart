// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:khulla/shared/utils/collection_page_size.dart';
import 'package:khulla_ui/khulla_ui.dart';

/// The page recipe every collection screen in the app follows.
///
/// Three bands: the **filter row**, the **table** in its own bordered
/// wrapper, and the **pagination row**. The page's name and its one action
/// are in the shell's top bar, so nothing repeats them here.
///
/// The table **fills the window down to the last pixel** rather than sizing
/// to its rows. A bordered box that stops two thirds of the way down the
/// screen reads as a card that ran out of content, and it wastes the room a
/// desk machine has most of: vertical. Filling means the wrapper is an
/// [Expanded] with its own scroll view inside, so the filters and the page
/// count stay put while the rows move under them - the same reasoning that
/// put the top bar outside the page.
///
/// Only the table is boxed. Wrapping the filters inside the same border
/// makes the screen read as one heavy object; leaving them outside lets the
/// border say exactly one thing - *here is the data*.
///
/// The wrapper is a [DecoratedBox] around the table's scroll viewport rather
/// than a [DecoratedSliver] around its rows, so the border fills the
/// [Expanded] slot even when the current page has fewer records than fit.
/// The list inside stays lazy - a catalogue of ten thousand titles must not
/// lay out ten thousand rows to draw a border.
///
/// Wire [onPageSizeChanged] to the list cubit's `limitChanged` so the query
/// fetches enough rows to fill the table body. Without it the table still
/// expands, but only the default page size of records is drawn inside it.
class CollectionPageView<T> extends StatefulWidget {
  const CollectionPageView({
    required this.items,
    required this.columns,
    required this.emptyState,
    this.summary,
    this.toolbar,
    this.intro,
    this.onRowTap,
    this.isSelected,
    this.sort,
    this.onSort,
    this.compactBuilder,
    this.footer,
    this.onPageSizeChanged,
    super.key,
  });

  /// A line about what the table holds - *1,284 titles*. It sits at the
  /// trailing end of the filter row, where a count belongs: beside the
  /// controls that change it.
  final String? summary;

  /// Search, filters and view controls, above the table.
  final Widget? toolbar;

  /// Anything above the filters - a row of stat tiles, a banner. Keep it
  /// short: every pixel here is a row the table cannot show.
  final Widget? intro;

  /// The page of records to draw. Paging happens before this.
  final List<T> items;

  /// The columns, in display order.
  final List<AppTableColumn<T>> columns;

  /// Rendered in place of the table when [items] is empty. Pass the *right*
  /// empty state: "nothing catalogued yet" and "nothing matched" are
  /// different screens.
  final Widget emptyState;

  /// Opens a record.
  final void Function(T item)? onRowTap;

  /// Marks a row as the picked one.
  final bool Function(T item)? isSelected;

  /// The active sort, reported to the caller and turned into an `ORDER BY`.
  final AppTableSort? sort;

  /// Called when a column header is picked.
  final ValueChanged<AppTableSort>? onSort;

  /// Renders one record as a card, for windows too narrow for a table.
  final Widget Function(BuildContext context, T item)? compactBuilder;

  /// The pagination footer.
  final Widget? footer;

  /// Called when the viewport fits a different number of rows than before.
  final ValueChanged<int>? onPageSizeChanged;

  @override
  State<CollectionPageView<T>> createState() => _CollectionPageViewState<T>();
}

class _CollectionPageViewState<T> extends State<CollectionPageView<T>> {
  int? _lastReportedPageSize;
  int? _pendingPageSize;
  bool _pageSizeReportScheduled = false;

  void _schedulePageSizeReport(double tableBodyHeight) {
    final callback = widget.onPageSizeChanged;
    if (callback == null) return;

    _pendingPageSize = computeCollectionPageSize(
      tableBodyHeight: tableBodyHeight,
      metrics: context.appMetrics,
    );

    if (_pageSizeReportScheduled) return;
    _pageSizeReportScheduled = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _pageSizeReportScheduled = false;
      if (!mounted) return;
      final size = _pendingPageSize;
      if (size == null || _lastReportedPageSize == size) return;
      _lastReportedPageSize = size;
      callback(size);
    });
  }

  void _scheduleCompactPageSize() {
    final callback = widget.onPageSizeChanged;
    if (callback == null ||
        _lastReportedPageSize == kCollectionPageSizeCompact) {
      return;
    }

    if (_pageSizeReportScheduled) return;
    _pageSizeReportScheduled = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _pageSizeReportScheduled = false;
      if (!mounted || _lastReportedPageSize == kCollectionPageSizeCompact) {
        return;
      }
      _lastReportedPageSize = kCollectionPageSizeCompact;
      callback(kCollectionPageSizeCompact);
    });
  }

  Widget _buildTableSliver() {
    return AppSliverTable<T>(
      items: widget.items,
      columns: widget.columns,
      onRowTap: widget.onRowTap,
      isSelected: widget.isSelected,
      sort: widget.sort,
      onSort: widget.onSort,
      compactBuilder: widget.compactBuilder,
    );
  }

  Widget _buildTableViewport(BoxDecoration tableWrapper) {
    if (widget.items.isEmpty) {
      return DecoratedBox(decoration: tableWrapper, child: widget.emptyState);
    }

    return DecoratedBox(
      decoration: tableWrapper,
      child: CustomScrollView(slivers: [_buildTableSliver()]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final spacing = context.appSpacing;
    final colors = context.appColors;
    final bar = widget.toolbar;
    final end = widget.footer;
    final top = widget.intro;
    final count = widget.summary;

    final tableWrapper = BoxDecoration(
      borderRadius: BorderRadius.circular(context.appRadius.container),
      border: Border.all(color: colors.hairline),
    );

    final head = <Widget>[
      if (top != null) ...[top, SizedBox(height: spacing.lg)],
      if (bar != null || count != null) ...[
        _FilterBand(toolbar: bar, summary: count),
        SizedBox(height: spacing.sm),
      ],
    ];

    // A phone has no room to give the table a viewport of its own: the
    // filters alone would take half of it. There the whole page scrolls, as
    // it did before.
    if (context.formFactor.isCompact) {
      _scheduleCompactPageSize();

      return AppPageBody(
        wide: true,
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                spacing.page,
                spacing.pageVertical,
                spacing.page,
                spacing.xlg,
              ),
              sliver: SliverMainAxisGroup(
                slivers: [
                  for (final widget in head) SliverToBoxAdapter(child: widget),
                  if (widget.items.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: DecoratedBox(
                        decoration: tableWrapper,
                        child: widget.emptyState,
                      ),
                    )
                  else
                    DecoratedSliver(
                      decoration: tableWrapper,
                      sliver: _buildTableSliver(),
                    ),
                  if (end != null)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.only(top: spacing.xxs),
                        child: end,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return AppPageBody(
      wide: true,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          spacing.page,
          spacing.pageVertical,
          spacing.page,
          spacing.md,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ...head,
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  _schedulePageSizeReport(constraints.maxHeight);

                  return _buildTableViewport(tableWrapper);
                },
              ),
            ),
            if (end != null) ...[
              SizedBox(height: spacing.xs),
              end,
            ],
          ],
        ),
      ),
    );
  }
}

/// The filter row, with the collection's count parked on its trailing edge.
class _FilterBand extends StatelessWidget {
  const _FilterBand({required this.toolbar, required this.summary});

  final Widget? toolbar;
  final String? summary;

  @override
  Widget build(BuildContext context) {
    final spacing = context.appSpacing;
    final bar = toolbar;
    final count = summary;

    if (count == null) return bar ?? const SizedBox.shrink();

    final label = Text(
      count,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: context.appTextStyles.body.copyWith(
        color: context.appColors.mutedForeground,
      ),
    );

    if (bar == null) {
      return Align(alignment: AlignmentDirectional.centerStart, child: label);
    }

    // On a phone the count goes under the filters rather than beside them.
    // Parked on the trailing edge it takes a third of the row from a search
    // field and a chip set that already have none to spare.
    if (context.formFactor.isCompact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          bar,
          SizedBox(height: spacing.xs),
          label,
        ],
      );
    }

    return Row(
      children: [
        Expanded(child: bar),
        SizedBox(width: spacing.md),
        label,
      ],
    );
  }
}
