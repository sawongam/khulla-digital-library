// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:go_router/go_router.dart';
import 'package:khulla/core/router/routes.dart';
import 'package:khulla/features/circulation/loan/domain/models/loan.dart';
import 'package:khulla/features/circulation/shared/presentation/circulation_labels.dart';
import 'package:khulla/features/users/domain/user_role.dart';
import 'package:khulla/l10n/l10n.dart';
import 'package:khulla/shared/utils/not_wired_action.dart';
import 'package:khulla/shared/utils/permission_context.dart';
import 'package:khulla_ui/khulla_ui.dart';

/// The loans table: title, member, barcode, issued, due, accrued fine,
/// standing, and the desk menu.
///
/// Opening the borrower's record is a members-permission read; returning,
/// renewing and writing a copy off are the desk's work. A role holding
/// neither gets the list without the column. Renew taps call back out so
/// the page owns the confirm and its toast.
List<AppTableColumn<Loan>> loanListColumns(
  BuildContext context, {
  required void Function(Loan loan) onRenew,
  void Function(Loan loan)? onReturn,
}) {
  final l10n = context.l10n;
  final scheme = context.colorScheme;
  final muted = context.textTheme.bodyMedium?.copyWith(
    color: scheme.onSurfaceVariant,
  );
  final canWorkTheDesk = context.canManage(StaffPermission.circulation);
  final canSeeMembers = context.canView(StaffPermission.members);

  return [
    AppTableColumn<Loan>(
      id: 'title',
      label: l10n.loansColumnTitle,
      flex: 4,
      sortable: true,
      cellBuilder: (context, loan) => Text(loan.titleName ?? l10n.commonNotSet),
    ),
    AppTableColumn<Loan>(
      id: 'member',
      label: l10n.loansColumnMember,
      flex: 3,
      sortable: true,
      showFrom: FormFactor.medium,
      cellBuilder: (context, loan) =>
          Text(loan.memberName ?? l10n.commonNotSet),
    ),
    AppTableColumn<Loan>(
      id: 'barcode',
      label: l10n.loansColumnBarcode,
      flex: 2,
      showFrom: FormFactor.medium,
      cellBuilder: (context, loan) =>
          Text(loan.barcode ?? l10n.commonNotSet, style: muted),
    ),
    AppTableColumn<Loan>(
      id: 'issued',
      label: l10n.loansColumnIssued,
      flex: 2,
      sortable: true,
      showFrom: FormFactor.large,
      cellBuilder: (context, loan) => Text(loan.issuedOn, style: muted),
    ),
    AppTableColumn<Loan>(
      id: 'due',
      label: l10n.loansColumnDue,
      flex: 2,
      sortable: true,
      showFrom: FormFactor.expanded,
      cellBuilder: (context, loan) => Text(loan.dueOn),
    ),
    AppTableColumn<Loan>(
      id: 'fine',
      label: l10n.loansColumnFine,
      flex: 2,
      sortable: true,
      alignment: Alignment.centerRight,
      showFrom: FormFactor.expanded,
      cellBuilder: (context, loan) => Text(
        loan.accruedFine.isZero
            ? l10n.commonNotSet
            : loan.accruedFine.display(),
        style: loan.accruedFine.isZero
            ? muted
            : context.textTheme.bodyMedium?.copyWith(
                color: scheme.error,
                fontWeight: FontWeight.w500,
              ),
      ),
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
    if (canWorkTheDesk || canSeeMembers)
      AppTableColumn<Loan>(
        id: 'actions',
        label: l10n.commonActions,
        alignment: Alignment.centerRight,
        cellBuilder: (context, loan) => AppMenuButton(
          tooltip: l10n.commonMoreActions,
          actions: [
            if (canWorkTheDesk) ...[
              AppMenuAction(
                label: l10n.loansReturn,
                icon: AppIcons.checkIn,
                onSelected: () => onReturn != null
                    ? onReturn(loan)
                    : context.go(Routes.circulationReturn),
              ),
              AppMenuAction(
                label: l10n.loansRenew,
                icon: AppIcons.refresh,
                onSelected: () => onRenew(loan),
              ),
            ],
            if (canSeeMembers)
              AppMenuAction(
                label: l10n.loansViewMember,
                icon: AppIcons.person,
                onSelected: () => context.go(Routes.member(loan.memberId)),
              ),
            if (canWorkTheDesk)
              AppMenuAction(
                label: l10n.loansMarkLost,
                icon: AppIcons.help,
                isDestructive: true,
                onSelected: () => showNotWiredToast(context),
              ),
          ],
        ),
      ),
  ];
}

/// The compact loan card for narrow windows: title and standing up top,
/// member and due-with-fine below, with barcode so the desk can identify the
/// physical copy without opening the row menu.
class LoanCard extends StatelessWidget {
  const LoanCard({
    required this.loan,
    required this.onTap,
    this.onReturn,
    super.key,
  });

  final Loan loan;
  final VoidCallback onTap;
  final VoidCallback? onReturn;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final spacing = context.appSpacing;
    final scheme = context.colorScheme;

    return Padding(
      padding: EdgeInsets.only(bottom: spacing.sm),
      child: AppCard(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    loan.titleName ?? l10n.commonNotSet,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: scheme.onSurface,
                    ),
                  ),
                ),
                AppStatusBadge(
                  dense: true,
                  label: loan.status.label(l10n),
                  tone: loan.status.tone,
                ),
              ],
            ),
            SizedBox(height: spacing.xxs),
            Text(
              loan.memberName ?? l10n.commonNotSet,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            SizedBox(height: spacing.xs),
            Row(
              children: [
                AppIcon(
                  AppIcons.barcode,
                  size: context.appMetrics.iconDense,
                  color: scheme.onSurfaceVariant,
                ),
                SizedBox(width: spacing.xxs),
                Expanded(
                  child: Text(
                    loan.barcode ?? l10n.commonNotSet,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: spacing.xs),
            Row(
              children: [
                Expanded(
                  child: Text(
                    loan.accruedFine.isZero
                        ? '${l10n.loansColumnDue} ${loan.dueOn}'
                        : '${l10n.loansColumnDue} ${loan.dueOn} · ${loan.accruedFine.display()}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.textTheme.bodySmall?.copyWith(
                      color: loan.accruedFine.isZero
                          ? scheme.onSurfaceVariant
                          : scheme.error,
                    ),
                  ),
                ),
                if (onReturn != null) ...[
                  SizedBox(width: spacing.xs),
                  AppTextButton(
                    onPressed: onReturn,
                    child: Text(l10n.loansReturn),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
