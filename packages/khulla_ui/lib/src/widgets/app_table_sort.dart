// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: MIT

import 'package:khulla_ui/khulla_ui.dart';

/// {@template app_table_sort}
/// Which column a table is sorted by, and in which direction.
///
/// The table does not sort anything - with ten thousand titles the ordering
/// belongs in the query, not in a `List.sort` on the UI thread. This is the
/// value a header reports and the cubit turns into an ORDER BY.
/// {@endtemplate}
@immutable
class AppTableSort {
  /// {@macro app_table_sort}
  const AppTableSort({required this.columnId, this.ascending = true});

  /// The [AppTableColumn.id] the table is ordered by.
  final String columnId;

  /// Whether the order runs A→Z, oldest→newest, smallest→largest.
  final bool ascending;

  /// The sort that results from clicking [columnId]'s heading: the same
  /// column flips direction, a different one starts ascending.
  AppTableSort toggled(String nextColumnId) => nextColumnId == columnId
      ? AppTableSort(columnId: columnId, ascending: !ascending)
      : AppTableSort(columnId: nextColumnId);

  @override
  bool operator ==(Object other) =>
      other is AppTableSort &&
      other.columnId == columnId &&
      other.ascending == ascending;

  @override
  int get hashCode => Object.hash(columnId, ascending);
}
