// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: MIT

import 'package:khulla_ui/khulla_ui.dart';

/// The floating panel chrome shared by [AppDialog] and [AppFormModal].
///
/// The close chip hangs off the top-right corner, so it must be a **sibling**
/// of the panel - not a child overflowing the [Dialog]'s [Material]. A child
/// that crosses a shaped Material is composited against the scrim and reads
/// as translucent.
class AppDialogShell extends StatelessWidget {
  /// Creates the panel chrome.
  const AppDialogShell({
    required this.child,
    required this.maxWidth,
    this.showClose = true,
    super.key,
  });

  /// The dialog body. Sized by the child, capped at [maxWidth] and 90% of
  /// the viewport height.
  final Widget child;

  /// The panel's width cap, in logical pixels.
  final double maxWidth;

  /// Whether to draw the close chip. Hide it for a step the operator must
  /// answer rather than dismiss.
  final bool showClose;

  @override
  Widget build(BuildContext context) {
    final spacing = context.appSpacing;
    final colors = context.appColors;
    final scheme = context.colorScheme;
    final maxHeight = MediaQuery.sizeOf(context).height * 0.9;
    final chipHang = spacing.xs;
    final chipHangEnd = spacing.xs + 2;
    final panelShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(context.appRadius.control),
      side: BorderSide(color: colors.hairline),
    );

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      shadowColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      clipBehavior: Clip.none,
      insetPadding: EdgeInsets.all(spacing.lg),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(context.appRadius.control),
      ),
      child: Padding(
        padding: showClose
            ? EdgeInsets.only(top: chipHang, right: chipHangEnd)
            : EdgeInsets.zero,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Material(
              color: scheme.surface,
              shadowColor: Colors.transparent,
              surfaceTintColor: Colors.transparent,
              shape: panelShape,
              clipBehavior: Clip.antiAlias,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: maxWidth,
                  maxHeight: maxHeight,
                ),
                child: child,
              ),
            ),
            if (showClose)
              Positioned(
                top: -chipHang,
                right: -chipHangEnd,
                child: AppDialogCloseChip(
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
