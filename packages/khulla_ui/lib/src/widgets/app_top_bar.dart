// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: MIT

import 'package:khulla_ui/khulla_ui.dart';

/// The bar pinned above every page in the shell.
///
/// It lives *outside* the page's scroll view, which is the whole point: the
/// page title and the section's own actions stay put while a ten-thousand-row
/// catalogue scrolls under them. A header that scrolls away is the single
/// most common complaint about dashboards built as one long column, and no
/// amount of `SliverPersistentHeader` gymnastics inside each page fixes it as
/// simply as putting the bar in the shell.
///
/// It carries **only** the current section: its name, its trail, and what you
/// can do to it. Account, search, notifications and the theme switch are
/// app-wide chrome and live at the foot of the rail instead - putting them up
/// here made the top of every screen say the same four things and left no
/// room for the one thing that differs.
///
/// Slots, in order: the leading control (a menu button on a phone), the title
/// block with its breadcrumb trail, then the section's actions. The actions
/// drop to their own row when the window cannot hold them beside the title.
class AppTopBar extends StatelessWidget {
  const AppTopBar({
    required this.title,
    this.breadcrumbs,
    this.actions = const [],
    this.leading,
    this.wrapSafeArea = true,
    super.key,
  });

  /// The page's name.
  final String title;

  /// The trail above the title. Null on a top-level section.
  final Widget? breadcrumbs;

  /// What this section can do - *Add title*, an export menu. Keep it to one
  /// primary action plus an overflow: a bar of four equal buttons has no
  /// primary action at all.
  final List<Widget> actions;

  /// A control before the title - the drawer button on a narrow window.
  final Widget? leading;

  /// Whether to wrap the bar in [SafeArea]. The shell turns this off when the
  /// bar shares a top row with the brand header and the row is wrapped once.
  final bool wrapSafeArea;

  @override
  Widget build(BuildContext context) {
    final spacing = context.appSpacing;
    final scheme = context.colorScheme;
    final colors = context.appColors;
    final crumbs = breadcrumbs;
    final lead = leading;

    final titleBlock = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: context.appTextStyles.pageHeader.copyWith(
            color: colors.ink100,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.2,
          ),
        ),
        if (crumbs != null) ...[
          const SizedBox(height: 3),
          crumbs,
        ],
      ],
    );

    // A phone's bar is a single band: title on the left, actions on the
    // right. It gets the tighter vertical inset because the bottom bar
    // already names the section - this row exists for what the section can
    // *do*, and every pixel it takes is a record the list cannot show.
    final compact = context.formFactor.isCompact;

    final bar = LayoutBuilder(
      builder: (context, constraints) {
        final stacked =
            !compact && constraints.maxWidth < 640 && actions.length > 1;

        final actionRow = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final (index, action) in actions.indexed) ...[
              if (index > 0) SizedBox(width: spacing.xs),
              action,
            ],
          ],
        );

        return Padding(
          padding: EdgeInsets.symmetric(
            horizontal: spacing.page,
            vertical: compact ? spacing.xs : spacing.sm,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  if (lead != null) ...[
                    lead,
                    SizedBox(width: spacing.xs),
                  ],
                  Expanded(child: titleBlock),
                  if (actions.isNotEmpty && !stacked) ...[
                    SizedBox(width: compact ? spacing.xs : spacing.md),
                    actionRow,
                  ],
                ],
              ),
              if (actions.isNotEmpty && stacked) ...[
                SizedBox(height: spacing.xs),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: actionRow,
                ),
              ],
            ],
          ),
        );
      },
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(bottom: BorderSide(color: colors.hairline)),
        boxShadow: context.appShadows.card,
      ),
      child: wrapSafeArea ? SafeArea(bottom: false, child: bar) : bar,
    );
  }
}
