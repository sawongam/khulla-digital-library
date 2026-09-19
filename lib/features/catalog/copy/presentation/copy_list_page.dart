// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:khulla/core/di/injection.dart';
import 'package:khulla/core/error/app_exception.dart';
import 'package:khulla/core/feedback/app_toast.dart';
import 'package:khulla/core/router/routes.dart';
import 'package:khulla/features/catalog/copy/domain/models/copy.dart';
import 'package:khulla/features/catalog/copy/presentation/copy_form_dialog.dart';
import 'package:khulla/features/catalog/copy/presentation/copy_list_refresh.dart';
import 'package:khulla/features/catalog/copy/presentation/cubit/copy_cubit.dart';
import 'package:khulla/features/catalog/copy/presentation/cubit/copy_state.dart';
import 'package:khulla/features/catalog/copy/presentation/widgets/copy_card.dart';
import 'package:khulla/features/catalog/copy/presentation/widgets/copy_status_badge.dart';
import 'package:khulla/features/catalog/shared/domain/copy_status.dart';
import 'package:khulla/features/catalog/shared/presentation/catalog_labels.dart';
import 'package:khulla/features/users/domain/user_role.dart';
import 'package:khulla/l10n/l10n.dart';
import 'package:khulla/shared/utils/app_exception_l10n.dart';
import 'package:khulla/shared/utils/permission_context.dart';
import 'package:khulla/shared/widgets/collection_page_view.dart';
import 'package:khulla/shared/widgets/error_retry_view.dart';
import 'package:khulla_ui/khulla_ui.dart';

/// Every physical item, across every title.
class CopyListPage extends StatefulWidget {
  const CopyListPage({super.key});

  @override
  State<CopyListPage> createState() => _CopyListPageState();
}

class _CopyListPageState extends State<CopyListPage> {
  static const List<CopyStatus> _filterableStatuses = [
    CopyStatus.available,
    CopyStatus.onLoan,
    CopyStatus.reserved,
    CopyStatus.lost,
    CopyStatus.damaged,
  ];

  @override
  void initState() {
    super.initState();
    getIt<CopyListRefresh>().reload = _reload;
  }

  @override
  void dispose() {
    getIt<CopyListRefresh>().reload = null;
    super.dispose();
  }

  void _reload() {
    if (!mounted) return;
    unawaited(context.read<CopyCubit>().loadCopies());
  }

  Future<void> _addCopy() async {
    final saved = await CopyFormDialog.show(context);
    if (saved == true && mounted) {
      await context.read<CopyCubit>().loadCopies();
    }
  }

  Future<void> _markLost(Copy copy) async {
    final l10n = context.l10n;
    final confirmed = await AppDialog.confirmDestructive(
      context: context,
      title: l10n.copiesMarkLost,
      message: l10n.copiesMarkLostBody,
      confirmLabel: l10n.copiesMarkLost,
      cancelLabel: l10n.commonCancel,
    );
    if (!mounted || !confirmed) return;
    try {
      await context.read<CopyCubit>().markCopyLost(copy.id);
      if (!mounted) return;
      AppToast.success(context, message: l10n.copiesMarkLostSuccess);
    } on AppException catch (error) {
      if (!mounted) return;
      AppToast.error(context, message: error.localizedMessage(l10n));
    }
  }

  Future<void> _markDamaged(Copy copy) async {
    final l10n = context.l10n;
    final confirmed = await AppDialog.confirmDestructive(
      context: context,
      title: l10n.copiesMarkDamaged,
      message: l10n.copiesMarkDamagedBody,
      confirmLabel: l10n.copiesMarkDamaged,
      cancelLabel: l10n.commonCancel,
    );
    if (!mounted || !confirmed) return;
    try {
      await context.read<CopyCubit>().markCopyDamaged(copy.id);
      if (!mounted) return;
      AppToast.success(context, message: l10n.copiesMarkDamagedSuccess);
    } on AppException catch (error) {
      if (!mounted) return;
      AppToast.error(context, message: error.localizedMessage(l10n));
    }
  }

  Future<void> _withdraw(Copy copy) async {
    final l10n = context.l10n;
    final confirmed = await AppDialog.confirmDestructive(
      context: context,
      title: l10n.copiesWithdraw,
      message: l10n.copiesWithdrawBody,
      confirmLabel: l10n.copiesWithdraw,
      cancelLabel: l10n.commonCancel,
    );
    if (!mounted || !confirmed) return;
    try {
      await context.read<CopyCubit>().archiveCopy(copy.id);
      if (!mounted) return;
      AppToast.success(context, message: l10n.copiesWithdrawSuccess);
    } on AppException catch (error) {
      if (!mounted) return;
      AppToast.error(context, message: error.localizedMessage(l10n));
    }
  }

  List<AppTableColumn<Copy>> _columns(AppLocalizations l10n) {
    final canManage = context.canManage(StaffPermission.catalog);
    final scheme = context.colorScheme;
    final muted = context.textTheme.bodyMedium?.copyWith(
      color: scheme.onSurfaceVariant,
    );

    return [
      AppTableColumn<Copy>(
        id: 'barcode',
        label: l10n.copiesColumnBarcode,
        flex: 2,
        sortable: true,
        cellBuilder: (context, copy) => Text(copy.barcode),
      ),
      AppTableColumn<Copy>(
        id: 'title',
        label: l10n.copiesColumnTitle,
        flex: 3,
        sortable: true,
        showFrom: FormFactor.medium,
        cellBuilder: (context, copy) => Text(copy.titleName),
      ),
      AppTableColumn<Copy>(
        id: 'shelf',
        label: l10n.copiesColumnShelf,
        flex: 2,
        sortable: true,
        showFrom: FormFactor.expanded,
        cellBuilder: (context, copy) => Text(copy.shelf, style: muted),
      ),
      AppTableColumn<Copy>(
        id: 'borrower',
        label: l10n.copiesColumnBorrower,
        flex: 2,
        showFrom: FormFactor.large,
        cellBuilder: (context, copy) =>
            Text(copy.borrower ?? l10n.commonNotSet, style: muted),
      ),
      AppTableColumn<Copy>(
        id: 'status',
        flex: 2,
        label: l10n.commonStatus,
        cellBuilder: (context, copy) => CopyStatusBadge(status: copy.status),
      ),
      AppTableColumn<Copy>(
        id: 'notes',
        label: l10n.fieldNotes,
        flex: 2,
        showFrom: FormFactor.large,
        cellBuilder: (context, copy) => Text(
          copy.notes ?? l10n.commonNotSet,
          style: muted,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      // Every action in this column writes, so the column itself is gone for
      // a role that may read the catalogue but not change it - rather than a
      // menu button that opens onto nothing.
      if (canManage)
        AppTableColumn<Copy>(
          id: 'actions',
          label: l10n.commonActions,
          alignment: Alignment.centerRight,
          cellBuilder: (context, copy) => AppMenuButton(
            tooltip: l10n.commonMoreActions,
            actions: [
              AppMenuAction(
                label: l10n.copiesMarkLost,
                icon: AppIcons.help,
                onSelected: () => unawaited(_markLost(copy)),
              ),
              AppMenuAction(
                label: l10n.copiesMarkDamaged,
                icon: AppIcons.damage,
                onSelected: () => unawaited(_markDamaged(copy)),
              ),
              AppMenuAction(
                label: l10n.copiesWithdraw,
                icon: AppIcons.delete,
                isDestructive: true,
                onSelected: () => unawaited(_withdraw(copy)),
              ),
            ],
          ),
        ),
    ];
  }

  bool _isFiltered(CopyState state) =>
      state.query.search.isNotEmpty || state.query.statuses.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cubit = context.read<CopyCubit>();

    return BlocBuilder<CopyCubit, CopyState>(
      builder: (context, state) {
        if (state.hasError) {
          return ErrorRetryView(
            error: state.error,
            onRetry: cubit.loadCopies,
          );
        }

        final bootstrapping = state.isLoading && state.copies.isEmpty;

        final pageSize = state.query.limit;
        final pageCount = (state.totalCount / pageSize).ceil();
        final page = (state.query.offset / pageSize).floor().clamp(
          0,
          pageCount == 0 ? 0 : pageCount - 1,
        );
        final start = state.totalCount == 0 ? 0 : page * pageSize;
        final end = (start + state.copies.length).clamp(0, state.totalCount);
        final sort = AppTableSort(
          columnId: state.query.sortColumn,
          ascending: state.query.sortAscending,
        );

        return CollectionPageView<Copy>(
          onPageSizeChanged: cubit.limitChanged,
          summary: l10n.copiesSubtitle('${state.totalCount}'),
          toolbar: AppToolbar(
            search: AppSearchField(
              hintText: l10n.copiesSearchHint,
              clearTooltip: l10n.commonClearSearch,
              onChanged: cubit.searchChanged,
            ),
            filters: [
              for (final status in _filterableStatuses)
                AppFilterChip(
                  label: status.label(l10n),
                  tone: status.tone,
                  selected: state.query.statuses.contains(status),
                  onSelected: (selected) =>
                      cubit.statusFilterChanged(status, selected),
                ),
            ],
            actions: [
              if (_isFiltered(state))
                AppTextButton(
                  onPressed: cubit.clearFilters,
                  child: Text(l10n.commonClearFilters),
                ),
            ],
          ),
          items: state.copies,
          columns: _columns(l10n),
          sort: sort,
          onSort: (next) => cubit.sortChanged(next.columnId, next.ascending),
          onRowTap: (copy) => context.go(Routes.catalogTitle(copy.titleId)),
          compactBuilder: (context, copy) => CopyCard(
            copy: copy,
            onTap: () => context.go(Routes.catalogTitle(copy.titleId)),
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
                  icon: AppIcons.inventory,
                  title: l10n.copiesEmptyTitle,
                  message: l10n.copiesEmptyBody,
                  actionLabel: context.canManage(StaffPermission.catalog)
                      ? l10n.copiesAdd
                      : null,
                  onAction: context.canManage(StaffPermission.catalog)
                      ? () => unawaited(_addCopy())
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
