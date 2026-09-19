// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: MIT

import 'package:khulla_ui/khulla_ui.dart';

/// {@template app_content_constraint}
/// Centres [child] and caps its width.
///
/// Two caps, because Khulla has two kinds of page. Reading content - prose, a
/// form, a title's detail pane - caps at [AppBreakpoints.contentMaxWidth],
/// past which a line is too long to track. Dense content that genuinely uses
/// the room - a catalogue table, the dashboard - caps at
/// [AppBreakpoints.wideContentMaxWidth] via [AppContentConstraint.wide].
///
/// Neither stretches to the window: a form spread across a 2560px monitor is
/// a bug, not a feature. The wide variant does stretch vertically so a table
/// page can hand an [Expanded] slot the full viewport height.
/// {@endtemplate}
class AppContentConstraint extends StatelessWidget {
  /// {@macro app_content_constraint}
  const AppContentConstraint({required this.child, super.key})
    : maxWidth = null,
      wide = false;

  /// Caps at [AppBreakpoints.wideContentMaxWidth] for dense, multi-column
  /// content: tables, boards, the dashboard.
  const AppContentConstraint.wide({required this.child, super.key})
    : maxWidth = null,
      wide = true;

  /// Caps at an explicit [maxWidth]. Reach for this only when neither
  /// standard cap fits - a two-pane layout sizing its own detail pane.
  const AppContentConstraint.custom({
    required this.maxWidth,
    required this.child,
    super.key,
  }) : wide = false;

  /// Content to constrain.
  final Widget child;

  /// Explicit cap, set only by [AppContentConstraint.custom].
  final double? maxWidth;

  /// Whether to use the wide cap rather than the reading cap.
  final bool wide;

  @override
  Widget build(BuildContext context) {
    final breakpoints = context.appBreakpoints;
    final cap =
        maxWidth ??
        (wide ? breakpoints.wideContentMaxWidth : breakpoints.contentMaxWidth);

    return Align(
      alignment: Alignment.topCenter,
      widthFactor: wide ? 1 : null,
      heightFactor: wide ? 1 : null,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: cap),
        child: child,
      ),
    );
  }
}
