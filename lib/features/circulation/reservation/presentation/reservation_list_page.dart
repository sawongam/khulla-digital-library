// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:khulla/core/di/injection.dart';
import 'package:khulla/core/error/app_exception.dart';
import 'package:khulla/core/feedback/app_toast.dart';
import 'package:khulla/core/router/routes.dart';
import 'package:khulla/features/circulation/reservation/domain/models/reservation.dart';
import 'package:khulla/features/circulation/reservation/presentation/cubit/reservation_list_cubit.dart';
import 'package:khulla/features/circulation/reservation/presentation/cubit/reservation_list_state.dart';
import 'package:khulla/features/circulation/reservation/presentation/place_hold_dialog.dart';
import 'package:khulla/features/circulation/reservation/presentation/reservation_list_refresh.dart';
import 'package:khulla/features/circulation/shared/domain/reservation_status.dart';
import 'package:khulla/features/circulation/shared/presentation/circulation_labels.dart';
import 'package:khulla/features/users/domain/user_role.dart';
import 'package:khulla/l10n/l10n.dart';
import 'package:khulla/shared/utils/app_exception_l10n.dart';
import 'package:khulla/shared/utils/permission_context.dart';
import 'package:khulla/shared/widgets/collection_page_view.dart';
import 'package:khulla/shared/widgets/error_retry_view.dart';
import 'package:khulla_ui/khulla_ui.dart';

/// The hold queue, in the order members asked.
class ReservationListPage extends StatefulWidget {
  const ReservationListPage({super.key});

  @override
  State<ReservationListPage> createState() => _ReservationListPageState();
}

class _ReservationListPageState extends State<ReservationListPage> {
  @override
  void initState() {
    super.initState();
    getIt<ReservationListRefresh>().reload = _reload;
  }

  @override
  void dispose() {
    getIt<ReservationListRefresh>().reload = null;
    super.dispose();
  }

  void _reload() {
    if (!mounted) return;
    unawaited(context.read<ReservationListCubit>().loadReservations());
  }

  Future<void> _placeHold() async {
    final saved = await PlaceHoldDialog.show(context);
    if (saved == true && mounted) {
      await context.read<ReservationListCubit>().loadReservations();
    }
  }

  Future<void> _markReady(Reservation hold) async {
    final l10n = context.l10n;
    try {
      await context.read<ReservationListCubit>().markHoldReady(hold.id);
      if (!mounted) return;
      AppToast.success(context, message: l10n.reservationsMarkReadySuccess);
    } on AppException catch (error) {
      if (!mounted) return;
      AppToast.error(context, message: error.localizedMessage(l10n));
    }
  }

  Future<void> _cancel(Reservation hold) async {
    final l10n = context.l10n;
    final confirmed = await AppDialog.confirmDestructive(
      context: context,
      title: l10n.reservationsCancel,
      message: l10n.reservationsCancelBody,
      confirmLabel: l10n.reservationsCancel,
      cancelLabel: l10n.commonCancel,
    );
    if (!mounted || !confirmed) return;
    try {
      await context.read<ReservationListCubit>().cancelHold(hold.id);
      if (!mounted) return;
      AppToast.success(context, message: l10n.reservationsCancelSuccess);
    } on AppException catch (error) {
      if (!mounted) return;
      AppToast.error(context, message: error.localizedMessage(l10n));
    }
  }

  bool _isFiltered(ReservationListState state) =>
      state.query.search.isNotEmpty || state.query.status != null;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = context.colorScheme;
    final cubit = context.read<ReservationListCubit>();
    final muted = context.textTheme.bodyMedium?.copyWith(
      color: scheme.onSurfaceVariant,
    );
    final canWorkTheDesk = context.canManage(StaffPermission.circulation);
    final canSeeMembers = context.canView(StaffPermission.members);

    return BlocBuilder<ReservationListCubit, ReservationListState>(
      builder: (context, state) {
        if (state.hasError) {
          return ErrorRetryView(
            error: state.error,
            onRetry: cubit.loadReservations,
          );
        }

        final bootstrapping = state.isLoading && state.reservations.isEmpty;
        final isFiltered = _isFiltered(state);

        return CollectionPageView<Reservation>(
          onPageSizeChanged: cubit.limitChanged,
          summary: l10n.reservationsSubtitle,
          toolbar: AppToolbar(
            search: AppSearchField(
              hintText: l10n.reservationsSearchHint,
              clearTooltip: l10n.commonClearSearch,
              onChanged: cubit.searchChanged,
            ),
            filters: [
              for (final status in ReservationStatus.values)
                AppFilterChip(
                  label: status.label(l10n),
                  tone: status.tone,
                  selected: state.query.status == status,
                  onSelected: (selected) =>
                      cubit.statusFilterChanged(selected ? status : null),
                ),
            ],
            actions: [
              if (isFiltered)
                AppTextButton(
                  onPressed: cubit.clearFilters,
                  child: Text(l10n.commonClearFilters),
                ),
            ],
          ),
          items: state.reservations,
          onRowTap: (hold) => context.go(Routes.catalogTitle(hold.titleId)),
          compactBuilder: (context, hold) => _ReservationCard(hold: hold),
          columns: [
            AppTableColumn<Reservation>(
              id: 'queue',
              label: l10n.reservationsColumnQueue,
              cellBuilder: (context, hold) => Text(
                l10n.reservationsQueuePosition('${hold.queuePosition}'),
                style: context.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            AppTableColumn<Reservation>(
              id: 'title',
              label: l10n.reservationsColumnTitle,
              flex: 4,
              cellBuilder: (context, hold) =>
                  Text(hold.titleName ?? l10n.commonNotSet),
            ),
            AppTableColumn<Reservation>(
              id: 'member',
              label: l10n.reservationsColumnMember,
              flex: 3,
              showFrom: FormFactor.medium,
              cellBuilder: (context, hold) =>
                  Text(hold.memberName ?? l10n.commonNotSet),
            ),
            AppTableColumn<Reservation>(
              id: 'placed',
              label: l10n.reservationsColumnPlaced,
              flex: 2,
              showFrom: FormFactor.large,
              cellBuilder: (context, hold) => Text(hold.placedOn, style: muted),
            ),
            AppTableColumn<Reservation>(
              id: 'expires',
              label: l10n.reservationsColumnExpires,
              flex: 2,
              showFrom: FormFactor.expanded,
              cellBuilder: (context, hold) =>
                  Text(hold.expiresOn ?? l10n.commonNotSet, style: muted),
            ),
            AppTableColumn<Reservation>(
              id: 'status',
              label: l10n.commonStatus,
              flex: 2,
              cellBuilder: (context, hold) => AppStatusBadge(
                dense: true,
                label: hold.status.label(l10n),
                tone: hold.status.tone,
              ),
            ),
            // The queue is readable by anyone who can open circulation;
            // moving a hold along it is the desk's work.
            if (canWorkTheDesk || canSeeMembers)
              AppTableColumn<Reservation>(
                id: 'actions',
                label: l10n.commonActions,
                alignment: Alignment.centerRight,
                cellBuilder: (context, hold) => AppMenuButton(
                  tooltip: l10n.commonMoreActions,
                  actions: [
                    if (canWorkTheDesk)
                      AppMenuAction(
                        label: l10n.reservationsMarkReady,
                        icon: AppIcons.notificationsActive,
                        enabled: hold.status == ReservationStatus.waiting,
                        onSelected: () => unawaited(_markReady(hold)),
                      ),
                    if (canSeeMembers)
                      AppMenuAction(
                        label: l10n.loansViewMember,
                        icon: AppIcons.person,
                        onSelected: () =>
                            context.go(Routes.member(hold.memberId)),
                      ),
                    if (canWorkTheDesk)
                      AppMenuAction(
                        label: l10n.reservationsCancel,
                        icon: AppIcons.close,
                        isDestructive: true,
                        enabled: hold.closedAt == null,
                        onSelected: () => unawaited(_cancel(hold)),
                      ),
                  ],
                ),
              ),
          ],
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
                  icon: AppIcons.bookmark,
                  title: l10n.reservationsEmptyTitle,
                  message: l10n.reservationsEmptyBody,
                  actionLabel: canWorkTheDesk ? l10n.reservationsPlace : null,
                  onAction: canWorkTheDesk
                      ? () => unawaited(_placeHold())
                      : null,
                ),
        );
      },
    );
  }
}

class _ReservationCard extends StatelessWidget {
  const _ReservationCard({required this.hold});

  final Reservation hold;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final spacing = context.appSpacing;
    final scheme = context.colorScheme;

    return Padding(
      padding: EdgeInsets.only(bottom: spacing.sm),
      child: AppCard(
        onTap: () => context.go(Routes.catalogTitle(hold.titleId)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    hold.titleName ?? l10n.commonNotSet,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: scheme.onSurface,
                    ),
                  ),
                ),
                AppStatusBadge(
                  dense: true,
                  label: hold.status.label(l10n),
                  tone: hold.status.tone,
                ),
              ],
            ),
            SizedBox(height: spacing.xxs),
            Text(
              hold.memberName ?? l10n.commonNotSet,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            SizedBox(height: spacing.xs),
            Text(
              '${l10n.reservationsQueuePosition('${hold.queuePosition}')} · ${hold.placedOn}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
