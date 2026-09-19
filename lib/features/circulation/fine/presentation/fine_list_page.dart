// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:khulla/core/error/app_exception.dart';
import 'package:khulla/core/feedback/app_toast.dart';
import 'package:khulla/core/money/money.dart';
import 'package:khulla/core/router/routes.dart';
import 'package:khulla/features/circulation/fine/domain/models/fine.dart';
import 'package:khulla/features/circulation/fine/presentation/cubit/fine_list_cubit.dart';
import 'package:khulla/features/circulation/fine/presentation/cubit/fine_list_state.dart';
import 'package:khulla/features/circulation/fine/presentation/widgets/fine_list_columns.dart';
import 'package:khulla/features/circulation/fine/presentation/widgets/fine_list_stats.dart';
import 'package:khulla/features/circulation/fine/presentation/widgets/fine_list_toolbar.dart';
import 'package:khulla/l10n/l10n.dart';
import 'package:khulla/shared/utils/app_exception_l10n.dart';
import 'package:khulla/shared/widgets/collection_page_view.dart';
import 'package:khulla/shared/widgets/error_retry_view.dart';
import 'package:khulla_ui/khulla_ui.dart';

/// The fines ledger: what is owed, what was taken, what was written off.
///
/// Every amount on this screen is a [Money] rendered through `display()` —
/// never interpolated, which would print the paisa, and never formatted by
/// hand, which would put the currency symbol somewhere the library's settings
/// did not ask for. [FineListCubit] drives search, status filters and the
/// summary totals. Collect and waive confirm in a dialog, then persist through
/// [FineListCubit]. Columns, stats and toolbar live in `presentation/widgets/`.
class FineListPage extends StatelessWidget {
  const FineListPage({super.key});

  bool _isFiltered(FineListState state) =>
      state.query.search.isNotEmpty || state.query.status != null;

  Future<void> _collect(BuildContext context, Fine fine) async {
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
      await context.read<FineListCubit>().collectFine(fine.id);
      if (!context.mounted) return;
      AppToast.success(context, message: l10n.finesCollectSuccess);
    } on AppException catch (error) {
      if (!context.mounted) return;
      AppToast.error(context, message: error.localizedMessage(l10n));
    }
  }

  Future<void> _waive(BuildContext context, Fine fine) async {
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
      await context.read<FineListCubit>().waiveFine(fine.id);
      if (!context.mounted) return;
      AppToast.success(context, message: l10n.finesWaiveSuccess);
    } on AppException catch (error) {
      if (!context.mounted) return;
      AppToast.error(context, message: error.localizedMessage(l10n));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cubit = context.read<FineListCubit>();

    return BlocBuilder<FineListCubit, FineListState>(
      builder: (context, state) {
        if (state.hasError) {
          return ErrorRetryView(
            error: state.error,
            onRetry: cubit.loadFines,
          );
        }

        final bootstrapping = state.isLoading && state.fines.isEmpty;
        final isFiltered = _isFiltered(state);

        return CollectionPageView<Fine>(
          onPageSizeChanged: cubit.limitChanged,
          summary: l10n.finesSubtitle,
          intro: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              FineListStats(
                outstandingTotal: state.outstandingTotal,
                collectedTotal: state.collectedTotal,
                waivedTotal: state.waivedTotal,
                membersOwing: state.membersOwing,
              ),
            ],
          ),
          toolbar: FineListToolbar(
            status: state.query.status,
            isFiltered: isFiltered,
            onSearchChanged: cubit.searchChanged,
            onStatusFilterChanged: cubit.statusFilterChanged,
            onClearFilters: cubit.clearFilters,
          ),
          items: state.fines,
          onRowTap: (fine) => context.go(Routes.member(fine.memberId)),
          compactBuilder: (context, fine) => FineCard(
            fine: fine,
            onTap: () => context.go(Routes.member(fine.memberId)),
          ),
          columns: fineListColumns(
            context,
            onCollect: (fine) => unawaited(_collect(context, fine)),
            onWaive: (fine) => unawaited(_waive(context, fine)),
            onViewMember: (fine) => context.go(Routes.member(fine.memberId)),
          ),
          emptyState: bootstrapping
              ? const Center(child: AppSpinner())
              : isFiltered
              ? AppEmptyView(
                  icon: AppIcons.noResults,
                  title: l10n.commonNoMatchesTitle,
                  message: l10n.commonNoMatchesBody,
                  actionLabel: l10n.commonClearFilters,
                  onAction: cubit.clearFilters,
                )
              : AppEmptyView(
                  icon: AppIcons.wallet,
                  title: l10n.finesEmptyTitle,
                  message: l10n.finesEmptyBody,
                ),
        );
      },
    );
  }
}
