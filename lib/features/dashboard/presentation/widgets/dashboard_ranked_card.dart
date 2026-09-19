// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:khulla/features/dashboard/presentation/models/dashboard_ranked_entry.dart';
import 'package:khulla/features/dashboard/presentation/widgets/dashboard_section_card.dart';
import 'package:khulla_ui/khulla_ui.dart';

/// A ranked list — most borrowed titles, most active members.
///
/// One widget for both, because the two lists differ only in what they count.
/// The rank is drawn as a numeral rather than implied by position: a card
/// that gets truncated at four rows still says these are the top four.
class DashboardRankedCard extends StatelessWidget {
  const DashboardRankedCard({
    required this.title,
    required this.entries,
    this.subtitle,
    this.trailing,
    super.key,
  });

  /// The card's heading.
  final String title;

  /// The ranked rows, best first.
  final List<DashboardRankedEntry> entries;

  /// Supporting line under the heading.
  final String? subtitle;

  /// The card's single control — a period picker, a *view all* link.
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final spacing = context.appSpacing;
    final colors = context.appColors;

    return DashboardSectionCard(
      framed: false,
      title: title,
      subtitle: subtitle,
      trailing: trailing,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final (index, entry) in entries.indexed) ...[
            if (index > 0) ...[
              SizedBox(height: spacing.sm),
              Divider(height: 1, color: colors.hairline),
              SizedBox(height: spacing.sm),
            ],
            Row(
              children: [
                SizedBox(
                  width: spacing.md,
                  child: Text(
                    '${index + 1}',
                    style: context.textTheme.bodySmall?.copyWith(
                      color: colors.textMuted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                SizedBox(width: spacing.xs),
                AppAvatar(initials: entry.initials, size: 32),
                SizedBox(width: spacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        entry.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.textTheme.bodyMedium?.copyWith(
                          color: colors.textHigh,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        entry.detail,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.textTheme.bodySmall?.copyWith(
                          color: colors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: spacing.xs),
                Text(
                  entry.figure,
                  style: context.textTheme.bodySmall?.copyWith(
                    color: colors.textHigh,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
