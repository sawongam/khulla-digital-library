// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:khulla/features/reports/domain/models/reports_summary.dart';

/// The library's figures over a period, for the reports screen and its
/// exports.
///
/// A cross-cutting read, the same reasoning as `DashboardRepository`: every
/// query here crosses loans, fines, members, copies and titles, so it owns
/// no table and gets its own repository rather than living on one feature's.
abstract interface class ReportsRepository {
  /// Everything the board draws for `[start, end)`, with `[previousStart,
  /// previousEnd)` supplying the stat tiles' trend comparison. The monthly
  /// trend charts and the collection mix are not period-scoped — they show a
  /// fixed eight months of history and the catalogue's current composition.
  Future<ReportsSummary> loadSummary({
    required DateTime start,
    required DateTime end,
    required DateTime previousStart,
    required DateTime previousEnd,
  });
}
