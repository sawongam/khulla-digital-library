// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:khulla/core/money/money.dart';
import 'package:khulla/l10n/l10n.dart';
import 'package:khulla/shared/components/section_card.dart';
import 'package:khulla_ui/khulla_ui.dart';

/// Fines raised, collected and waived over the period.
///
/// Three bars on one scale rather than three tiles: what a council asks is
/// what proportion of what was charged actually came in, and that is a
/// comparison, not three separate figures.
class ReportsFinesCard extends StatelessWidget {
  const ReportsFinesCard({required this.totals, super.key});

  final List<({String label, Money amount, AppStatusTone tone, double share})>
  totals;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final spacing = context.appSpacing;

    return SectionCard(
      title: l10n.reportsFinesTitle,
      subtitle: l10n.reportsFinesSubtitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final (index, total) in totals.indexed) ...[
            if (index > 0) SizedBox(height: spacing.md),
            AppProgressBar(
              value: total.share,
              label: total.label,
              valueLabel: total.amount.display(),
              tone: total.tone,
            ),
          ],
        ],
      ),
    );
  }
}
