// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:go_router/go_router.dart';
import 'package:khulla/features/dashboard/presentation/models/dashboard_stat.dart';
import 'package:khulla_ui/khulla_ui.dart';

/// The row of figures at the top of the dashboard, as one instrument panel.
///
/// The four figures share a single bordered surface divided by hairlines
/// rather than sitting in four separate cards: they are one reading of one
/// library taken at one moment, and four floating rectangles say the opposite.
///
/// Four, not six: the top of a dashboard is the one place where every figure
/// has to be readable without a second look, and the fifth tile is always the
/// one nobody reads.
class DashboardStatsStrip extends StatelessWidget {
  const DashboardStatsStrip({required this.stats, super.key});

  /// The figures to show, in reading order.
  final List<DashboardStat> stats;

  @override
  Widget build(BuildContext context) {
    return AppStatStrip(
      tiles: [
        for (final stat in stats)
          AppStatTile(
            label: stat.label,
            value: stat.value,
            caption: stat.caption,
            icon: stat.icon,
            tone: stat.tone,
            trend: stat.trend,
            trendValue: stat.trendValue,
            trendInverted: stat.trendInverted,
            onTap: stat.route == null ? null : () => context.go(stat.route!),
          ),
      ],
    );
  }
}
