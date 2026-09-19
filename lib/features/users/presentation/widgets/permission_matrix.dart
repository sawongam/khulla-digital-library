// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'dart:math';

import 'package:khulla/features/users/domain/user_role.dart';
import 'package:khulla/features/users/presentation/user_labels.dart';
import 'package:khulla/l10n/l10n.dart';
import 'package:khulla_ui/khulla_ui.dart';

/// Every permission against every role.
///
/// A grid rather than four lists, because the question an administrator asks
/// is comparative — "who else can waive a fine" — and four lists make that a
/// memory exercise. The grid scrolls horizontally on a narrow window rather
/// than dropping columns: a matrix missing a role is worse than one you have
/// to push sideways.
///
/// Three marks, not two. A permission is held at a level — a desk assistant
/// looks a book up without editing it — and a matrix that flattened that
/// back into a tick would promise access the app does not grant, or deny one
/// it does. It reads the same `rolePermissions` the router and every button
/// read, so what is shown here is what is enforced.
class PermissionMatrix extends StatelessWidget {
  const PermissionMatrix({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final spacing = context.appSpacing;
    final colors = context.appColors;
    final scheme = context.colorScheme;

    const labelWidth = 240.0;
    const roleWidth = 132.0;

    // A horizontal scroll view hands its child an unbounded width, and a
    // Column with stretch then tries to expand to infinity and crashes
    // ("BoxConstraints forces an infinite width"). Pin the column to a
    // finite width instead: the content width on a narrow window, the full
    // available width when there is room to stretch into.
    return LayoutBuilder(
      builder: (context, constraints) {
        final contentWidth =
            labelWidth + roleWidth * UserRole.values.length + spacing.sm * 2;
        final width = constraints.maxWidth.isFinite
            ? max(contentWidth, constraints.maxWidth)
            : contentWidth;
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: width,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerLow,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(context.appRadius.control),
                    ),
                  ),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: spacing.sm,
                      vertical: spacing.xs + 2,
                    ),
                    child: Row(
                      children: [
                        const SizedBox(width: labelWidth),
                        for (final role in UserRole.values)
                          SizedBox(
                            width: roleWidth,
                            child: Text(
                              role.label(l10n),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: context.appTextStyles.columnHeader
                                  .copyWith(
                                    color: colors.textMuted,
                                  ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                for (final permission in StaffPermission.values)
                  DecoratedBox(
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: colors.hairline),
                      ),
                    ),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: spacing.sm,
                        vertical: spacing.sm,
                      ),
                      child: Row(
                        children: [
                          SizedBox(
                            width: labelWidth,
                            child: Text(
                              permission.label(l10n),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: context.textTheme.bodyMedium?.copyWith(
                                color: colors.textHigh,
                              ),
                            ),
                          ),
                          for (final role in UserRole.values)
                            SizedBox(
                              width: roleWidth,
                              child: Center(
                                child: _LevelMark(
                                  level: role.levelOf(permission),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// One cell: how far a role reaches into a permission.
class _LevelMark extends StatelessWidget {
  const _LevelMark({required this.level});

  final PermissionLevel level;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.appColors;
    final size = context.appSpacing.md + 2;

    final (icon, color, label) = switch (level) {
      PermissionLevel.manage => (
        AppIcons.success,
        colors.success,
        l10n.rolesLevelManage,
      ),
      PermissionLevel.view => (
        AppIcons.preview,
        colors.textMuted,
        l10n.rolesLevelView,
      ),
      PermissionLevel.none => (
        AppIcons.remove,
        colors.hairlineStrong,
        l10n.rolesLevelNone,
      ),
    };

    // The three marks differ by glyph as well as by colour, so the grid is
    // still readable without colour vision; the tooltip names the level for
    // anyone reading it through a screen reader.
    return Tooltip(
      message: label,
      child: AppIcon(icon, size: size, color: color),
    );
  }
}
