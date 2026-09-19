// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:khulla/features/users/domain/user_role.dart';
import 'package:khulla/features/users/presentation/cubit/staff_list_cubit.dart';
import 'package:khulla/features/users/presentation/cubit/staff_list_state.dart';
import 'package:khulla/features/users/presentation/user_labels.dart';
import 'package:khulla/features/users/presentation/widgets/permission_matrix.dart';
import 'package:khulla/l10n/l10n.dart';
import 'package:khulla/shared/components/section_card.dart';
import 'package:khulla_ui/khulla_ui.dart';

/// What each role is allowed to do.
///
/// Four fixed roles rather than a role builder: a library desk has four jobs,
/// and a screen that lets an administrator invent a fifth mostly produces a
/// role called "Librarian 2" whose permissions nobody can remember. The
/// matrix below is the whole model, on one screen, with no scrolling between
/// a role and the permission being read — there is no "add role" action for
/// the same reason: a custom role is a feature request, not a default.
class RoleListPage extends StatelessWidget {
  const RoleListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final spacing = context.appSpacing;

    return BlocBuilder<StaffListCubit, StaffListState>(
      builder: (context, state) {
        final counts = <UserRole, int>{
          for (final role in UserRole.values)
            role: state.staff.where((staff) => staff.role == role).length,
        };

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
                    AppResponsiveGrid(
                      children: [
                        for (final role in UserRole.values)
                          _RoleCard(role: role, people: counts[role] ?? 0),
                      ],
                    ),
                    SizedBox(height: spacing.lg),
                    SectionCard(
                      title: l10n.rolesMatrixTitle,
                      subtitle: l10n.rolesLegend,
                      child: const PermissionMatrix(),
                    ),
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

/// One role, its people, and what it can reach.
class _RoleCard extends StatelessWidget {
  const _RoleCard({required this.role, required this.people});

  final UserRole role;
  final int people;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final spacing = context.appSpacing;
    final colors = context.appColors;
    // Anything the role can open counts, at either level — the card is a
    // reach-at-a-glance, and the matrix below it says how far.
    final granted = StaffPermission.values.where(role.canView).length;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              AppIcon(
                role.icon,
                size: spacing.lg - 4,
                color: role.tone.foreground(context),
              ),
              SizedBox(width: spacing.sm),
              Expanded(
                child: Text(
                  role.label(l10n),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.textTheme.titleSmall?.copyWith(
                    color: colors.textHigh,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: spacing.sm),
          Text(
            role.description(l10n),
            maxLines: 3,
            style: context.textTheme.bodySmall?.copyWith(
              color: colors.textMuted,
              height: 1.4,
            ),
          ),
          SizedBox(height: spacing.sm),
          Row(
            children: [
              AppStatusBadge(
                dense: true,
                label: l10n.rolesPeopleCount('$people'),
              ),
              SizedBox(width: spacing.xs),
              Flexible(
                child: Text(
                  l10n.rolesPermissionCount(
                    '$granted',
                    '${StaffPermission.values.length}',
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.textTheme.bodySmall?.copyWith(
                    color: colors.textMuted,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
