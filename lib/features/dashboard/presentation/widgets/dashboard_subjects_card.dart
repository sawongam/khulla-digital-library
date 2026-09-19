// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:khulla/features/dashboard/presentation/widgets/dashboard_section_card.dart';
import 'package:khulla/l10n/l10n.dart';
import 'package:khulla_ui/khulla_ui.dart';

/// How the catalogue divides by format - the closest categorical dimension a
/// title carries; there is no separate subject/genre column.
///
/// Bars on a shared scale rather than a second pie: six categories in a pie
/// are six slices nobody can rank, while six bars starting from the same edge
/// are ranked at a glance.
class DashboardSubjectsCard extends StatelessWidget {
  const DashboardSubjectsCard({required this.subjects, super.key});

  final List<({String label, String count, double share})> subjects;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final spacing = context.appSpacing;

    return DashboardSectionCard(
      framed: false,
      title: l10n.dashboardCategoriesTitle,
      subtitle: l10n.dashboardCategoriesSubtitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final (index, subject) in subjects.indexed) ...[
            if (index > 0) SizedBox(height: spacing.sm),
            AppProgressBar(
              value: subject.share,
              label: subject.label,
              valueLabel: subject.count,
              tone: index == 0 ? AppStatusTone.brand : AppStatusTone.info,
            ),
          ],
        ],
      ),
    );
  }
}
