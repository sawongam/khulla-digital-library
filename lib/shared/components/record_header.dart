// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:khulla_ui/khulla_ui.dart';

/// The identity block at the top of a record's detail screen.
///
/// It does not draw a card. The record *is* the page, so boxing its name
/// makes it one panel among the panels below it and leaves the screen with no
/// focal point; on the canvas, under the hairline that closes it, the name is
/// unmistakably what everything beneath is about.
///
/// The split between [facts] and [badges] is the other half of the fix. A
/// badge is a standing - *Overdue*, *Suspended*, *Reference only* - and it
/// earns its color and its pill. A lifespan, a card number, a format or a
/// copy count is a fact, and rendering it as a badge spends the same emphasis
/// on something nobody needs to react to. Facts go in one muted line;
/// badges stay a short row of real statuses.
class RecordHeader extends StatelessWidget {
  const RecordHeader({
    required this.title,
    required this.actions,
    this.subtitle,
    this.initials,
    this.leading,
    this.facts = const [],
    this.badges = const [],
    this.note,
    super.key,
  });

  /// The record's name - the page's focal point.
  final String title;

  /// The line under the name: a subtitle, an author, a role.
  final Widget? subtitle;

  /// Initials for the leading avatar. Null draws no avatar - a book has no
  /// face, and a two-letter circle beside a title is decoration.
  final String? initials;

  /// A control before the identity block - typically a back chevron on a
  /// detail screen the operator drilled into from a list.
  final Widget? leading;

  /// Identifying facts, already formatted and localized, joined into one
  /// muted line.
  final List<String> facts;

  /// Standings worth reacting to. Keep it short; four pills is a toolbar.
  final List<Widget> badges;

  /// A free line under the block - a member's note, a shelving remark.
  final String? note;

  /// The record's actions: the primary control, and an overflow menu.
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final spacing = context.appSpacing;
    final colors = context.appColors;
    final avatar = initials;
    final caption = subtitle;
    final remark = note;
    final back = leading;

    final identity = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          style: context.appTextStyles.pageHeader.copyWith(
            color: colors.ink100,
          ),
        ),
        if (caption != null) ...[SizedBox(height: spacing.xxs), caption],
        if (facts.isNotEmpty) ...[
          SizedBox(height: spacing.xs),
          Text(
            facts.join('  ·  '),
            style: context.appTextStyles.body.copyWith(
              color: colors.mutedForeground,
            ),
          ),
        ],
        if (badges.isNotEmpty) ...[
          SizedBox(height: spacing.sm),
          Wrap(spacing: spacing.xs, runSpacing: spacing.xs, children: badges),
        ],
        if (remark != null) ...[
          SizedBox(height: spacing.sm),
          Text(
            remark,
            style: context.textTheme.bodySmall?.copyWith(
              color: colors.textMuted,
              height: 1.4,
            ),
          ),
        ],
      ],
    );

    final lead = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (back != null) ...[back, SizedBox(width: spacing.sm)],
        if (avatar != null) ...[
          AppAvatar(initials: avatar, size: 52),
          SizedBox(width: spacing.md),
        ],
        Expanded(child: identity),
      ],
    );

    final compact = context.formFactor.isCompact;

    // A bare Row gives a non-flex child unbounded main-axis width, so a
    // Wrap inside one never actually wraps - it has to sit where its own
    // parent already bounds its width (Column's cross axis, or a Flexible
    // inside the wide Row below), or a long action label overflows a phone.
    final actionsRow = Wrap(
      alignment: WrapAlignment.end,
      spacing: spacing.xs,
      runSpacing: spacing.xs,
      children: actions,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (compact) ...[
          lead,
          if (actions.isNotEmpty) ...[
            SizedBox(height: spacing.md),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: actionsRow,
            ),
          ],
        ] else
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: lead),
              if (actions.isNotEmpty) ...[
                SizedBox(width: spacing.lg),
                // Intrinsic width only - a [Flexible] here would share the
                // row with [Expanded] and park the buttons in the middle.
                actionsRow,
              ],
            ],
          ),
        SizedBox(height: spacing.md),
        Divider(height: 1, color: colors.hairlineStrong),
      ],
    );
  }
}
