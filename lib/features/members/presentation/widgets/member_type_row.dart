// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:khulla/features/members/domain/models/member_type.dart';
import 'package:khulla/features/members/presentation/member_labels.dart';
import 'package:khulla/l10n/l10n.dart';
import 'package:khulla_ui/khulla_ui.dart';

/// One category row in the category list: the icon, name, system/archived
/// badges, the loan-rule overrides it carries, and its edit/archive or
/// restore actions.
///
/// Dumb by design — taps call back out so the dialog owns the cubit writes
/// and their toasts.
class MemberTypeRow extends StatelessWidget {
  const MemberTypeRow({
    required this.type,
    required this.canArchive,
    required this.onEdit,
    required this.onArchive,
    required this.onRestore,
    super.key,
  });

  final MemberType type;
  final bool canArchive;
  final VoidCallback onEdit;
  final VoidCallback onArchive;
  final VoidCallback onRestore;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = context.colorScheme;
    final spacing = context.appSpacing;
    final muted = context.textTheme.bodySmall?.copyWith(
      color: scheme.onSurfaceVariant,
    );

    return AppCard(
      child: Row(
        children: [
          AppIcon(
            type.code.memberTypeIcon,
            size: spacing.md,
            color: scheme.onSurfaceVariant,
          ),
          SizedBox(width: spacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        type.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    if (type.isSystem) ...[
                      SizedBox(width: spacing.xs),
                      AppStatusBadge(
                        dense: true,
                        label: l10n.memberTypeSystemBadge,
                      ),
                    ],
                    if (type.isArchived) ...[
                      SizedBox(width: spacing.xs),
                      AppStatusBadge(
                        dense: true,
                        label: l10n.memberTypeArchivedBadge,
                        tone: AppStatusTone.warning,
                      ),
                    ],
                  ],
                ),
                Text(_overridesSummary(l10n), style: muted),
              ],
            ),
          ),
          if (type.isArchived)
            AppTextButton(
              onPressed: onRestore,
              child: Text(l10n.memberTypeRestoreAction),
            )
          else ...[
            AppIconButton(
              icon: AppIcons.edit,
              tooltip: l10n.commonEdit,
              size: AppIconButtonSize.small,
              onPressed: onEdit,
            ),
            AppIconButton(
              icon: AppIcons.delete,
              tooltip: l10n.commonArchive,
              size: AppIconButtonSize.small,
              tone: AppStatusTone.danger,
              onPressed: canArchive ? onArchive : null,
            ),
          ],
        ],
      ),
    );
  }

  String _overridesSummary(AppLocalizations l10n) {
    final parts = <String>[
      if (type.loanPeriodDays != null) l10n.fieldLoanPeriodDays,
      if (type.borrowingLimit != null) l10n.fieldBorrowingLimit,
      if (type.finePerDay != null) l10n.fieldFinePerDay,
      if (type.membershipDurationMonths != null)
        l10n.fieldMembershipDurationMonths,
    ];
    return parts.isEmpty
        ? l10n.memberFormMembershipDescription
        : parts.join(' · ');
  }
}
