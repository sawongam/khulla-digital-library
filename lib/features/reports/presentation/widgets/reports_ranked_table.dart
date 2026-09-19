// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:khulla/l10n/l10n.dart';
import 'package:khulla_ui/khulla_ui.dart';

/// One row of a ranked report table.
typedef ReportsRankedRow = ({String name, String detail, int loans});

/// A ranked report table — most borrowed titles, most active members.
///
/// The share bar beside each row is what makes it a report rather than a
/// list: a title with 128 loans means nothing until you can see it is a
/// third again as popular as the next one.
class ReportsRankedTable extends StatelessWidget {
  const ReportsRankedTable({
    required this.rows,
    required this.nameLabel,
    super.key,
  });

  /// The rows, best first.
  final List<ReportsRankedRow> rows;

  /// What the first column counts — a title, a member.
  final String nameLabel;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.appColors;
    final spacing = context.appSpacing;
    final metrics = context.appMetrics;
    final top = rows.isEmpty
        ? 1
        : rows.map((row) => row.loans).reduce((a, b) => a > b ? a : b);

    Widget nameCell(BuildContext context, ReportsRankedRow row) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          row.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: context.textTheme.bodyMedium?.copyWith(
            color: colors.textHigh,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          row.detail,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: context.textTheme.bodySmall?.copyWith(
            color: colors.textMuted,
          ),
        ),
      ],
    );

    Widget shareCell(BuildContext context, ReportsRankedRow row) =>
        AppProgressBar(
          value: top == 0 ? 0 : row.loans / top,
          thickness: 6,
        );

    Widget loansCell(BuildContext context, ReportsRankedRow row) => Text(
      '${row.loans}',
      style: context.textTheme.bodyMedium?.copyWith(
        color: colors.textHigh,
        fontWeight: FontWeight.w600,
      ),
    );

    if (context.formFactor.isCompact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final (index, row) in rows.indexed) ...[
            if (index > 0) SizedBox(height: spacing.sm),
            Padding(
              padding: EdgeInsets.only(bottom: spacing.xs),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      row.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.textTheme.bodyMedium,
                    ),
                  ),
                  Text(
                    '${row.loans}',
                    style: context.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colors.textHigh,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      );
    }

    // AppTableRow fixes every row to metrics.tableRowHeight, whose content
    // slot (~27px) fits one line only. These rows carry two, so the table
    // is built by hand here: same header and column slots, but each row is
    // at least one token tall and grows with its content instead of clipping.
    final columns = [
      AppTableColumn<ReportsRankedRow>(
        id: 'rank',
        label: l10n.reportsColumnRank,
        width: 40,
        cellBuilder: (context, row) => const SizedBox.shrink(),
      ),
      AppTableColumn<ReportsRankedRow>(
        id: 'name',
        label: nameLabel,
        flex: 4,
        cellBuilder: nameCell,
      ),
      AppTableColumn<ReportsRankedRow>(
        id: 'share',
        label: l10n.reportsColumnShare,
        flex: 3,
        showFrom: FormFactor.expanded,
        cellBuilder: shareCell,
      ),
      AppTableColumn<ReportsRankedRow>(
        id: 'loans',
        label: l10n.reportsColumnLoans,
        width: 80,
        alignment: Alignment.centerRight,
        cellBuilder: loansCell,
      ),
    ];
    final visible = AppTableColumn.visible(columns, context.formFactor);

    Widget cellFor(
      AppTableColumn<ReportsRankedRow> column,
      ReportsRankedRow row,
      int index,
    ) {
      // Rank is positional, not data: indexOf would collapse structurally
      // equal rows to the same rank. Every other column already carries its
      // builder, so delegate directly.
      final body = column.id == 'rank'
          ? Text(
              '${index + 1}',
              style: context.textTheme.bodySmall?.copyWith(
                color: colors.textMuted,
                fontWeight: FontWeight.w600,
              ),
            )
          : column.cellBuilder(context, row);
      return column.sized(
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: spacing.md,
            vertical: metrics.tableCellPaddingY,
          ),
          child: Align(alignment: column.alignment, child: body),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        AppTableHeader<ReportsRankedRow>(columns: columns),
        for (final (index, row) in rows.indexed)
          ConstrainedBox(
            constraints: BoxConstraints(minHeight: metrics.tableRowHeight),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: index.isOdd ? colors.tints.rowZebra : null,
              ),
              child: Row(
                children: [
                  for (final column in visible) cellFor(column, row, index),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
