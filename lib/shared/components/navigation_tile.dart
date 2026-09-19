// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:go_router/go_router.dart';
import 'package:khulla_ui/khulla_ui.dart';

/// One door from a section's overview into a list behind it, as a row.
///
/// A row rather than a card: a section overview offers a handful of doors
/// that differ only in destination, and rendering each as its own floating
/// surface makes five equal choices look like five unrelated features. Stack
/// them in a `NavigationGroup` and the hairline between rows does the work a
/// border around each one was doing badly.
///
/// The count is the reason a door is a row and not a nav item - it is what a
/// librarian reads before deciding which list to open.
class NavigationTile extends StatelessWidget {
  const NavigationTile({
    required this.label,
    required this.description,
    required this.icon,
    required this.route,
    this.count,
    super.key,
  });

  /// What is behind the door.
  final String label;

  /// A line explaining what is behind the door.
  final String description;

  /// How many records are in it, already formatted. Null hides the figure -
  /// a door into a desk flow is not counting anything.
  final String? count;

  /// Glyph identifying the destination, drawn bare.
  final AppIconSpec icon;

  /// Where the tile leads.
  final String route;

  @override
  Widget build(BuildContext context) {
    final spacing = context.appSpacing;
    final colors = context.appColors;

    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: () => context.go(route),
        focusColor: context.colorScheme.primary.withValues(alpha: 0.06),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: spacing.md,
            vertical: spacing.sm,
          ),
          child: Row(
            children: [
              AppIcon(icon, size: spacing.lg - 4, color: colors.textMuted),
              SizedBox(width: spacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: colors.textHigh,
                      ),
                    ),
                    Text(
                      description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: context.textTheme.bodySmall?.copyWith(
                        color: colors.textMuted,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              if (count case final figure?) ...[
                SizedBox(width: spacing.sm),
                Text(
                  figure,
                  style: context.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colors.textHigh,
                  ),
                ),
              ],
              SizedBox(width: spacing.xs),
              AppIcon(
                AppIcons.chevronRight,
                size: spacing.lg - 6,
                color: colors.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
