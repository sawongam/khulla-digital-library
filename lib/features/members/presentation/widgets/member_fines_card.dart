// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:khulla/features/circulation/fine/domain/models/fine.dart';
import 'package:khulla/features/circulation/fine/presentation/cubit/fine_list_cubit.dart';
import 'package:khulla/features/circulation/shared/domain/fine_status.dart';
import 'package:khulla/features/circulation/shared/presentation/circulation_labels.dart';
import 'package:khulla/features/members/presentation/cubit/member_detail_cubit.dart';
import 'package:khulla/l10n/l10n.dart';
import 'package:khulla/shared/components/section_card.dart';
import 'package:khulla_ui/khulla_ui.dart';

/// What a member owes, and the controls that settle it.
///
/// Outstanding amounts come from [FineListCubit] on the ledger page and from
/// [MemberDetailCubit] here. [onCollect] and [onWaive] are passed down from
/// the page, mirroring the actions on the standalone fines ledger. [onCharge]
/// opens the by-hand fine dialog for a lost/damaged copy or a membership fee.
class MemberFinesCard extends StatelessWidget {
  const MemberFinesCard({
    required this.fines,
    this.onCollect,
    this.onWaive,
    this.onCharge,
    super.key,
  });

  final List<Fine> fines;

  /// Collecting, waiving and charging are all the fines permission at its
  /// `manage` level. All three are null for a role that may see what a member
  /// owes without settling it, and the card then shows the ledger alone.
  final void Function(Fine fine)? onCollect;
  final void Function(Fine fine)? onWaive;
  final VoidCallback? onCharge;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = context.colorScheme;
    final collect = onCollect;
    final waive = onWaive;
    final charge = onCharge;

    return SectionCard(
      title: l10n.memberDetailFinesTitle,
      subtitle: l10n.memberDetailFinesSubtitle,
      trailing: charge == null
          ? null
          : AppTextButton(
              onPressed: charge,
              child: Text(l10n.finesChargeAction),
            ),
      child: fines.isEmpty
          ? AppEmptyView(
              variant: AppFeedbackVariant.inline,
              title: l10n.memberDetailFinesEmptyTitle,
              message: l10n.memberDetailFinesEmptyBody,
            )
          : AppTable<Fine>(
              items: fines,
              columns: [
                AppTableColumn<Fine>(
                  id: 'title',
                  label: l10n.finesColumnTitle,
                  flex: 4,
                  cellBuilder: (context, fine) =>
                      Text(fine.titleName ?? l10n.commonNotSet),
                ),
                AppTableColumn<Fine>(
                  id: 'raised',
                  label: l10n.finesColumnRaised,
                  flex: 2,
                  showFrom: FormFactor.medium,
                  cellBuilder: (context, fine) => Text(
                    fine.raisedOn,
                    style: context.textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
                AppTableColumn<Fine>(
                  id: 'amount',
                  label: l10n.finesColumnAmount,
                  flex: 2,
                  alignment: Alignment.centerRight,
                  cellBuilder: (context, fine) => Text(
                    fine.outstanding.display(),
                    style: context.textTheme.bodyMedium?.copyWith(
                      color: scheme.error,
                      fontWeight: FontWeight.w500,
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
                if (collect != null || waive != null)
                  AppTableColumn<Fine>(
                    id: 'actions',
                    label: l10n.commonActions,
                    alignment: Alignment.centerRight,
                    cellBuilder: (context, fine) => AppMenuButton(
                      tooltip: l10n.commonMoreActions,
                      actions: [
                        if (collect != null)
                          AppMenuAction(
                            label: l10n.finesCollect,
                            icon: AppIcons.payment,
                            enabled: fine.status == FineStatus.unpaid,
                            onSelected: () => collect(fine),
                          ),
                        if (waive != null)
                          AppMenuAction(
                            label: l10n.finesWaive,
                            icon: AppIcons.waiveFine,
                            isDestructive: true,
                            enabled: fine.status == FineStatus.unpaid,
                            onSelected: () => waive(fine),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }
}
