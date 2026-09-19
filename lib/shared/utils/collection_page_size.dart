// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'dart:math';

import 'package:khulla_ui/khulla_ui.dart';

/// Fewest rows to fetch when the viewport is very short.
const int kCollectionPageSizeMin = 5;

/// Rows to fetch on a compact window where the whole page scrolls together.
const int kCollectionPageSizeCompact = 30;

/// How many table body rows to fetch for [tableBodyHeight].
///
/// [tableBodyHeight] is the height of the scroll viewport in a collection
/// list page — the [Expanded] slot on a desk window, not the full screen.
/// The pinned header row is subtracted before dividing by row height.
///
/// Rounds up so the last page of rows fills the viewport; rounding down leaves
/// a band of empty canvas inside the bordered table.
int computeCollectionPageSize({
  required double tableBodyHeight,
  required AppMetrics metrics,
}) {
  final body = tableBodyHeight - metrics.tableHeaderHeight;
  if (body <= 0) return kCollectionPageSizeMin;
  return max(kCollectionPageSizeMin, (body / metrics.tableRowHeight).ceil());
}
