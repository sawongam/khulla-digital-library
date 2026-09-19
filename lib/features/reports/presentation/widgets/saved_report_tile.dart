// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:khulla/features/reports/presentation/saved_reports.dart';
import 'package:khulla/l10n/l10n.dart';
import 'package:khulla_ui/khulla_ui.dart';

/// One saved report, as a row with its export action.
///
/// A row rather than a card in a grid. Six identical rectangles said the six
/// reports were six different kinds of thing, and putting a tap on the card
/// while also putting a button inside it left no honest answer to what
/// clicking the middle of it should do. A report is a document you export, so
/// the row names it and the verb sits at the end of the line.
class SavedReportTile extends StatelessWidget {
  const SavedReportTile({
    required this.report,
    required this.onExport,
    super.key,
  });

  final SavedReport report;
  final VoidCallback onExport;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final spacing = context.appSpacing;
    final colors = context.appColors;
    final stacked = context.formFactor.isCompact;

    final identity = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(top: spacing.xxs / 2),
          child: AppIcon(
            report.icon,
            size: spacing.lg - 4,
            color: report.tone.foreground(context),
          ),
        ),
        SizedBox(width: spacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                report.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: context.textTheme.bodyMedium?.copyWith(
                  color: colors.textHigh,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                report.body,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: context.textTheme.bodySmall?.copyWith(
                  color: colors.textMuted,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );

    final export = AppButton(
      variant: AppButtonVariant.outline,
      icon: AppIcons.tableView,
      onPressed: onExport,
      child: Text(l10n.commonExportCsv),
    );

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: spacing.md,
        vertical: spacing.sm,
      ),
      child: stacked
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                identity,
                SizedBox(height: spacing.sm),
                export,
              ],
            )
          : Row(
              children: [
                Expanded(child: identity),
                SizedBox(width: spacing.md),
                export,
              ],
            ),
    );
  }
}
