// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: MIT

import 'package:go_router/go_router.dart';
import 'package:khulla/core/router/routes.dart';
import 'package:khulla/features/members/domain/models/member.dart';
import 'package:khulla/features/members/presentation/member_labels.dart';
import 'package:khulla/features/members/presentation/widgets/member_row_menu.dart';
import 'package:khulla/features/users/domain/user_role.dart';
import 'package:khulla/l10n/l10n.dart';
import 'package:khulla/shared/utils/permission_context.dart';
import 'package:khulla_ui/khulla_ui.dart';

/// The register's columns: name, card, category, loans, fines, expiry,
/// standing, and the row menu.
///
/// Sorting stays in the query (`ORDER BY` upstream, never in the cubit), so
/// this only describes columns. Row taps call back out to the page.
List<AppTableColumn<Member>> memberTableColumns(
  BuildContext context, {
  required void Function(Member member) onCheckOut,
  required void Function(Member member) onEdit,
  required void Function(Member member) onRenew,
  required void Function(Member member) onSuspend,
  required void Function(Member member) onUnsuspend,
  required void Function(Member member) onArchive,
}) {
  final l10n = context.l10n;
  final spacing = context.appSpacing;
  final scheme = context.colorScheme;
  final muted = context.textTheme.bodyMedium?.copyWith(
    color: scheme.onSurfaceVariant,
  );
  final canManage = context.canManage(StaffPermission.members);
  final canWorkTheDesk = context.canManage(StaffPermission.circulation);

  return [
    AppTableColumn<Member>(
      id: 'name',
      label: l10n.membersColumnName,
      flex: 3,
      sortable: true,
      cellBuilder: (context, member) => Row(
        children: [
          AppAvatar(initials: member.initials, size: 28),
          SizedBox(width: spacing.xs),
          Flexible(child: Text(member.name)),
        ],
      ),
    ),
    AppTableColumn<Member>(
      id: 'barcode',
      label: l10n.fieldBarcode,
      flex: 2,
      sortable: true,
      showFrom: FormFactor.medium,
      cellBuilder: (context, member) => Text(member.barcode, style: muted),
    ),
    AppTableColumn<Member>(
      id: 'category',
      label: l10n.membersColumnCategory,
      flex: 2,
      showFrom: FormFactor.expanded,
      cellBuilder: (context, member) => Row(
        children: [
          AppIcon(
            member.memberTypeCode.memberTypeIcon,
            size: spacing.md,
            color: scheme.onSurfaceVariant,
          ),
          SizedBox(width: spacing.xs),
          Flexible(child: Text(member.memberTypeName)),
        ],
      ),
    ),
    AppTableColumn<Member>(
      id: 'loans',
      label: l10n.membersColumnLoans,
      sortable: true,
      showFrom: FormFactor.medium,
      cellBuilder: (context, member) => Text(
        '${member.loansOut}',
        style: member.overdueLoans > 0
            ? context.textTheme.bodyMedium?.copyWith(
                color: scheme.error,
                fontWeight: FontWeight.w500,
              )
            : null,
      ),
    ),
    AppTableColumn<Member>(
      id: 'fines',
      label: l10n.membersColumnFines,
      flex: 2,
      sortable: true,
      showFrom: FormFactor.expanded,
      cellBuilder: (context, member) => Text(
        member.finesOwed.isZero
            ? l10n.commonNotSet
            : member.finesOwed.display(),
        style: member.finesOwed.isZero
            ? muted
            : context.textTheme.bodyMedium?.copyWith(
                color: scheme.error,
                fontWeight: FontWeight.w500,
              ),
      ),
    ),
    AppTableColumn<Member>(
      id: 'expires',

      label: l10n.membersColumnExpires,
      sortable: true,
      showFrom: FormFactor.large,
      cellBuilder: (context, member) => Text(
        member.expires.isEmpty ? l10n.commonNotSet : member.expires,
        style: muted,
      ),
    ),
    AppTableColumn<Member>(
      id: 'status',
      label: l10n.commonStatus,
      flex: 2,
      cellBuilder: (context, member) => AppStatusBadge(
        dense: true,
        label: member.status.label(l10n),
        tone: member.status.tone,
      ),
    ),
    // Two permissions meet in this menu. Editing, renewing, suspending and
    // archiving a member are members work; sending the row to the checkout
    // desk is circulation work, and a role can hold either without the
    // other. With neither, the column itself is gone.
    if (canManage || canWorkTheDesk)
      AppTableColumn<Member>(
        id: 'actions',
        label: l10n.commonActions,
        alignment: Alignment.centerRight,
        cellBuilder: (context, member) => AppMenuButton(
          tooltip: l10n.commonMoreActions,
          actions: [
            if (canWorkTheDesk)
              AppMenuAction(
                label: l10n.memberDetailCheckOut,
                icon: AppIcons.scan,
                onSelected: () => onCheckOut(member),
              ),
            if (canManage)
              ...memberManageMenuActions(
                context,
                member,
                onEdit: () => onEdit(member),
                onRenew: () => onRenew(member),
                onSuspend: () => onSuspend(member),
                onUnsuspend: () => onUnsuspend(member),
                onArchive: () => onArchive(member),
              ),
          ],
        ),
      ),
  ];
}

/// Sends a row to the checkout desk for the member's barcode.
void goToMemberCheckOut(BuildContext context, Member member) => context.go(
  Routes.circulationCheckOutForMember(member.barcode),
);
