// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:khulla/core/error/app_exception.dart';
import 'package:khulla/core/feedback/app_toast.dart';
import 'package:khulla/core/router/routes.dart';
import 'package:khulla/features/circulation/fine/domain/models/fine.dart';
import 'package:khulla/features/members/presentation/cubit/member_detail_cubit.dart';
import 'package:khulla/features/members/presentation/cubit/member_detail_state.dart';
import 'package:khulla/features/members/presentation/pages/charge_fine_dialog.dart';
import 'package:khulla/features/members/presentation/pages/member_form_dialog.dart';
import 'package:khulla/features/members/presentation/widgets/member_detail_header.dart';
import 'package:khulla/features/members/presentation/widgets/member_details_card.dart';
import 'package:khulla/features/members/presentation/widgets/member_fines_card.dart';
import 'package:khulla/features/members/presentation/widgets/member_loans_card.dart';
import 'package:khulla/features/members/presentation/widgets/member_row_menu.dart';
import 'package:khulla/features/users/domain/user_role.dart';
import 'package:khulla/l10n/l10n.dart';
import 'package:khulla/shared/utils/app_exception_l10n.dart';
import 'package:khulla/shared/utils/permission_context.dart';
import 'package:khulla/shared/widgets/error_retry_view.dart';
import 'package:khulla_ui/khulla_ui.dart';

/// One borrower's record: their standing, what they are holding, what they
/// owe, and everything they have read.
///
/// The four figures at the top are the ones a desk decides on — copies out,
/// how many are late, what is owed, and how much they have borrowed over the
/// life of the card. [MemberDetailCubit] loads the member, open loans, fine
/// rows and loan history. Check-out and edit are live.
class MemberDetailPage extends StatelessWidget {
  const MemberDetailPage({required this.memberId, super.key});

  final String memberId;

  Future<void> _confirmDelete(BuildContext context) async {
    final l10n = context.l10n;
    final confirmed = await AppDialog.confirmDestructive(
      context: context,
      title: l10n.memberDetailDeleteTitle,
      message: l10n.memberDetailDeleteBody,
      confirmLabel: l10n.memberDetailDelete,
      cancelLabel: l10n.commonCancel,
    );
    if (!context.mounted || !confirmed) return;
    try {
      await context.read<MemberDetailCubit>().removeMember(memberId);
      if (!context.mounted) return;
      context.go(Routes.members);
    } on AppException catch (error) {
      if (!context.mounted) return;
      AppToast.error(context, message: error.localizedMessage(l10n));
    }
  }

  Future<void> _edit(BuildContext context) async {
    final saved = await MemberFormDialog.show(context, memberId: memberId);
    if (saved == true && context.mounted) {
      unawaited(context.read<MemberDetailCubit>().loadMember(memberId));
    }
  }

  Future<void> _collectFine(BuildContext context, Fine fine) async {
    final l10n = context.l10n;
    final confirmed = await AppDialog.show<bool>(
      context: context,
      title: l10n.finesCollectTitle,
      message: l10n.finesCollectBody(
        fine.outstanding.display(),
        fine.memberName ?? l10n.commonNotSet,
      ),
      icon: AppIcons.wallet,
      actionsBuilder: (dialogContext) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: double.infinity,
            child: AppButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(l10n.finesCollect),
            ),
          ),
          SizedBox(height: dialogContext.appSpacing.xs),
          AppDialog.secondaryAction(
            context: dialogContext,
            label: l10n.commonCancel,
            onPressed: () => Navigator.of(dialogContext).pop(false),
          ),
        ],
      ),
    );
    if (!context.mounted || confirmed != true) return;
    try {
      await context.read<MemberDetailCubit>().collectFine(memberId, fine.id);
      if (!context.mounted) return;
      AppToast.success(context, message: l10n.finesCollectSuccess);
    } on AppException catch (error) {
      if (!context.mounted) return;
      AppToast.error(context, message: error.localizedMessage(l10n));
    }
  }

  Future<void> _waiveFine(BuildContext context, Fine fine) async {
    final l10n = context.l10n;
    final confirmed = await AppDialog.confirmDestructive(
      context: context,
      title: l10n.finesWaiveTitle,
      message: l10n.finesWaiveBody,
      confirmLabel: l10n.finesWaive,
      cancelLabel: l10n.commonCancel,
    );
    if (!context.mounted || !confirmed) return;
    try {
      await context.read<MemberDetailCubit>().waiveFine(memberId, fine.id);
      if (!context.mounted) return;
      AppToast.success(context, message: l10n.finesWaiveSuccess);
    } on AppException catch (error) {
      if (!context.mounted) return;
      AppToast.error(context, message: error.localizedMessage(l10n));
    }
  }

  Future<void> _chargeFine(BuildContext context) async {
    final l10n = context.l10n;
    final result = await ChargeFineDialog.show(context);
    if (result == null || !context.mounted) return;
    try {
      await context.read<MemberDetailCubit>().chargeFine(
        memberId,
        result.reason,
        result.amount,
        result.note,
      );
      if (!context.mounted) return;
      AppToast.success(context, message: l10n.finesChargeSuccess);
    } on AppException catch (error) {
      if (!context.mounted) return;
      AppToast.error(context, message: error.localizedMessage(l10n));
    }
  }

  Future<void> _unsuspendMembership(BuildContext context) async {
    final l10n = context.l10n;
    try {
      await context.read<MemberDetailCubit>().unsuspendMember(memberId);
      if (!context.mounted) return;
      AppToast.success(context, message: l10n.memberDetailUnsuspendSuccess);
    } on AppException catch (error) {
      if (!context.mounted) return;
      AppToast.error(context, message: error.localizedMessage(l10n));
    }
  }

  Future<void> _archiveMember(BuildContext context) async {
    final l10n = context.l10n;
    final confirmed = await AppDialog.confirmDestructive(
      context: context,
      title: l10n.memberDetailArchiveTitle,
      message: l10n.memberDetailArchiveBody,
      confirmLabel: l10n.memberDetailArchive,
      cancelLabel: l10n.commonCancel,
    );
    if (!context.mounted || !confirmed) return;
    try {
      await context.read<MemberDetailCubit>().archiveMember(memberId);
      if (!context.mounted) return;
      AppToast.success(context, message: l10n.memberDetailArchiveSuccess);
      context.go(Routes.members);
    } on AppException catch (error) {
      if (!context.mounted) return;
      AppToast.error(context, message: error.localizedMessage(l10n));
    }
  }

  Future<void> _renewMembership(BuildContext context) async {
    final l10n = context.l10n;
    try {
      await context.read<MemberDetailCubit>().renewMembership(memberId);
      if (!context.mounted) return;
      AppToast.success(context, message: l10n.memberDetailRenewSuccess);
    } on AppException catch (error) {
      if (!context.mounted) return;
      AppToast.error(context, message: error.localizedMessage(l10n));
    }
  }

  Future<void> _suspendMembership(BuildContext context) async {
    final l10n = context.l10n;
    final confirmed = await AppDialog.confirmDestructive(
      context: context,
      title: l10n.memberDetailSuspend,
      message: l10n.memberDetailSuspendBody,
      confirmLabel: l10n.memberDetailSuspend,
      cancelLabel: l10n.commonCancel,
    );
    if (!context.mounted || !confirmed) return;
    try {
      await context.read<MemberDetailCubit>().suspendMember(memberId);
      if (!context.mounted) return;
      AppToast.success(context, message: l10n.memberDetailSuspendSuccess);
    } on AppException catch (error) {
      if (!context.mounted) return;
      AppToast.error(context, message: error.localizedMessage(l10n));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final spacing = context.appSpacing;

    return BlocBuilder<MemberDetailCubit, MemberDetailState>(
      builder: (context, state) {
        if (state.isLoading) {
          return const Center(child: AppSpinner());
        }
        if (state.hasError) {
          return ErrorRetryView(
            error: state.error,
            onRetry: () =>
                context.read<MemberDetailCubit>().loadMember(memberId),
          );
        }
        final member = state.member;
        if (member == null) {
          return Center(child: Text(l10n.commonNotSet));
        }

        final twoPane = context.formFactor.isAtLeast(FormFactor.expanded);
        // A member's record reads under the members permission; changing it
        // needs that permission at `manage`. Fines are their own permission —
        // a desk assistant sees what is owed without being able to settle it
        // — and the checkout button is circulation's.
        final canManage = context.canManage(StaffPermission.members);
        final canSettleFines = context.canManage(StaffPermission.fines);
        final canWorkTheDesk = context.canManage(StaffPermission.circulation);

        final loansCard = MemberLoansCard(
          title: l10n.memberDetailLoansTitle,
          subtitle: l10n.memberDetailLoansSubtitle,
          loans: state.openLoans,
          emptyTitle: l10n.memberDetailLoansEmptyTitle,
          emptyBody: l10n.memberDetailLoansEmptyBody,
        );
        final historyCard = MemberLoansCard(
          title: l10n.memberDetailHistoryTitle,
          subtitle: l10n.memberDetailHistorySubtitle,
          loans: state.historyLoans,
          emptyTitle: l10n.memberDetailHistoryEmptyTitle,
          emptyBody: l10n.memberDetailHistoryEmptyBody,
          isHistory: true,
        );
        final finesCard = MemberFinesCard(
          fines: state.fines,
          onCollect: !canSettleFines
              ? null
              : (fine) => unawaited(_collectFine(context, fine)),
          onWaive: !canSettleFines
              ? null
              : (fine) => unawaited(_waiveFine(context, fine)),
          onCharge: !canSettleFines
              ? null
              : () => unawaited(_chargeFine(context)),
        );
        final detailsCard = MemberDetailsCard(member: member);

        return AppPageBody(
          wide: true,
          child: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  spacing.page,
                  spacing.lg,
                  spacing.page,
                  spacing.xlg,
                ),
                sliver: SliverList.list(
                  children: [
                    MemberDetailHeader(
                      member: member,
                      onCheckOut: !canWorkTheDesk
                          ? null
                          : () => context.go(
                              Routes.circulationCheckOutForMember(
                                member.barcode,
                              ),
                            ),
                      menuActions: [
                        if (canManage) ...[
                          ...memberManageMenuActions(
                            context,
                            member,
                            onEdit: () => unawaited(_edit(context)),
                            onRenew: () => unawaited(_renewMembership(context)),
                            onSuspend: () =>
                                unawaited(_suspendMembership(context)),
                            onUnsuspend: () =>
                                unawaited(_unsuspendMembership(context)),
                            onArchive: () => unawaited(_archiveMember(context)),
                          ),
                          AppMenuAction(
                            label: l10n.memberDetailDelete,
                            icon: AppIcons.delete,
                            isDestructive: true,
                            onSelected: () =>
                                unawaited(_confirmDelete(context)),
                          ),
                        ],
                      ],
                    ),
                    SizedBox(height: spacing.md),
                    MemberDetailStats(member: member),
                    SizedBox(height: spacing.md),
                    if (twoPane)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 3,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                loansCard,
                                SizedBox(height: spacing.md),
                                finesCard,
                                SizedBox(height: spacing.md),
                                historyCard,
                              ],
                            ),
                          ),
                          SizedBox(width: spacing.md),
                          Expanded(flex: 2, child: detailsCard),
                        ],
                      )
                    else ...[
                      detailsCard,
                      SizedBox(height: spacing.md),
                      loansCard,
                      SizedBox(height: spacing.md),
                      finesCard,
                      SizedBox(height: spacing.md),
                      historyCard,
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
