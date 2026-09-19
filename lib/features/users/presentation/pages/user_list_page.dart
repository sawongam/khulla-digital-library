// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:khulla/core/error/app_exception.dart';
import 'package:khulla/core/feedback/app_toast.dart';
import 'package:khulla/features/users/domain/models/staff_member.dart';
import 'package:khulla/features/users/domain/user_role.dart';
import 'package:khulla/features/users/domain/user_status.dart';
import 'package:khulla/features/users/presentation/cubit/staff_list_cubit.dart';
import 'package:khulla/features/users/presentation/cubit/staff_list_state.dart';
import 'package:khulla/features/users/presentation/widgets/staff_card.dart';
import 'package:khulla/features/users/presentation/widgets/staff_form_dialog.dart';
import 'package:khulla/features/users/presentation/widgets/staff_list_widgets.dart';
import 'package:khulla/features/users/presentation/widgets/staff_reset_password_dialog.dart';
import 'package:khulla/l10n/l10n.dart';
import 'package:khulla/shared/utils/app_exception_l10n.dart';
import 'package:khulla/shared/widgets/collection_page_view.dart';
import 'package:khulla_ui/khulla_ui.dart';

/// Who can sign in to this library, and as what.
///
/// A single-branch library still wants this screen: the ledger is only worth
/// something if it can say *which* member of staff waived a fine, and that
/// means one account per person rather than a shared login taped to the
/// monitor.
///
/// Search, filters, sort and paging are local state — the register is small
/// and fully loaded. Columns and toolbar live in `presentation/widgets/`;
/// the self-disable and last-administrator guards toast here.
class UserListPage extends StatefulWidget {
  const UserListPage({super.key});

  @override
  State<UserListPage> createState() => _UserListPageState();
}

class _UserListPageState extends State<UserListPage> {
  int _pageSize = 20;

  String _query = '';
  final Set<UserStatus> _statuses = <UserStatus>{};
  AppTableSort _sort = const AppTableSort(columnId: 'name');
  int _page = 0;

  bool get _isFiltered => _query.isNotEmpty || _statuses.isNotEmpty;

  void _clearFilters() => setState(() {
    _query = '';
    _statuses.clear();
    _page = 0;
  });

  void _toggleStatus(UserStatus status, bool selected) => setState(() {
    if (selected) {
      _statuses.add(status);
    } else {
      _statuses.remove(status);
    }
    _page = 0;
  });

  List<StaffMember> _matches(List<StaffMember> staff) {
    final needle = _query.trim().toLowerCase();
    final matches = [
      for (final member in staff)
        if ((needle.isEmpty ||
                member.name.toLowerCase().contains(needle) ||
                member.email.toLowerCase().contains(needle) ||
                (member.barcode?.toLowerCase().contains(needle) ?? false)) &&
            (_statuses.isEmpty || _statuses.contains(member.status)))
          member,
    ];

    return matches..sort((a, b) {
      final order = switch (_sort.columnId) {
        'barcode' => (a.barcode ?? '').compareTo(b.barcode ?? ''),
        'email' => a.email.compareTo(b.email),
        'role' => a.role.index.compareTo(b.role.index),
        'status' => a.status.index.compareTo(b.status.index),
        _ => a.name.compareTo(b.name),
      };
      return _sort.ascending ? order : -order;
    });
  }

  Future<void> _add() async {
    final saved = await StaffFormDialog.show(context);
    if (saved == true && mounted) {
      await context.read<StaffListCubit>().load();
    }
  }

  Future<void> _edit(StaffMember staff) async {
    final saved = await StaffFormDialog.show(context, staffId: staff.id);
    if (saved == true && mounted) {
      await context.read<StaffListCubit>().load();
    }
  }

  Future<void> _resetPassword(StaffMember staff) async {
    await StaffResetPasswordDialog.show(
      context,
      staffId: staff.id,
      staffName: staff.name,
    );
  }

  Future<void> _toggleEnabled(StaffMember staff) async {
    final l10n = context.l10n;
    final cubit = context.read<StaffListCubit>();
    final disabling = staff.status != UserStatus.disabled;

    // Checked here, against data already on screen, so the desk gets an
    // immediate, specific reason instead of a round trip to the database for
    // a rule that never changes: an account cannot disable itself, and the
    // library cannot be left with no active administrator. The repository
    // enforces the same two rules as a backstop, in case the register
    // changed under this screen between the load and the tap.
    if (disabling) {
      if (staff.id == cubit.actingStaffId) {
        AppToast.error(context, message: l10n.usersSelfDisableError);
        return;
      }
      if (staff.role == UserRole.administrator) {
        final activeAdmins = cubit.state.staff
            .where(
              (member) =>
                  member.role == UserRole.administrator &&
                  member.status == UserStatus.active,
            )
            .length;
        if (activeAdmins <= 1) {
          AppToast.error(context, message: l10n.usersLastAdministratorError);
          return;
        }
      }
      final confirmed = await AppDialog.confirmDestructive(
        context: context,
        title: l10n.usersDisableConfirmTitle(staff.name),
        message: l10n.usersDisableConfirmBody,
        confirmLabel: l10n.usersDisableConfirmAction,
        cancelLabel: l10n.commonCancel,
      );
      if (!mounted) return;
      if (!confirmed) return;
    }

    try {
      await cubit.setStatus(
        staff.id,
        disabling ? UserStatus.disabled : UserStatus.active,
      );
      if (!mounted) return;
      AppToast.success(
        context,
        message: disabling ? l10n.usersDisabledToast : l10n.usersEnabledToast,
      );
    } on AppException catch (error) {
      if (!mounted) return;
      AppToast.error(context, message: error.localizedMessage(l10n));
    }
  }

  void _pageSizeChanged(int size) {
    if (_pageSize == size) return;
    setState(() {
      _pageSize = size;
      _page = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return BlocBuilder<StaffListCubit, StaffListState>(
      builder: (context, listState) {
        if (listState.isLoading) {
          return const Center(child: AppSpinner());
        }

        final matches = _matches(listState.staff);
        final pageCount = (matches.length / _pageSize).ceil();
        final page = _page.clamp(0, pageCount == 0 ? 0 : pageCount - 1);
        final start = page * _pageSize;
        final end = (start + _pageSize).clamp(0, matches.length);

        return CollectionPageView<StaffMember>(
          onPageSizeChanged: _pageSizeChanged,
          toolbar: StaffListToolbar(
            statuses: _statuses,
            isFiltered: _isFiltered,
            onSearchChanged: (value) => setState(() {
              _query = value;
              _page = 0;
            }),
            onStatusToggled: _toggleStatus,
            onClearFilters: _clearFilters,
            onAdd: () => unawaited(_add()),
          ),
          items: matches.sublist(start, end),
          columns: staffTableColumns(
            context,
            onEdit: (staff) => unawaited(_edit(staff)),
            onResetPassword: (staff) => unawaited(_resetPassword(staff)),
            onToggleEnabled: (staff) => unawaited(_toggleEnabled(staff)),
          ),
          sort: _sort,
          onSort: (next) => setState(() {
            _sort = next;
            _page = 0;
          }),
          onRowTap: (staff) => unawaited(_edit(staff)),
          compactBuilder: (context, staff) =>
              StaffCard(staff: staff, onTap: () => unawaited(_edit(staff))),
          emptyState: _isFiltered
              ? AppEmptyView(
                  icon: AppIcons.noResults,
                  title: l10n.commonNoMatchesTitle,
                  message: l10n.commonNoMatchesBody,
                  actionLabel: l10n.commonClearFilters,
                  onAction: _clearFilters,
                )
              : AppEmptyView(
                  icon: AppIcons.idCard,
                  title: l10n.usersEmptyTitle,
                  message: l10n.usersEmptyBody,
                  actionLabel: l10n.usersAdd,
                  onAction: () => unawaited(_add()),
                ),
          footer: AppPagination(
            rangeLabel: l10n.commonShowingRange(
              '${start + 1}',
              '$end',
              '${matches.length}',
            ),
            previousTooltip: l10n.commonPreviousPage,
            nextTooltip: l10n.commonNextPage,
            pageCount: pageCount,
            currentPage: page,
            onPageSelected: (next) => setState(() => _page = next),
            onPrevious: page == 0
                ? null
                : () => setState(() => _page = page - 1),
            onNext: page >= pageCount - 1
                ? null
                : () => setState(() => _page = page + 1),
          ),
        );
      },
    );
  }
}
