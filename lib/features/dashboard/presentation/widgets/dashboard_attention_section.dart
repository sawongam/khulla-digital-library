// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:go_router/go_router.dart';
import 'package:khulla/features/dashboard/presentation/models/dashboard_attention_item.dart';
import 'package:khulla/features/dashboard/presentation/widgets/dashboard_section_card.dart';
import 'package:khulla/l10n/l10n.dart';
import 'package:khulla/shared/components/navigation_group.dart';
import 'package:khulla_ui/khulla_ui.dart';

/// Overdue loans, unfilled holds, memberships lapsing, copies reported lost.
///
/// The counterpart to the activity table: that one is what happened, this one
/// is what somebody still has to do. Every row opens the screen that clears
/// it, so the panel is a worklist rather than a worry list.
class DashboardAttentionSection extends StatelessWidget {
  const DashboardAttentionSection({required this.items, super.key});

  final List<DashboardAttentionItem> items;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return DashboardSectionCard(
      framed: false,
      title: l10n.dashboardAttentionTitle,
      subtitle: l10n.dashboardAttentionSubtitle,
      child: items.isEmpty
          ? AppEmptyView(
              icon: AppIcons.success,
              title: l10n.dashboardAttentionEmptyTitle,
              message: l10n.dashboardAttentionEmptyBody,
            )
          : NavigationGroup(
              children: [
                for (final item in items) _AttentionRow(item: item),
              ],
            ),
    );
  }
}

class _AttentionRow extends StatelessWidget {
  const _AttentionRow({required this.item});

  final DashboardAttentionItem item;

  @override
  Widget build(BuildContext context) {
    final spacing = context.appSpacing;
    final colors = context.appColors;

    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: () => context.go(item.route),
        focusColor: context.colorScheme.primary.withValues(alpha: 0.06),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: spacing.md,
            vertical: spacing.sm,
          ),
          child: Row(
            children: [
              AppIcon(
                item.icon,
                size: spacing.md + 2,
                color: item.tone.foreground(context),
              ),
              SizedBox(width: spacing.sm),
              Expanded(
                child: Text(
                  item.label,
                  maxLines: 2,
                  style: context.textTheme.bodyMedium?.copyWith(
                    color: colors.textHigh,
                  ),
                ),
              ),
              SizedBox(width: spacing.xs),
              Text(
                item.count,
                style: context.textTheme.titleSmall?.copyWith(
                  color: item.tone.foreground(context),
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(width: spacing.xxs),
              AppIcon(
                AppIcons.chevronRight,
                size: spacing.md + 2,
                color: colors.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
