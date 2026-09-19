// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:khulla_ui/khulla_ui.dart';

/// The doors out of a section overview, stacked into one bordered surface.
///
/// One surface with a hairline between rows, not a grid of cards: the rows
/// are alternatives to each other, and a shared frame is what says so. It is
/// also what stops an overview page from becoming three card grids in a
/// column, which is the shape that makes a tool look generated.
class NavigationGroup extends StatelessWidget {
  const NavigationGroup({required this.children, super.key});

  /// The doors, in the order they should be considered.
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) return const SizedBox.shrink();
    final colors = context.appColors;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.colorScheme.surface,
        borderRadius: BorderRadius.circular(context.appRadius.container),
        border: Border.all(color: colors.hairlineStrong),
        boxShadow: context.appShadows.card,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(context.appRadius.container),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final (index, child) in children.indexed) ...[
              if (index > 0) Divider(height: 1, color: colors.hairline),
              child,
            ],
          ],
        ),
      ),
    );
  }
}
