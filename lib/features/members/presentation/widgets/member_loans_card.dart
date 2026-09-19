// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:khulla/core/format/app_date_format.dart';
import 'package:khulla/features/circulation/loan/domain/models/loan.dart';
import 'package:khulla/features/circulation/shared/presentation/circulation_labels.dart';
import 'package:khulla/features/members/presentation/cubit/member_detail_cubit.dart';
import 'package:khulla/l10n/l10n.dart';
import 'package:khulla/shared/components/section_card.dart';
import 'package:khulla_ui/khulla_ui.dart';

/// The copies a member is holding, or everything they have brought back.
///
/// One widget for both because the two tables differ only in which date
/// matters - the due date while a copy is out, the return date once it is
/// back - and duplicating the column list to say that would be worse.
/// [isHistory] switches the date column; the parent passes the slice from
/// [MemberDetailCubit].
class MemberLoansCard extends StatelessWidget {
  const MemberLoansCard({
    required this.title,
    required this.subtitle,
    required this.loans,
    required this.emptyTitle,
    required this.emptyBody,
    this.isHistory = false,
    super.key,
  });

  final String title;
  final String subtitle;
  final List<Loan> loans;
  final String emptyTitle;
  final String emptyBody;
  final bool isHistory;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = context.colorScheme;
    final muted = context.textTheme.bodyMedium?.copyWith(
      color: scheme.onSurfaceVariant,
    );

    return SectionCard(
      title: title,
      subtitle: subtitle,
      child: loans.isEmpty
          ? AppEmptyView(
              variant: AppFeedbackVariant.inline,
              title: emptyTitle,
              message: emptyBody,
            )
          : AppTable<Loan>(
              items: loans,
              columns: [
                AppTableColumn<Loan>(
                  id: 'title',
                  label: l10n.loansColumnTitle,
                  flex: 4,
                  cellBuilder: (context, loan) =>
                      Text(loan.titleName ?? l10n.commonNotSet),
                ),
                AppTableColumn<Loan>(
                  id: 'barcode',
                  label: l10n.loansColumnBarcode,
                  flex: 2,
                  showFrom: FormFactor.large,
                  cellBuilder: (context, loan) =>
                      Text(loan.barcode ?? l10n.commonNotSet, style: muted),
                ),
                AppTableColumn<Loan>(
                  id: 'issued',
                  label: l10n.loansColumnIssued,
                  flex: 2,
                  showFrom: FormFactor.expanded,
                  cellBuilder: (context, loan) =>
                      Text(loan.issuedOn, style: muted),
                ),
                AppTableColumn<Loan>(
                  id: 'due',
                  label: l10n.loansColumnDue,
                  flex: 2,
                  showFrom: FormFactor.medium,
                  cellBuilder: (context, loan) => Text(
                    isHistory
                        ? (loan.returnedAt == null
                              ? loan.dueOn
                              : AppDateFormat.format(loan.returnedAt!))
                        : loan.dueOn,
                  ),
                ),
                AppTableColumn<Loan>(
                  id: 'fine',
                  label: l10n.loansColumnFine,
                  flex: 2,
                  alignment: Alignment.centerRight,
                  showFrom: FormFactor.expanded,
                  cellBuilder: (context, loan) {
                    final fine = loan.accruedFine;
                    return Text(
                      fine.isZero ? l10n.commonNotSet : fine.display(),
                      style: fine.isZero
                          ? muted
                          : context.textTheme.bodyMedium?.copyWith(
                              color: scheme.error,
                            ),
                    );
                  },
                ),
                AppTableColumn<Loan>(
                  id: 'status',
                  label: l10n.commonStatus,
                  flex: 2,
                  cellBuilder: (context, loan) => AppStatusBadge(
                    dense: true,
                    label: loan.status.label(l10n),
                    tone: loan.status.tone,
                  ),
                ),
              ],
            ),
    );
  }
}
