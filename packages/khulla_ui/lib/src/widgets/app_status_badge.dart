// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: MIT

import 'package:khulla_ui/khulla_ui.dart';

/// The standing pill - *Available*, *Overdue*, *Reserved*, *Active*.
///
/// A quiet tag: secondary wash, hairline, ink for the label. Hue lives on an
/// optional [icon], not on the whole pill - a table of saturated greens and
/// cyans reads as decoration, not as data.
///
/// [AppStatusTone.danger] is the exception: overdue and lost keep a red wash
/// so an alarm still interrupts the row.
///
/// It is small on purpose - 10px semibold - because a status sits *inside* a
/// table cell, next to a title, and a badge that matches the body size
/// competes with it.
class AppStatusBadge extends StatelessWidget {
  const AppStatusBadge({
    required this.label,
    this.tone = AppStatusTone.neutral,
    this.icon,
    this.dense = false,
    super.key,
  });

  /// The standing, already localized.
  final String label;

  /// Which meaning to paint.
  final AppStatusTone tone;

  /// Optional leading glyph, where one says more than the label alone.
  final AppIconSpec? icon;

  /// Tightens the pill for use inside a table row.
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final spacing = context.appSpacing;
    final colors = context.appColors;
    final alarm = tone == AppStatusTone.danger;
    final mark = tone.foreground(context);
    final labelColor = alarm ? mark : colors.ink200;
    final glyph = icon;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: alarm ? tone.background(context) : colors.secondary,
        borderRadius: BorderRadius.circular(context.appRadius.pill),
        border: Border.all(
          color: alarm ? tone.border(context) : colors.hairline,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: dense ? spacing.xs : spacing.sm - 2,
          vertical: dense ? 1 : spacing.xxs / 2,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (glyph != null) ...[
              AppIcon(
                glyph,
                size: context.appMetrics.iconDense,
                color: mark,
              ),
              SizedBox(width: spacing.xxs),
            ],
            // Flexible, not bare: a badge is routinely dropped into a fixed
            // -width table column, and a min-size Row would overflow rather
            // than let the label ellipsise.
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.appTextStyles.micro.copyWith(
                  color: labelColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
