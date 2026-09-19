// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:khulla/features/dashboard/domain/models/dashboard_summary.dart';

/// The board's figures, aggregated over the catalogue's tables.
///
/// A cross-cutting read: the dashboard owns no table of its own, only
/// queries that cross loans, fines, reservations, copies, titles and
/// members. That is why it gets its own repository rather than living on
/// `CirculationRepository` — the same reasoning `CirculationRepositoryImpl`
/// already applies within circulation, one level up.
abstract interface class DashboardRepository {
  /// Everything the board draws for `[start, end)`, with `[previousStart,
  /// previousEnd)` supplying the comparison a stat tile's trend needs.
  Future<DashboardSummary> loadSummary({
    required DateTime start,
    required DateTime end,
    required DateTime previousStart,
    required DateTime previousEnd,
  });
}
