// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: MIT

import 'package:khulla/features/members/domain/models/member.dart';
import 'package:khulla/features/members/presentation/member_labels.dart';
import 'package:khulla/l10n/l10n.dart';
import 'package:khulla/shared/components/record_header.dart';
import 'package:khulla_ui/khulla_ui.dart';

/// A borrower's identity block at the top of their detail screen.
class MemberDetailHeader extends StatelessWidget {
  const MemberDetailHeader({
    required this.member,
    required this.menuActions,
    this.onCheckOut,
    super.key,
  });

  final Member member;

  /// Sends the member to the checkout desk. Null for a role that may read
  /// the register without working the counter.
  final VoidCallback? onCheckOut;
  final List<AppMenuAction> menuActions;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final spacing = context.appSpacing;

    return RecordHeader(
      title: member.name,
      initials: member.initials,
      facts: [member.barcode, member.memberTypeName],
      badges: [
        AppStatusBadge(
          label: member.status.label(l10n),
          tone: member.status.tone,
        ),
        if (member.finesOwed.isPositive)
          AppStatusBadge(
            label: l10n.memberDetailOwes(member.finesOwed.display()),
            tone: AppStatusTone.danger,
          ),
      ],
      note: member.notes,
      actions: [
        if (menuActions.isNotEmpty) ...[
          AppMenuButton(actions: menuActions, tooltip: l10n.commonMoreActions),
          SizedBox(width: spacing.xs),
        ],
        if (onCheckOut != null)
          AppButton(
            size: AppButtonSize.medium,
            onPressed: onCheckOut,
            child: Text(l10n.circulationCheckOut),
          ),
      ],
    );
  }
}
