// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: MIT

import 'package:khulla/features/catalog/title/presentation/cubit/title/title_detail_cubit.dart';
import 'package:khulla/features/circulation/loan/domain/models/loan.dart';
import 'package:khulla/l10n/l10n.dart';
import 'package:khulla/shared/components/section_card.dart';
import 'package:khulla_ui/khulla_ui.dart';

/// Who has borrowed this work, most recent first.
///
/// Closed loans only — open loans show on the copies table via borrower and
/// due date. The parent loads the list from [TitleDetailCubit].
class TitleHistoryCard extends StatelessWidget {
  const TitleHistoryCard({required this.loans, super.key});

  final List<Loan> loans;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = context.colorScheme;

    return SectionCard(
      title: l10n.titleDetailHistoryTitle,
      subtitle: l10n.titleDetailHistorySubtitle,
      child: loans.isEmpty
          ? AppEmptyView(
              variant: AppFeedbackVariant.inline,
              title: l10n.titleDetailHistoryEmptyTitle,
              message: l10n.titleDetailHistoryEmptyBody,
            )
          : AppTable<Loan>(
              items: loans,
              columns: [
                AppTableColumn<Loan>(
                  id: 'member',
                  label: l10n.loansColumnMember,
                  flex: 3,
                  cellBuilder: (context, loan) =>
                      Text(loan.memberName ?? l10n.commonNotSet),
                ),
                AppTableColumn<Loan>(
                  id: 'barcode',
                  label: l10n.loansColumnBarcode,
                  flex: 2,
                  cellBuilder: (context, loan) => Text(
                    loan.barcode ?? l10n.commonNotSet,
                    style: context.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
                AppTableColumn<Loan>(
                  id: 'borrowed',
                  label: l10n.loansColumnIssued,
                  flex: 2,
                  showFrom: FormFactor.large,
                  cellBuilder: (context, loan) => Text(loan.issuedOn),
                ),
                AppTableColumn<Loan>(
                  id: 'status',
                  label: l10n.commonStatus,
                  width: 130,
                  alignment: Alignment.centerRight,
                  cellBuilder: (context, loan) => AppStatusBadge(
                    dense: true,
                    label: loan.isOpen
                        ? l10n.statusOnLoan
                        : l10n.statusReturned,
                    tone: loan.isOpen
                        ? AppStatusTone.brand
                        : (loan.daysLate > 0
                              ? AppStatusTone.warning
                              : AppStatusTone.success),
                  ),
                ),
              ],
            ),
    );
  }
}
