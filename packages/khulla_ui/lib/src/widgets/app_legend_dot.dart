// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: MIT

import 'package:khulla_ui/khulla_ui.dart';

/// One entry in a chart legend: a swatch, what it means, and optionally how
/// much of it there is.
///
/// Kept a separate widget from the charts so a legend can sit wherever the
/// layout needs it - beside a donut, under a bar chart, inside a card header
/// - instead of being trapped in the chart's own box.
class AppLegendDot extends StatelessWidget {
  const AppLegendDot({
    required this.label,
    required this.tone,
    this.value,
    this.dense = false,
    super.key,
  });

  /// What the series means.
  final String label;

  /// Which tone the swatch paints.
  final AppStatusTone tone;

  /// The series' figure, already formatted. Null shows the label alone.
  final String? value;

  /// Tightens the row for a legend inside a card header.
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final spacing = context.appSpacing;
    final colors = context.appColors;
    final figure = value;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: dense ? 8 : 10,
          height: dense ? 8 : 10,
          decoration: BoxDecoration(
            color: tone.foreground(context),
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        SizedBox(width: spacing.xs),
        Text(
          label,
          style: context.textTheme.bodySmall?.copyWith(color: colors.textMuted),
        ),
        if (figure != null) ...[
          SizedBox(width: spacing.xs),
          Text(
            figure,
            style: context.textTheme.bodySmall?.copyWith(
              color: colors.textHigh,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }
}
