// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:khulla/features/members/domain/models/member.dart';
import 'package:khulla/l10n/l10n.dart';
import 'package:khulla_ui/khulla_ui.dart';

/// The members-permission half of a member row menu, shared by the list and
/// the detail page: edit, renew, suspend/unsuspend, archive, delete; for an archived member just restore and delete.
///
/// Dumb by design - taps call back out so each page owns its cubit writes
/// and toasts. Callers add their own extras around it: the list prepends
/// the circulation check-out action,
List<AppMenuAction> memberManageMenuActions(
  BuildContext context,
  Member member, {
  required VoidCallback onEdit,
  required VoidCallback onRenew,
  required VoidCallback onSuspend,
  required VoidCallback onUnsuspend,
  required VoidCallback onArchive,
  required VoidCallback onRestore,
  required VoidCallback onDelete,
}) {
  final l10n = context.l10n;
  // An archived member can only be brought back or removed for good.
  if (member.isArchived) {
    return [
      AppMenuAction(
        label: l10n.memberRestore,
        icon: AppIcons.restore,
        onSelected: onRestore,
      ),
      AppMenuAction(
        label: l10n.memberDetailDelete,
        icon: AppIcons.delete,
        isDestructive: true,
        onSelected: onDelete,
      ),
    ];
  }
  return [
    AppMenuAction(
      label: l10n.memberDetailEdit,
      icon: AppIcons.edit,
      onSelected: onEdit,
    ),
    AppMenuAction(
      label: l10n.memberDetailRenewMembership,
      icon: AppIcons.renew,
      onSelected: onRenew,
    ),
    if (member.suspendedAt != null)
      AppMenuAction(
        label: l10n.memberDetailUnsuspend,
        icon: AppIcons.restore,
        onSelected: onUnsuspend,
      )
    else
      AppMenuAction(
        label: l10n.memberDetailSuspend,
        icon: AppIcons.blocked,
        isDestructive: true,
        onSelected: onSuspend,
      ),
    AppMenuAction(
      label: l10n.memberDetailArchive,
      icon: AppIcons.delete,
      isDestructive: true,
      onSelected: onArchive,
    ),
    AppMenuAction(
      label: l10n.memberDetailDelete,
      icon: AppIcons.delete,
      isDestructive: true,
      onSelected: onDelete,
    ),
  ];
}
