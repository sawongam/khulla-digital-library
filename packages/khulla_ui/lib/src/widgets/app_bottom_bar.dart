// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: MIT

import 'package:khulla_ui/khulla_ui.dart';

/// {@template app_bottom_bar}
/// The action bar pinned under a full-page form.
///
/// A long settings form scrolls; its *Save* must not. Put the bar beside the
/// scroll view, not inside it - `Column(children: [Expanded(scroll), bar])` -
/// so the primary action stays on screen however far down the fields go.
///
/// Actions are trailing-aligned and dismiss-first, the same order as the
/// footer of an [AppFormModal]. A 1px hairline carries the edge, not a shadow.
/// {@endtemplate}
class AppBottomBar extends StatelessWidget {
  /// {@macro app_bottom_bar}
  const AppBottomBar({required this.children, super.key});

  /// The buttons, dismiss-first.
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final spacing = context.appSpacing;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.colorScheme.surface,
        border: Border(top: BorderSide(color: context.appColors.hairline)),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: spacing.page,
          vertical: spacing.sm,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            for (final (index, child) in children.indexed) ...[
              if (index > 0) SizedBox(width: spacing.sm),
              child,
            ],
          ],
        ),
      ),
    );
  }
}
