// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: MIT

import 'package:khulla_ui/khulla_ui.dart';

/// {@template app_section_header}
/// Title, optional supporting line, and one trailing action for a section of
/// a page or the top of a card.
///
/// One action, not a row of equals: a section that needs more puts the rest
/// behind [AppMenuButton]. Takes ready-made strings - the design system does
/// not know what the section is or which locale it is in.
/// {@endtemplate}
class AppSectionHeader extends StatelessWidget {
  /// {@macro app_section_header}
  const AppSectionHeader({
    required this.title,
    this.subtitle,
    this.trailing,
    this.icon,
    this.dense = false,
    this.tone = AppStatusTone.brand,
    super.key,
  });

  /// Section heading.
  final String title;

  /// Secondary line under [title] - a count, a date range, a hint.
  final String? subtitle;

  /// The section's single action, typically an [AppButton] or
  /// [AppIconButton].
  final Widget? trailing;

  /// Glyph shown before [title]. Drawn bare: a filled chip around it would
  /// put a second surface inside the card the header already sits on, and a
  /// page of six headers each wearing one reads as decoration rather than
  /// structure.
  final AppIconSpec? icon;

  /// Uses the card heading ramp rather than the section one. Set inside a
  /// card, where the page-level size is too loud.
  final bool dense;

  /// The tone of the leading glyph.
  final AppStatusTone tone;

  @override
  Widget build(BuildContext context) {
    final spacing = context.appSpacing;
    final type = context.appTextStyles;
    final glyph = icon;
    final caption = subtitle;

    return Row(
      children: [
        if (glyph != null) ...[
          AppIcon(
            glyph,
            size: context.appMetrics.icon,
            color: tone.foreground(context),
          ),
          SizedBox(width: spacing.xs),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: (dense ? type.sectionTitle : type.title).copyWith(
                  color: context.appColors.ink100,
                ),
              ),
              if (caption != null) ...[
                SizedBox(height: spacing.xxs),
                Text(
                  caption,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: type.body.copyWith(
                    color: context.appColors.mutedForeground,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (trailing != null) ...[SizedBox(width: spacing.sm), trailing!],
      ],
    );
  }
}
