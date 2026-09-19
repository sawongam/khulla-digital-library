// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:khulla/core/di/injection.dart';
import 'package:khulla/core/router/routes.dart';
import 'package:khulla/features/catalog/shared/presentation/catalog_labels.dart';
import 'package:khulla/features/catalog/title/domain/models/title.dart'
    as catalog;
import 'package:khulla/features/catalog/title/presentation/cubit/title/title_cubit.dart';
import 'package:khulla/features/catalog/title/presentation/cubit/title/title_state.dart';
import 'package:khulla/features/catalog/title/presentation/title_form_dialog.dart';
import 'package:khulla/features/catalog/title/presentation/title_list_refresh.dart';
import 'package:khulla/features/catalog/title/presentation/widgets/title_card.dart';
import 'package:khulla/features/users/domain/user_role.dart';
import 'package:khulla/l10n/l10n.dart';
import 'package:khulla/shared/presentation/cubit/reference_data_cubit.dart';
import 'package:khulla/shared/utils/permission_context.dart';
import 'package:khulla/shared/widgets/collection_page_view.dart';
import 'package:khulla/shared/widgets/error_retry_view.dart';
import 'package:khulla_ui/khulla_ui.dart';

String _displayOrDash(String? value) =>
    value == null || value.isEmpty ? '-' : value;

/// Every work the library holds.
///
/// [TitleCubit] owns search, format and availability filters, sort and paging —
/// the same four knobs the placeholder ran in memory, now one SQLite query.
/// Format chips read [ReferenceDataCubit] because formats are reference data,
/// not part of the title query. The [CollectionPageView] shape is unchanged:
/// row tap opens the detail route, the empty state opens [TitleFormDialog].
class TitleListPage extends StatefulWidget {
  const TitleListPage({super.key});

  @override
  State<TitleListPage> createState() => _TitleListPageState();
}

class _TitleListPageState extends State<TitleListPage> {
  @override
  void initState() {
    super.initState();
    getIt<TitleListRefresh>().reload = _reload;
  }

  @override
  void dispose() {
    getIt<TitleListRefresh>().reload = null;
    super.dispose();
  }

  void _reload() {
    if (!mounted) return;
    unawaited(context.read<TitleCubit>().loadTitles());
  }

  Future<void> _addTitle() async {
    final saved = await TitleFormDialog.show(context);
    if (saved == true && mounted) {
      await context.read<TitleCubit>().loadTitles();
    }
  }

  bool _isFiltered(TitleState state) =>
      state.query.search.isNotEmpty ||
      state.query.formatId != null ||
      state.query.availableOnly;

  List<AppTableColumn<catalog.Title>> _columns(AppLocalizations l10n) {
    final scheme = context.colorScheme;
    final muted = context.textTheme.bodyMedium?.copyWith(
      color: scheme.onSurfaceVariant,
    );
    final smallMuted = context.textTheme.bodySmall?.copyWith(
      color: scheme.onSurfaceVariant,
    );
    final isbnStyle = context.appTextStyles.numeric.copyWith(
      color: scheme.onSurfaceVariant,
    );

    return [
      AppTableColumn<catalog.Title>(
        id: 'title',
        label: l10n.titlesColumnTitle,
        flex: 4,
        sortable: true,
        cellBuilder: (context, title) => Row(
          children: [
            Expanded(
              child: Text(
                title.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
      AppTableColumn<catalog.Title>(
        id: 'author',
        label: l10n.titlesColumnAuthor,
        flex: 2,
        sortable: true,
        cellBuilder: (context, title) =>
            Text(_displayOrDash(title.author), style: muted),
      ),
      AppTableColumn<catalog.Title>(
        id: 'isbn',
        label: l10n.titlesColumnIsbn,
        flex: 2,
        cellBuilder: (context, title) =>
            Text(_displayOrDash(title.isbn), style: isbnStyle),
      ),
      AppTableColumn<catalog.Title>(
        id: 'publisher',
        label: l10n.titlesColumnPublisher,
        flex: 2,
        sortable: true,
        cellBuilder: (context, title) =>
            Text(_displayOrDash(title.publisher), style: muted),
      ),
      AppTableColumn<catalog.Title>(
        id: 'year',
        label: l10n.titlesColumnYear,
        sortable: true,
        cellBuilder: (context, title) => Text(_displayOrDash(title.year)),
      ),
      AppTableColumn<catalog.Title>(
        id: 'available',
        flex: 2,
        label: l10n.titlesColumnAvailable,
        sortable: true,
        cellBuilder: (context, title) => Text(
          l10n.titlesCopiesOf(
            '${title.availableCount}',
            '${title.copyCount}',
          ),
          style: smallMuted,
        ),
      ),
      AppTableColumn<catalog.Title>(
        id: 'status',
        label: l10n.commonStatus,
        alignment: Alignment.centerRight,
        cellBuilder: (context, title) => AppStatusBadge(
          dense: true,
          label: title.availableCount > 0
              ? l10n.statusAvailable
              : l10n.statusOnLoan,
          tone: title.availableCount > 0
              ? AppStatusTone.success
              : AppStatusTone.brand,
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cubit = context.read<TitleCubit>();
    final formats = context.watch<ReferenceDataCubit>().state.formats;

    return BlocBuilder<TitleCubit, TitleState>(
      builder: (context, state) {
        if (state.hasError) {
          return ErrorRetryView(
            error: state.error,
            onRetry: cubit.loadTitles,
          );
        }

        final bootstrapping = state.isLoading && state.titles.isEmpty;
        final pageSize = state.query.limit;
        final pageCount = (state.totalCount / pageSize).ceil();
        final page = (state.query.offset / pageSize).floor().clamp(
          0,
          pageCount == 0 ? 0 : pageCount - 1,
        );
        final start = state.totalCount == 0 ? 0 : page * pageSize;
        final end = (start + state.titles.length).clamp(0, state.totalCount);
        final sort = AppTableSort(
          columnId: state.query.sortColumn,
          ascending: state.query.sortAscending,
        );

        return CollectionPageView<catalog.Title>(
          onPageSizeChanged: cubit.limitChanged,
          summary: l10n.titlesSubtitle('${state.totalCount}'),
          toolbar: AppToolbar(
            search: AppSearchField(
              hintText: l10n.titlesSearchHint,
              clearTooltip: l10n.commonClearSearch,
              onChanged: cubit.searchChanged,
            ),
            filters: [
              AppFilterChip(
                label: l10n.statusAvailable,
                icon: AppIcons.success,
                selected: state.query.availableOnly,
                onSelected: cubit.availableOnlyChanged,
              ),
              if (formats.isNotEmpty)
                SizedBox(
                  height: context.appSpacing.lg,
                  child: VerticalDivider(
                    width: context.appSpacing.md,
                    thickness: context.appBorders.hairline,
                    color: context.appColors.hairline,
                  ),
                ),
              for (final format in formats)
                AppFilterChip(
                  label: format.label(l10n),
                  icon: format.icon,
                  selected: state.query.formatId == format.id,
                  onSelected: (selected) => cubit.formatFilterChanged(
                    selected ? format.id : null,
                  ),
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
          items: state.titles,
          columns: _columns(l10n),
          sort: sort,
          onSort: (next) => cubit.sortChanged(next.columnId, next.ascending),
          onRowTap: (title) => context.go(Routes.catalogTitle(title.id)),
          compactBuilder: (context, title) => TitleCard(
            title: title,
            onTap: () => context.go(Routes.catalogTitle(title.id)),
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
                  icon: AppIcons.book,
                  title: l10n.titlesEmptyTitle,
                  message: l10n.titlesEmptyBody,
                  // An empty catalogue still reads as empty to a role that
                  // cannot fill it; what it must not do is offer the way in.
                  actionLabel: context.canManage(StaffPermission.catalog)
                      ? l10n.titlesAdd
                      : null,
                  onAction: context.canManage(StaffPermission.catalog)
                      ? () => unawaited(_addTitle())
                      : null,
                ),
          footer: AppPagination(
            rangeLabel: l10n.commonShowingRange(
              state.totalCount == 0 ? '0' : '${start + 1}',
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
