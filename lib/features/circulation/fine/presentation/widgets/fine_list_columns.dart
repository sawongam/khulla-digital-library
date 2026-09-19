// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:khulla/features/circulation/fine/domain/models/fine.dart';
import 'package:khulla/features/circulation/shared/domain/fine_status.dart';
import 'package:khulla/features/circulation/shared/presentation/circulation_labels.dart';
import 'package:khulla/features/users/domain/user_role.dart';
import 'package:khulla/l10n/l10n.dart';
import 'package:khulla/shared/utils/permission_context.dart';
import 'package:khulla_ui/khulla_ui.dart';

/// The ledger's columns: member, reason, title, raised date, amount,
/// standing, and the settle/view-member menu.
///
/// Reading the ledger and settling what is on it are two levels of the same
/// permission: a desk assistant can tell a member what they owe, and a
/// librarian is the one who takes or waives it. Settle and waive taps call
/// back out so the page owns the confirms and their toasts.
List<AppTableColumn<Fine>> fineListColumns(
  BuildContext context, {
  required void Function(Fine fine) onCollect,
  required void Function(Fine fine) onWaive,
  required void Function(Fine fine) onViewMember,
}) {
  final l10n = context.l10n;
  final spacing = context.appSpacing;
  final scheme = context.colorScheme;
  final muted = context.textTheme.bodyMedium?.copyWith(
    color: scheme.onSurfaceVariant,
  );
  final canSettle = context.canManage(StaffPermission.fines);
  final canSeeMembers = context.canView(StaffPermission.members);

  return [
    AppTableColumn<Fine>(
      id: 'member',
      label: l10n.finesColumnMember,
      flex: 3,
      cellBuilder: (context, fine) =>
          Text(fine.memberName ?? l10n.commonNotSet),
    ),
    AppTableColumn<Fine>(
      id: 'reason',
      label: l10n.finesColumnReason,
      flex: 2,
      showFrom: FormFactor.medium,
      cellBuilder: (context, fine) => Row(
        children: [
          AppIcon(
            fine.reason.icon,
            size: spacing.md,
            color: scheme.onSurfaceVariant,
          ),
          SizedBox(width: spacing.xs),
          Flexible(child: Text(fine.reason.label(l10n))),
        ],
      ),
    ),
    AppTableColumn<Fine>(
      id: 'title',
      label: l10n.finesColumnTitle,
      flex: 3,
      showFrom: FormFactor.large,
      cellBuilder: (context, fine) =>
          Text(fine.titleName ?? l10n.commonNotSet, style: muted),
    ),
    AppTableColumn<Fine>(
      id: 'raised',
      label: l10n.finesColumnRaised,
      flex: 2,
      showFrom: FormFactor.expanded,
      cellBuilder: (context, fine) => Text(fine.raisedOn, style: muted),
    ),
    AppTableColumn<Fine>(
      id: 'amount',
      label: l10n.finesColumnAmount,
      flex: 2,
      alignment: Alignment.centerRight,
      cellBuilder: (context, fine) => Text(
        fine.outstanding.display(),
        style: context.textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w500,
          color: fine.status == FineStatus.unpaid
              ? scheme.error
              : scheme.onSurface,
        ),
      ),
    ),
    AppTableColumn<Fine>(
      id: 'status',
      label: l10n.commonStatus,
      flex: 2,
      cellBuilder: (context, fine) => AppStatusBadge(
        dense: true,
        label: fine.status.label(l10n),
        tone: fine.status.tone,
      ),
    ),
    if (canSettle || canSeeMembers)
      AppTableColumn<Fine>(
        id: 'actions',
        label: l10n.commonActions,
        alignment: Alignment.centerRight,
        cellBuilder: (context, fine) => AppMenuButton(
          tooltip: l10n.commonMoreActions,
          actions: [
            if (canSettle)
              AppMenuAction(
                label: l10n.finesCollect,
                icon: AppIcons.payment,
                enabled: fine.status == FineStatus.unpaid,
                onSelected: () => onCollect(fine),
              ),
            if (canSeeMembers)
              AppMenuAction(
                label: l10n.loansViewMember,
                icon: AppIcons.person,
                onSelected: () => onViewMember(fine),
              ),
            if (canSettle)
              AppMenuAction(
                label: l10n.finesWaive,
                icon: AppIcons.waiveFine,
                isDestructive: true,
                enabled: fine.status == FineStatus.unpaid,
                onSelected: () => onWaive(fine),
              ),
          ],
        ),
      ),
  ];
}

/// The compact fine card for narrow windows: member and amount up top,
/// title and standing below.
class FineCard extends StatelessWidget {
  const FineCard({required this.fine, required this.onTap, super.key});

  final Fine fine;
  final VoidCallback onTap;

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
                    fine.memberName ?? l10n.commonNotSet,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: scheme.onSurface,
                    ),
                  ),
                ),
                Text(
                  fine.outstanding.display(),
                  style: context.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: fine.status == FineStatus.unpaid
                        ? scheme.error
                        : scheme.onSurface,
                  ),
                ),
              ],
            ),
            SizedBox(height: spacing.xxs),
            Text(
              fine.titleName ?? fine.reason.label(l10n),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            SizedBox(height: spacing.xs),
            Row(
              children: [
                AppStatusBadge(
                  dense: true,
                  label: fine.status.label(l10n),
                  tone: fine.status.tone,
                ),
                SizedBox(width: spacing.xs),
                Flexible(
                  child: Text(
                    fine.raisedOn,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
