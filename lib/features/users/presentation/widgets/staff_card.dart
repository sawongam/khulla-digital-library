// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:khulla/features/users/domain/models/staff_member.dart';
import 'package:khulla/features/users/presentation/user_labels.dart';
import 'package:khulla/l10n/l10n.dart';
import 'package:khulla_ui/khulla_ui.dart';

/// One staff account as a card, for a window too narrow for the table.
class StaffCard extends StatelessWidget {
  const StaffCard({required this.staff, this.onTap, super.key});

  /// The account to draw.
  final StaffMember staff;

  /// Opens the account.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final spacing = context.appSpacing;
    final colors = context.appColors;

    return Padding(
      padding: EdgeInsets.only(bottom: spacing.sm),
      child: AppCard(
        onTap: onTap,
        child: Row(
          children: [
            AppAvatar(initials: staff.initials),
            SizedBox(width: spacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          staff.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: context.textTheme.bodyMedium?.copyWith(
                            color: colors.textHigh,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      AppStatusBadge(
                        dense: true,
                        label: staff.status.label(l10n),
                        tone: staff.status.tone,
                      ),
                    ],
                  ),
                  SizedBox(height: spacing.xxs),
                  Text(
                    staff.email,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.textTheme.bodySmall?.copyWith(
                      color: colors.textMuted,
                    ),
                  ),
                  if (staff.barcode != null) ...[
                    SizedBox(height: spacing.xxs),
                    Text(
                      staff.barcode!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.textTheme.bodySmall?.copyWith(
                        color: colors.textMuted,
                      ),
                    ),
                  ],
                  SizedBox(height: spacing.xxs),
                  Text(
                    staff.role.label(l10n),
                    style: context.textTheme.bodySmall?.copyWith(
                      color: staff.role.tone.foreground(context),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
