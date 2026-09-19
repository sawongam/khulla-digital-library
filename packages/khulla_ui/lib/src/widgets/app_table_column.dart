// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: MIT

import 'package:khulla_ui/khulla_ui.dart';

/// {@template app_table_column}
/// One column of an [AppTable]: its heading, how a cell is built from a row,
/// how much width it gets, and the narrowest window it survives.
///
/// [showFrom] is what makes a desktop table usable on a phone browser tab
/// without a second layout: give the identifying columns
/// [FormFactor.compact] and let the supporting ones appear as the window
/// grows. Below the point where too few remain, hand the table a
/// `compactBuilder` and let each row render as a card instead.
/// {@endtemplate}
class AppTableColumn<T> {
  /// {@macro app_table_column}
  const AppTableColumn({
    required this.id,
    required this.label,
    required this.cellBuilder,
    this.width,
    this.flex = 1,
    this.alignment = Alignment.centerLeft,
    this.sortable = false,
    this.showFrom = FormFactor.compact,
  });

  /// Stable key for this column, used to report sorting back to the caller.
  /// Keep it the column's field name - `title`, `dueDate` - so the cubit can
  /// map it straight onto an ORDER BY without a translation table.
  final String id;

  /// Column heading, already localized.
  final String label;

  /// Builds the cell for one row.
  final Widget Function(BuildContext context, T item) cellBuilder;

  /// Fixed width. Set it for columns whose content does not vary - a status
  /// badge, a row-action button - and leave [flex] to the rest.
  final double? width;

  /// Share of the leftover width, ignored when [width] is set.
  final int flex;

  /// How the cell's content sits in its box. Right-align counts and amounts:
  /// a column of numbers is read by its last digit, not its first.
  final Alignment alignment;

  /// Whether the heading is a sort control.
  final bool sortable;

  /// The narrowest window class this column appears in.
  final FormFactor showFrom;

  /// Whether this column has room at [formFactor].
  bool visibleIn(FormFactor formFactor) => formFactor.isAtLeast(showFrom);

  /// Sizes [child] into its slot in a header or row.
  ///
  /// Returns an [Expanded] for a flexible column, so it must be used as a
  /// direct child of the table's [Row].
  Widget sized(Widget child) {
    final fixed = width;
    if (fixed != null) return SizedBox(width: fixed, child: child);
    return Expanded(flex: flex, child: child);
  }

  /// The subset of [columns] that fits at [formFactor], in order.
  static List<AppTableColumn<T>> visible<T>(
    List<AppTableColumn<T>> columns,
    FormFactor formFactor,
  ) => [
    for (final column in columns)
      if (column.visibleIn(formFactor)) column,
  ];
}
