// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:khulla/core/error/app_exception.dart';
import 'package:khulla/core/feedback/app_toast.dart';
import 'package:khulla/core/router/routes.dart';
import 'package:khulla/features/circulation/circulation/presentation/cubit/loan_list_cubit.dart';
import 'package:khulla/features/circulation/circulation/presentation/cubit/loan_list_state.dart';
import 'package:khulla/features/circulation/circulation/presentation/widgets/loan_list_columns.dart';
import 'package:khulla/features/circulation/circulation/presentation/widgets/loan_list_widgets.dart';
import 'package:khulla/features/circulation/loan/domain/models/loan.dart';
import 'package:khulla/features/circulation/shared/domain/loan_status.dart';
import 'package:khulla/features/users/domain/user_role.dart';
import 'package:khulla/l10n/l10n.dart';
import 'package:khulla/shared/utils/app_exception_l10n.dart';
import 'package:khulla/shared/utils/permission_context.dart';
import 'package:khulla/shared/widgets/collection_page_view.dart';
import 'package:khulla/shared/widgets/error_retry_view.dart';
import 'package:khulla_ui/khulla_ui.dart';

/// The desk: what is out, what is due back, and what is late.
///
/// One page rather than a landing screen plus a list, because the loans table
/// *is* what a librarian came here to look at. [LoanListCubit] supplies the
/// counts, the open-loan query and the holds figure for the stat strip — tapping
/// *Overdue* selects the same rows the chip does. Renew toasts at its call site;
/// return routes to the returns desk.
///
/// Stats, toolbar, columns and card live in `presentation/widgets/`; renew
/// toasts at its call site here.
class CirculationPage extends StatelessWidget {
  const CirculationPage({super.key});

  bool _isFiltered(LoanListState state) =>
      state.query.search.isNotEmpty || state.query.status != null;

  Future<void> _renewLoan(BuildContext context, Loan loan) async {
    final l10n = context.l10n;
    try {
      await context.read<LoanListCubit>().renewLoan(loan.id);
      if (!context.mounted) return;
      AppToast.success(context, message: l10n.loansRenewSuccess);
    } on AppException catch (error) {
      if (!context.mounted) return;
      AppToast.error(context, message: error.localizedMessage(l10n));
    }
  }

  Future<void> _returnLoan(BuildContext context, Loan loan) async {
    final l10n = context.l10n;
    final barcode = loan.barcode;
    if (barcode == null || barcode.trim().isEmpty) {
      AppToast.error(
        context,
        message: const NotFoundException('That copy has no barcode.')
            .localizedMessage(l10n),
      );
      return;
    }
    final confirmed = await AppDialog.confirmDestructive(
      context: context,
      title: l10n.loansReturn,
      message: '${l10n.loansReturn} $barcode?',
      confirmLabel: l10n.returnsConfirm,
      cancelLabel: l10n.commonCancel,
    );
    if (!context.mounted || !confirmed) return;
    try {
      await context.read<LoanListCubit>().returnLoan(barcode);
      if (!context.mounted) return;
      AppToast.success(context, message: l10n.returnsSuccess);
    } on AppException catch (error) {
      if (!context.mounted) return;
      AppToast.error(context, message: error.localizedMessage(l10n));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cubit = context.read<LoanListCubit>();

    return BlocBuilder<LoanListCubit, LoanListState>(
      builder: (context, state) {
        if (state.hasError) {
          return ErrorRetryView(
            error: state.error,
            onRetry: cubit.loadOpenLoans,
          );
        }

        final bootstrapping = state.isLoading && state.loans.isEmpty;
        final isFiltered = _isFiltered(state);
        final sort = AppTableSort(
          columnId: _displaySortColumn(state.query.sortColumn),
          ascending: state.query.sortAscending,
        );

        return CollectionPageView<Loan>(
          onPageSizeChanged: cubit.limitChanged,
          intro: LoanListStats(
            onLoanCount: state.onLoanCount,
            dueTodayCount: state.dueTodayCount,
            overdueCount: state.overdueCount,
            holdsCount: state.holdsCount,
            onAllTap: () => cubit.statusFilterChanged(null),
            onDueTodayTap: () => cubit.statusFilterChanged(LoanStatus.dueToday),
            onOverdueTap: () => cubit.statusFilterChanged(LoanStatus.overdue),
            onHoldsTap: () => context.go(Routes.circulationReservations),
          ),
          toolbar: LoanListToolbar(
            status: state.query.status,
            isFiltered: isFiltered,
            onSearchChanged: cubit.searchChanged,
            onStatusFilterChanged: cubit.statusFilterChanged,
            onClearFilters: cubit.clearFilters,
          ),
          items: state.loans,
          columns: loanListColumns(
            context,
            onRenew: (loan) => unawaited(_renewLoan(context, loan)),
            onReturn: (loan) => unawaited(_returnLoan(context, loan)),
          ),
          sort: sort,
          onSort: (next) => cubit.sortChanged(next.columnId, next.ascending),
          onRowTap: (loan) => context.go(Routes.member(loan.memberId)),
          compactBuilder: (context, loan) => LoanCard(
            loan: loan,
            onTap: () => context.go(Routes.member(loan.memberId)),
            onReturn: context.canManage(StaffPermission.circulation)
                ? () => unawaited(_returnLoan(context, loan))
                : null,
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
                  icon: AppIcons.transfer,
                  title: l10n.circulationLoansEmptyTitle,
                  message: l10n.circulationLoansEmptyBody,
                  actionLabel: context.canManage(StaffPermission.circulation)
                      ? l10n.circulationCheckOut
                      : null,
                  onAction: context.canManage(StaffPermission.circulation)
                      ? () => context.go(Routes.circulationCheckOut)
                      : null,
                ),
        );
      },
    );
  }

  String _displaySortColumn(String columnId) => switch (columnId) {
    'memberName' => 'member',
    'titleName' => 'title',
    'checkedOutAt' => 'issued',
    'barcode' => 'barcode',
    _ => 'due',
  };
}
