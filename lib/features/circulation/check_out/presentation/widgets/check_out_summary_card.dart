// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:khulla/core/money/money.dart';
import 'package:khulla/l10n/l10n.dart';
import 'package:khulla/shared/components/section_card.dart';
import 'package:khulla_ui/khulla_ui.dart';

/// What this checkout amounts to, and the button that commits it.
///
/// The summary is the last thing read before a copy leaves the building, so
/// it repeats the numbers that decide whether it should: how many copies,
/// against what limit, and what the member already owes.
class CheckOutSummaryCard extends StatelessWidget {
  const CheckOutSummaryCard({
    required this.copyCount,
    required this.loanPeriodDays,
    required this.dueDate,
    required this.borrowingLimit,
    required this.outstandingFines,
    required this.onConfirm,
    this.currentLoansOut = 0,
    super.key,
  });

  final int copyCount;
  final int loanPeriodDays;

  /// When the copies come back, already formatted.
  final String dueDate;

  final int borrowingLimit;
  final int currentLoansOut;
  final Money outstandingFines;

  /// Commits the checkout. Null while the desk has not chosen a member or
  /// scanned a copy, which is the only gate this screen has.
  final VoidCallback? onConfirm;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final spacing = context.appSpacing;
    final scheme = context.colorScheme;
    final overLimit = currentLoansOut + copyCount > borrowingLimit;

    return SectionCard(
      title: l10n.checkOutSummarySection,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          AppDetailRow(
            label: l10n.checkOutSummaryCopies,
            child: Text(
              '$copyCount',
              style: context.textTheme.bodyMedium?.copyWith(
                color: overLimit ? scheme.error : scheme.onSurface,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          SizedBox(height: spacing.sm),
          AppDetailRow(
            label: l10n.checkOutSummaryLimit,
            child: Text('$borrowingLimit'),
          ),
          SizedBox(height: spacing.sm),
          AppDetailRow(
            label: l10n.checkOutSummaryLoanPeriod,
            child: Text(l10n.checkOutDays('$loanPeriodDays')),
          ),
          SizedBox(height: spacing.sm),
          AppDetailRow(
            label: l10n.checkOutSummaryDueBack,
            child: Text(dueDate),
          ),
          SizedBox(height: spacing.sm),
          AppDetailRow(
            label: l10n.checkOutSummaryOutstanding,
            child: Text(
              outstandingFines.display(),
              style: context.textTheme.bodyMedium?.copyWith(
                color: outstandingFines.isPositive
                    ? scheme.error
                    : scheme.onSurface,
              ),
            ),
          ),
          SizedBox(height: spacing.lg),
          AppButton(
            onPressed: onConfirm,
            child: Text(l10n.checkOutConfirm),
          ),
        ],
      ),
    );
  }
}
