// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: MIT

import 'package:khulla/features/users/domain/models/staff_member.dart';
import 'package:khulla/features/users/domain/user_status.dart';
import 'package:khulla/features/users/presentation/user_labels.dart';
import 'package:khulla/l10n/l10n.dart';
import 'package:khulla_ui/khulla_ui.dart';

/// The staff register's columns: name, email, role, standing, and the
/// edit/reset/enable menu.
///
/// Dumb by design — every row action calls back out so the page owns the
/// dialogs, the self-disable and last-administrator guards, and their
/// toasts.
List<AppTableColumn<StaffMember>> staffTableColumns(
  BuildContext context, {
  required void Function(StaffMember staff) onEdit,
  required void Function(StaffMember staff) onResetPassword,
  required void Function(StaffMember staff) onToggleEnabled,
}) {
  final l10n = context.l10n;
  final spacing = context.appSpacing;
  final colors = context.appColors;

  return [
    AppTableColumn<StaffMember>(
      id: 'name',
      label: l10n.usersColumnName,
      flex: 3,
      sortable: true,
      cellBuilder: (context, staff) => Row(
        children: [
          AppAvatar(initials: staff.initials, size: 24),
          SizedBox(width: spacing.xs),
          Flexible(
            child: Text(
              staff.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.textTheme.bodyMedium?.copyWith(
                color: colors.textHigh,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    ),
    AppTableColumn<StaffMember>(
      id: 'barcode',
      label: l10n.fieldBarcode,
      flex: 2,
      sortable: true,
      showFrom: FormFactor.medium,
      cellBuilder: (context, staff) => Text(
        staff.barcode ?? l10n.commonNotSet,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: context.textTheme.bodySmall?.copyWith(
          color: colors.textMuted,
        ),
      ),
    ),
    AppTableColumn<StaffMember>(
      id: 'email',
      label: l10n.usersColumnEmail,
      flex: 3,
      sortable: true,
      showFrom: FormFactor.medium,
      cellBuilder: (context, staff) => Text(
        staff.email,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: context.textTheme.bodySmall?.copyWith(
          color: colors.textMuted,
        ),
      ),
    ),
    AppTableColumn<StaffMember>(
      id: 'role',
      label: l10n.usersColumnRole,
      flex: 2,
      sortable: true,
      showFrom: FormFactor.medium,
      cellBuilder: (context, staff) => Row(
        children: [
          AppIcon(
            staff.role.icon,
            size: spacing.md,
            color: staff.role.tone.foreground(context),
          ),
          SizedBox(width: spacing.xs),
          Flexible(child: Text(staff.role.label(l10n))),
        ],
      ),
    ),
    AppTableColumn<StaffMember>(
      id: 'status',
      label: l10n.commonStatus,
      sortable: true,
      cellBuilder: (context, staff) => AppStatusBadge(
        dense: true,
        label: staff.status.label(l10n),
        tone: staff.status.tone,
      ),
    ),
    AppTableColumn<StaffMember>(
      id: 'actions',
      label: l10n.commonActions,
      alignment: Alignment.centerRight,
      cellBuilder: (context, staff) => AppMenuButton(
        tooltip: l10n.commonMoreActions,
        actions: [
          AppMenuAction(
            label: l10n.usersEditRole,
            icon: AppIcons.idCard,
            onSelected: () => onEdit(staff),
          ),
          AppMenuAction(
            label: l10n.usersResetPassword,
            icon: AppIcons.resetPassword,
            onSelected: () => onResetPassword(staff),
          ),
          AppMenuAction(
            label: staff.status == UserStatus.disabled
                ? l10n.usersEnable
                : l10n.usersDisable,
            icon: AppIcons.blocked,
            isDestructive: staff.status != UserStatus.disabled,
            onSelected: () => onToggleEnabled(staff),
          ),
        ],
      ),
    ),
  ];
}

/// Search, the active/disabled chips, the clear action and the add button.
///
/// The page owns the filter state locally — this only renders the controls.
class StaffListToolbar extends StatelessWidget {
  const StaffListToolbar({
    required this.statuses,
    required this.isFiltered,
    required this.onSearchChanged,
    required this.onStatusToggled,
    required this.onClearFilters,
    required this.onAdd,
    super.key,
  });

  final Set<UserStatus> statuses;
  final bool isFiltered;
  final ValueChanged<String> onSearchChanged;
  final void Function(UserStatus status, bool selected) onStatusToggled;
  final VoidCallback onClearFilters;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return AppToolbar(
      search: AppSearchField(
        hintText: l10n.usersSearchHint,
        clearTooltip: l10n.commonClearSearch,
        dense: true,
        onChanged: onSearchChanged,
      ),
      filters: [
        AppFilterChip(
          label: l10n.usersFilterActive,
          selected: statuses.contains(UserStatus.active),
          tone: AppStatusTone.success,
          onSelected: (selected) =>
              onStatusToggled(UserStatus.active, selected),
        ),
        AppFilterChip(
          label: l10n.usersFilterDisabled,
          selected: statuses.contains(UserStatus.disabled),
          onSelected: (selected) =>
              onStatusToggled(UserStatus.disabled, selected),
        ),
      ],
      actions: [
        if (isFiltered)
          AppTextButton(
            onPressed: onClearFilters,
            child: Text(l10n.commonClearFilters),
          ),
        AppButton(
          icon: AppIcons.add,
          onPressed: onAdd,
          child: Text(l10n.usersAdd),
        ),
      ],
    );
  }
}
