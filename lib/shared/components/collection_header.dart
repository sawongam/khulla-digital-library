// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:khulla_ui/khulla_ui.dart';

/// The heading row above a collection's table.
///
/// The page's *name* is in the shell's top bar; this says what the table
/// below holds and offers the one action that adds to it. Secondary actions
/// go in the overflow menu rather than becoming a row of equal buttons — a
/// header with four buttons has no primary action at all.
class CollectionHeader extends StatelessWidget {
  const CollectionHeader({
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.actionIcon = AppIcons.add,
    this.onAction,
    this.menuActions = const [],
    this.menuTooltip,
    this.leading,
    this.trailing,
    super.key,
  });

  /// What the card holds.
  final String title;

  /// The count, or a line about the collection.
  final String subtitle;

  /// The one primary action. Null leaves the header read-only.
  final String? actionLabel;

  /// The glyph on the primary action.
  final AppIconSpec actionIcon;

  /// Runs the primary action.
  final VoidCallback? onAction;

  /// Secondary actions, behind the overflow menu.
  final List<AppMenuAction> menuActions;

  /// Tooltip for the overflow menu. Required for the menu to appear.
  final String? menuTooltip;

  /// A widget above the heading — a banner, a back control.
  final Widget? leading;

  /// A control between the heading and the actions — a view switch.
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final spacing = context.appSpacing;
    final colors = context.appColors;
    final label = actionLabel;
    final tooltip = menuTooltip;

    final heading = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          style: context.appTextStyles.title.copyWith(color: colors.ink100),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: context.appTextStyles.body.copyWith(
            color: colors.mutedForeground,
          ),
        ),
      ],
    );

    final actions = <Widget>[
      ?trailing,
      if (menuActions.isNotEmpty && tooltip != null)
        AppMenuButton(actions: menuActions, tooltip: tooltip),
      if (label != null)
        AppButton(
          icon: actionIcon,
          onPressed: onAction,
          child: Text(label),
        ),
    ];

    final lead = leading;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (lead != null) ...[lead, SizedBox(height: spacing.sm)],
        if (context.formFactor.isCompact) ...[
          heading,
          if (actions.isNotEmpty) ...[
            SizedBox(height: spacing.sm),
            Row(
              children: [
                for (final (index, action) in actions.indexed) ...[
                  if (index > 0) SizedBox(width: spacing.xs),
                  if (action is AppButton) Expanded(child: action) else action,
                ],
              ],
            ),
          ],
        ] else
          Row(
            children: [
              Expanded(child: heading),
              SizedBox(width: spacing.lg),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final (index, action) in actions.indexed) ...[
                    if (index > 0) SizedBox(width: spacing.xs),
                    action,
                  ],
                ],
              ),
            ],
          ),
      ],
    );
  }
}
