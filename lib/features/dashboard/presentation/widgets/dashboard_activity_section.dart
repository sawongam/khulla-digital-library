// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:go_router/go_router.dart';
import 'package:khulla/core/router/routes.dart';
import 'package:khulla/features/dashboard/presentation/models/dashboard_activity_entry.dart';
import 'package:khulla/features/dashboard/presentation/widgets/dashboard_section_card.dart';
import 'package:khulla/l10n/l10n.dart';
import 'package:khulla_ui/khulla_ui.dart';

/// The last few things that happened at the desk.
///
/// A short, bounded [AppTable] rather than a sliver one: this list is six
/// rows by definition, and the page's scroll view already owns the scrolling.
/// When circulation has a table behind it, the rows come from a query and
/// the four screen states arrive with it - the layout does not change.
class DashboardActivitySection extends StatelessWidget {
  const DashboardActivitySection({required this.entries, super.key});

  /// The last few things that happened at the desk, most recent first.
  final List<DashboardActivityEntry> entries;

  List<AppTableColumn<DashboardActivityEntry>> _columns(
    BuildContext context,
    AppLocalizations l10n,
  ) {
    final spacing = context.appSpacing;
    final colors = context.appColors;

    return [
      AppTableColumn<DashboardActivityEntry>(
        id: 'item',
        label: l10n.dashboardActivityColumnItem,
        flex: 4,
        cellBuilder: (context, entry) => Text(
          entry.item,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: context.textTheme.bodyMedium?.copyWith(
            color: colors.textHigh,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      AppTableColumn<DashboardActivityEntry>(
        id: 'member',
        label: l10n.dashboardActivityColumnMember,
        flex: 4,
        showFrom: FormFactor.medium,
        cellBuilder: (context, entry) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppAvatar(initials: entry.memberInitials, size: 24),
            SizedBox(width: spacing.xs),
            Flexible(
              child: Text(
                entry.member,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      ),
      AppTableColumn<DashboardActivityEntry>(
        id: 'when',
        label: l10n.dashboardActivityColumnWhen,
        flex: 3,
        showFrom: FormFactor.expanded,
        cellBuilder: (context, entry) => Text(
          entry.when,
          style: context.textTheme.bodySmall?.copyWith(color: colors.textMuted),
        ),
      ),
      AppTableColumn<DashboardActivityEntry>(
        id: 'due',
        label: l10n.dashboardActivityColumnDue,
        flex: 2,
        showFrom: FormFactor.large,
        cellBuilder: (context, entry) => Text(
          entry.due ?? l10n.commonUnavailable,
          style: context.textTheme.bodySmall?.copyWith(color: colors.textMuted),
        ),
      ),
      AppTableColumn<DashboardActivityEntry>(
        id: 'action',
        label: l10n.dashboardActivityColumnAction,
        width: 132,
        alignment: Alignment.centerRight,
        cellBuilder: (context, entry) => AppStatusBadge(
          dense: true,
          tone: entry.tone,
          label: switch (entry.kind) {
            DashboardActivityKind.borrow => l10n.dashboardActivityBorrow,
            DashboardActivityKind.returned => l10n.dashboardActivityReturn,
            DashboardActivityKind.reserved => l10n.dashboardActivityReserve,
            DashboardActivityKind.fine => l10n.dashboardActivityFine,
          },
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return DashboardSectionCard(
      title: l10n.dashboardActivityTitle,
      subtitle: l10n.dashboardActivitySubtitle,
      trailing: AppTextButton(
        onPressed: () => context.go(Routes.circulation),
        child: Text(l10n.commonViewAll),
      ),
      child: entries.isEmpty
          ? AppEmptyView(
              icon: AppIcons.transfer,
              title: l10n.dashboardActivityEmptyTitle,
              message: l10n.dashboardActivityEmptyBody,
            )
          : AppTable<DashboardActivityEntry>(
              items: entries,
              columns: _columns(context, l10n),
              onRowTap: (_) => context.go(Routes.circulation),
              compactBuilder: (context, entry) => _ActivityCard(entry: entry),
            ),
    );
  }
}

/// One activity row as a card, for a window too narrow for the table.
class _ActivityCard extends StatelessWidget {
  const _ActivityCard({required this.entry});

  final DashboardActivityEntry entry;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final spacing = context.appSpacing;
    final colors = context.appColors;

    return Padding(
      padding: EdgeInsets.only(bottom: spacing.xs),
      child: Row(
        children: [
          AppAvatar(initials: entry.memberInitials, size: 34),
          SizedBox(width: spacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  entry.item,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.textTheme.bodyMedium?.copyWith(
                    color: colors.textHigh,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '${entry.member} · ${entry.when}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.textTheme.bodySmall?.copyWith(
                    color: colors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: spacing.xs),
          AppStatusBadge(
            dense: true,
            tone: entry.tone,
            label: switch (entry.kind) {
              DashboardActivityKind.borrow => l10n.dashboardActivityBorrow,
              DashboardActivityKind.returned => l10n.dashboardActivityReturn,
              DashboardActivityKind.reserved => l10n.dashboardActivityReserve,
              DashboardActivityKind.fine => l10n.dashboardActivityFine,
            },
          ),
        ],
      ),
    );
  }
}
