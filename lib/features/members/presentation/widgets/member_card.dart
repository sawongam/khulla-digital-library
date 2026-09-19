// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:khulla/features/members/domain/models/member.dart';
import 'package:khulla/features/members/presentation/member_labels.dart';
import 'package:khulla/l10n/l10n.dart';
import 'package:khulla_ui/khulla_ui.dart';

/// One borrower as a card, for the window classes too narrow for the table.
class MemberCard extends StatelessWidget {
  const MemberCard({required this.member, required this.onTap, super.key});

  final Member member;
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
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppAvatar(initials: member.initials),
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
                          member.name,
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
                        label: member.status.label(l10n),
                        tone: member.status.tone,
                      ),
                    ],
                  ),
                  SizedBox(height: spacing.xxs),
                  Text(
                    '${member.barcode} · ${member.memberTypeName}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  SizedBox(height: spacing.xs),
                  Text(
                    member.finesOwed.isZero
                        ? '${l10n.membersColumnLoans} ${member.loansOut}'
                        : '${l10n.membersColumnLoans} ${member.loansOut} · ${member.finesOwed.display()}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.textTheme.bodySmall?.copyWith(
                      color: member.finesOwed.isZero
                          ? scheme.onSurfaceVariant
                          : scheme.error,
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
