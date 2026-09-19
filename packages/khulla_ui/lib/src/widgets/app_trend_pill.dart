// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: MIT

import 'package:khulla_ui/khulla_ui.dart';

/// The change in a figure since the period before it - `+8.2%`, `-5.6%`.
///
/// A number on its own says what the library has; a number with a delta says
/// which way it is going, which is the only reason a dashboard tile beats a
/// report. The arrow and the color come from [value]'s sign, so a caller
/// passes the measurement and not a decision about how to paint it.
///
/// [inverted] is for the figures where *down* is the good news - overdue
/// items, unpaid fines, damaged copies. Green then means "fewer", which is
/// what an operator actually wants to know.
class AppTrendPill extends StatelessWidget {
  const AppTrendPill({
    required this.label,
    required this.value,
    this.inverted = false,
    this.dense = false,
    super.key,
  });

  /// The delta as the caller wants it read - already formatted and localized
  /// (`+8.2%`, `+150`). The widget never formats a number itself.
  final String label;

  /// The delta's sign, used only to choose the arrow and the tone. Zero is
  /// neutral: a figure that did not move is not good news or bad.
  final num value;

  /// Whether a fall is the improvement.
  final bool inverted;

  /// Tightens the pill for a dense tile.
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final spacing = context.appSpacing;
    final rising = value > 0;
    final flat = value == 0;
    final good = inverted ? !rising : rising;

    final tone = flat
        ? AppStatusTone.neutral
        : (good ? AppStatusTone.success : AppStatusTone.danger);
    final foreground = tone.foreground(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: tone.background(context),
        borderRadius: BorderRadius.circular(context.appRadius.pill),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: dense ? spacing.xs - 2 : spacing.xs,
          vertical: dense ? 1 : spacing.xxs / 2,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!flat) ...[
              AppIcon(
                rising ? AppIcons.arrowUp : AppIcons.arrowDown,
                size: spacing.sm,
                color: foreground,
              ),
              const SizedBox(width: 1),
            ],
            Text(
              label,
              style: context.textTheme.labelSmall?.copyWith(
                color: foreground,
                fontWeight: FontWeight.w600,
                letterSpacing: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
