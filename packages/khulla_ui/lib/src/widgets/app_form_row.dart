// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: MIT

import 'package:khulla_ui/khulla_ui.dart';

/// {@template app_form_row}
/// Pair up to three independent fields side by side where the slot is wide
/// enough, and stack them where it is not.
///
/// Pair only fields that are genuinely independent - *Loan period*, *Fine per
/// day* and *Grace days*, not *Address line 1* and *Address line 2*, where
/// side-by-side breaks the reading order a form depends on.
///
/// It measures its slot with [LayoutBuilder] rather than the window, so the
/// same row behaves correctly in a full-width page and in a side sheet.
/// {@endtemplate}
class AppFormRow extends StatelessWidget {
  /// {@macro app_form_row}
  const AppFormRow({
    required this.children,
    this.flexes,
    this.stackBelow,
    super.key,
  });

  /// The fields to pair, in tab order.
  final List<Widget> children;

  /// Relative widths, one per child. Null gives every field equal width.
  /// A `0` keeps that child at its intrinsic width instead of expanding.
  final List<int>? flexes;

  /// Slot width below which the fields stack. When null, derived from the
  /// child count - about 140px per field plus gaps.
  final double? stackBelow;

  @override
  Widget build(BuildContext context) {
    final spacing = context.appSpacing;
    final weights = flexes;

    assert(
      weights == null || weights.length == children.length,
      'flexes must have one entry per child.',
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final threshold =
            stackBelow ??
            (children.length <= 1
                ? 0
                : children.length * 140 + (children.length - 1) * spacing.sm);

        if (constraints.maxWidth < threshold) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final (index, field) in children.indexed) ...[
                if (index > 0) SizedBox(height: spacing.sm),
                field,
              ],
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final (index, field) in children.indexed) ...[
              if (index > 0) SizedBox(width: spacing.sm),
              switch (weights?[index] ?? 1) {
                0 => field,
                final flex => Expanded(flex: flex, child: field),
              },
            ],
          ],
        );
      },
    );
  }
}
