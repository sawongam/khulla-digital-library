// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:khulla/core/money/money.dart';
import 'package:khulla/l10n/l10n.dart';
import 'package:khulla_ui/khulla_ui.dart';

/// The ledger's headline figures: still owed, taken, written off, and how
/// many members owe anything.
class FineListStats extends StatelessWidget {
  const FineListStats({
    required this.outstandingTotal,
    required this.collectedTotal,
    required this.waivedTotal,
    required this.membersOwing,
    super.key,
  });

  final Money outstandingTotal;
  final Money collectedTotal;
  final Money waivedTotal;
  final int membersOwing;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return AppStatStrip(
      tiles: [
        AppStatTile(
          label: l10n.finesStatOutstanding,
          value: outstandingTotal.display(),
          icon: AppIcons.wallet,
          tone: AppStatusTone.danger,
        ),
        AppStatTile(
          label: l10n.finesStatCollected,
          value: collectedTotal.display(),
          icon: AppIcons.payment,
          tone: AppStatusTone.success,
        ),
        AppStatTile(
          label: l10n.finesStatWaived,
          value: waivedTotal.display(),
          icon: AppIcons.waiveFine,
        ),
        AppStatTile(
          label: l10n.finesStatMembersOwing,
          value: '$membersOwing',
          icon: AppIcons.people,
          tone: AppStatusTone.warning,
        ),
      ],
    );
  }
}
