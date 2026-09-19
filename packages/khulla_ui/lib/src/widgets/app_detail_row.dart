// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: MIT

import 'package:khulla_ui/khulla_ui.dart';

/// {@template app_detail_row}
/// One label/value pair in a detail pane - *ISBN*, *Shelf*, *Member since*.
///
/// Side by side where there is room, stacked below [FormFactor.medium], so a
/// long value never squeezes its label to two characters on a phone. It reads
/// its slot with [LayoutBuilder] rather than the window, because the same row
/// appears in a full-width pane and in a half-width card.
/// {@endtemplate}
class AppDetailRow extends StatelessWidget {
  /// {@macro app_detail_row}
  const AppDetailRow({
    required this.label,
    required this.child,
    this.labelWidth = 160,
    this.stackBelow = 420,
    super.key,
  });

  /// Builds a row whose value is plain text, the common case.
  factory AppDetailRow.text({
    required String label,
    required String value,
    Key? key,
  }) => AppDetailRow(
    label: label,
    key: key,
    child: _DetailValueText(value: value),
  );

  /// What the value is.
  final String label;

  /// The value itself - text, a badge, a link row.
  final Widget child;

  /// Width reserved for [label] in the side-by-side layout.
  final double labelWidth;

  /// Slot width below which the pair stacks instead.
  final double stackBelow;

  @override
  Widget build(BuildContext context) {
    final spacing = context.appSpacing;
    final labelText = Text(
      label,
      style: context.textTheme.bodySmall?.copyWith(
        color: context.colorScheme.onSurfaceVariant,
      ),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < stackBelow) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              labelText,
              SizedBox(height: spacing.xxs),
              child,
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: labelWidth, child: labelText),
            SizedBox(width: spacing.sm),
            Expanded(child: child),
          ],
        );
      },
    );
  }
}

class _DetailValueText extends StatelessWidget {
  const _DetailValueText({required this.value});

  final String value;

  @override
  Widget build(BuildContext context) {
    return Text(
      value,
      style: context.textTheme.bodyMedium?.copyWith(
        color: context.colorScheme.onSurface,
      ),
    );
  }
}
