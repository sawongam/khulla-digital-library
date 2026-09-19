// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:khulla/app/router/app_router.dart';
import 'package:khulla/core/di/injection.dart';
import 'package:khulla/core/error/app_exception.dart';
import 'package:khulla/core/feedback/app_toast.dart';
import 'package:khulla/core/lifecycle/dispose_bag.dart';
import 'package:khulla/core/router/routes.dart';
import 'package:khulla/features/members/domain/models/member.dart';
import 'package:khulla/features/members/domain/models/member_query.dart';
import 'package:khulla/features/members/presentation/cubit/member_cubit.dart';
import 'package:khulla/features/members/presentation/cubit/member_state.dart';
import 'package:khulla/features/members/presentation/member_list_refresh.dart';
import 'package:khulla/features/members/presentation/pages/member_form_dialog.dart';
import 'package:khulla/features/members/presentation/widgets/member_card.dart';
import 'package:khulla/features/members/presentation/widgets/member_list_toolbar.dart';
import 'package:khulla/features/members/presentation/widgets/member_table_columns.dart';
import 'package:khulla/features/users/domain/user_role.dart';
import 'package:khulla/l10n/l10n.dart';
import 'package:khulla/shared/utils/app_exception_l10n.dart';
import 'package:khulla/shared/utils/permission_context.dart';
import 'package:khulla/shared/widgets/collection_page_view.dart';
import 'package:khulla/shared/widgets/error_retry_view.dart';
import 'package:khulla_ui/khulla_ui.dart';

/// The register: every borrower and how they stand.
///
/// The filters are the questions a desk actually asks of it — who is holding
/// something, who owes something, whose card has stopped working — rather
/// than one chip per enum value. [MemberCubit] turns search, those filters,
/// sort and paging into one query. Check-out jumps to the circulation desk.
///
/// Orchestration only: the toolbar and columns live in
/// `presentation/widgets/`; every write below toasts at its call site.
class MemberListPage extends StatefulWidget {
  const MemberListPage({super.key});

  @override
  State<MemberListPage> createState() => _MemberListPageState();
}

class _MemberListPageState extends State<MemberListPage> with DisposeBag {
  late final TextEditingController _search = textController();
  late final GoRouterDelegate _routerDelegate =
      getIt<AppRouter>().router.routerDelegate;

  @override
  void initState() {
    super.initState();
    getIt<MemberListRefresh>().reload = _reload;
    _routerDelegate.addListener(_handleRouteChange);
  }

  @override
  void dispose() {
    _routerDelegate.removeListener(_handleRouteChange);
    getIt<MemberListRefresh>().reload = null;
    super.dispose();
  }

  /// Resets the list whenever the operator leaves the members section —
  /// switching rail tabs, checking out to a member, anything that moves the
  /// location out from under `/members`. The shell keeps every branch alive,
  /// so without this the stale search is still sitting there on return.
  /// Dialogs never change the location, so add/edit dialogs are unaffected.
  void _handleRouteChange() {
    if (!mounted) return;
    final location = _routerDelegate.currentConfiguration.uri.toString();
    if (Routes.isUnder(location, Routes.members)) return;
    final cubit = context.read<MemberCubit>();
    if (cubit.state.query == MemberQuery(limit: cubit.state.query.limit)) {
      return;
    }
    _search.clear();
    cubit.clearFilters();
  }

  void _reload() {
    if (!mounted) return;
    unawaited(context.read<MemberCubit>().loadMembers());
  }

  /// Opens a member's detail page from a clean list: the list cubit outlives
  /// the push (detail is a sub-route), so the search field and its query are
  /// cleared up front — otherwise coming back shows the stale search.
  void _openMember(Member member) {
    _search.clear();
    context.read<MemberCubit>().clearFilters();
    context.go(Routes.member(member.id));
  }

  Future<void> _addMember() async {
    final saved = await MemberFormDialog.show(context);
    if (saved == true && mounted) {
      await context.read<MemberCubit>().loadMembers();
    }
  }

  Future<void> _editMember(Member member) async {
    final saved = await MemberFormDialog.show(context, memberId: member.id);
    if (saved == true && mounted) {
      await context.read<MemberCubit>().loadMembers();
    }
  }

  Future<void> _renewMembership(BuildContext context, Member member) async {
    final l10n = context.l10n;
    try {
      await context.read<MemberCubit>().renewMembership(member.id);
      if (!context.mounted) return;
      AppToast.success(context, message: l10n.memberDetailRenewSuccess);
    } on AppException catch (error) {
      if (!context.mounted) return;
      AppToast.error(context, message: error.localizedMessage(l10n));
    }
  }

  Future<void> _suspendMembership(BuildContext context, Member member) async {
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
      await context.read<MemberCubit>().suspendMember(member.id);
      if (!context.mounted) return;
      AppToast.success(context, message: l10n.memberDetailSuspendSuccess);
    } on AppException catch (error) {
      if (!context.mounted) return;
      AppToast.error(context, message: error.localizedMessage(l10n));
    }
  }

  Future<void> _unsuspendMembership(BuildContext context, Member member) async {
    final l10n = context.l10n;
    try {
      await context.read<MemberCubit>().unsuspendMember(member.id);
      if (!context.mounted) return;
      AppToast.success(context, message: l10n.memberDetailUnsuspendSuccess);
    } on AppException catch (error) {
      if (!context.mounted) return;
      AppToast.error(context, message: error.localizedMessage(l10n));
    }
  }

  Future<void> _archiveMember(BuildContext context, Member member) async {
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
      await context.read<MemberCubit>().archiveMember(member.id);
      if (!context.mounted) return;
      AppToast.success(context, message: l10n.memberDetailArchiveSuccess);
    } on AppException catch (error) {
      if (!context.mounted) return;
      AppToast.error(context, message: error.localizedMessage(l10n));
    }
  }

  bool _isFiltered(MemberState state) =>
      state.query.search.isNotEmpty ||
      state.query.withLoans ||
      state.query.owesFines ||
      state.query.suspended ||
      state.query.expiring;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cubit = context.read<MemberCubit>();

    return BlocBuilder<MemberCubit, MemberState>(
      builder: (context, state) {
        if (state.hasError) {
          return ErrorRetryView(
            error: state.error,
            onRetry: cubit.loadMembers,
          );
        }

        final bootstrapping = state.isLoading && state.members.isEmpty;

        final pageSize = state.query.limit;
        final pageCount = (state.totalCount / pageSize).ceil();
        final page = (state.query.offset / pageSize).floor().clamp(
          0,
          pageCount == 0 ? 0 : pageCount - 1,
        );
        final start = state.totalCount == 0 ? 0 : page * pageSize;
        final end = (start + state.members.length).clamp(0, state.totalCount);
        final sort = AppTableSort(
          columnId: state.query.sortColumn,
          ascending: state.query.sortAscending,
        );

        return CollectionPageView<Member>(
          onPageSizeChanged: cubit.limitChanged,
          summary: l10n.membersSubtitle('${state.totalCount}'),
          toolbar: MemberListToolbar(
            searchController: _search,
            query: state.query,
            isFiltered: _isFiltered(state),
            onSearchChanged: cubit.searchChanged,
            onWithLoansChanged: cubit.withLoansChanged,
            onOwesFinesChanged: cubit.owesFinesChanged,
            onExpiringChanged: cubit.expiringChanged,
            onSuspendedChanged: cubit.suspendedChanged,
            onClearFilters: cubit.clearFilters,
          ),
          items: state.members,
          columns: memberTableColumns(
            context,
            onCheckOut: (member) => goToMemberCheckOut(context, member),
            onEdit: (member) => unawaited(_editMember(member)),
            onRenew: (member) => unawaited(_renewMembership(context, member)),
            onSuspend: (member) =>
                unawaited(_suspendMembership(context, member)),
            onUnsuspend: (member) =>
                unawaited(_unsuspendMembership(context, member)),
            onArchive: (member) => unawaited(_archiveMember(context, member)),
          ),
          sort: sort,
          onSort: (next) => cubit.sortChanged(next.columnId, next.ascending),
          onRowTap: _openMember,
          compactBuilder: (context, member) => MemberCard(
            member: member,
            onTap: () => _openMember(member),
          ),
          emptyState: bootstrapping
              ? const Center(child: AppSpinner())
              : _isFiltered(state)
              ? AppEmptyView(
                  icon: AppIcons.noResults,
                  title: l10n.commonNoMatchesTitle,
                  message: l10n.commonNoMatchesBody,
                  actionLabel: l10n.commonClearFilters,
                  onAction: cubit.clearFilters,
                )
              : AppEmptyView(
                  icon: AppIcons.people,
                  title: l10n.membersEmptyTitle,
                  message: l10n.membersEmptyBody,
                  actionLabel: context.canManage(StaffPermission.members)
                      ? l10n.membersAdd
                      : null,
                  onAction: context.canManage(StaffPermission.members)
                      ? () => unawaited(_addMember())
                      : null,
                ),
          footer: AppPagination(
            rangeLabel: l10n.commonShowingRange(
              '${start + 1}',
              '$end',
              '${state.totalCount}',
            ),
            previousTooltip: l10n.commonPreviousPage,
            nextTooltip: l10n.commonNextPage,
            pageCount: pageCount,
            currentPage: page,
            onPageSelected: cubit.pageChanged,
            onPrevious: page == 0 ? null : () => cubit.pageChanged(page - 1),
            onNext: page >= pageCount - 1
                ? null
                : () => cubit.pageChanged(page + 1),
          ),
        );
      },
    );
  }
}
