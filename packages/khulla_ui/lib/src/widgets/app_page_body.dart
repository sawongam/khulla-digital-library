// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:khulla_ui/src/extensions/build_context_extensions.dart';
import 'package:khulla_ui/src/theme/app_breakpoints.dart';
import 'package:khulla_ui/src/widgets/app_content_constraint.dart';

/// Standard scaffold body: [SafeArea] plus optional [AppContentConstraint].
///
/// Pass `wide: true` for dense content - a table, the dashboard - so it caps
/// at [AppBreakpoints.wideContentMaxWidth] instead of the reading width.
class AppPageBody extends StatelessWidget {
  /// {@macro app_page_body}
  const AppPageBody({
    required this.child,
    super.key,
    this.top = true,
    this.bottom = true,
    this.left = true,
    this.right = true,
    this.constrained = true,
    this.wide = false,
    this.extendBehindStatusBar = false,
  });

  /// Content rendered inside the safe area.
  final Widget child;

  /// Whether to inset the top edge (status bar).
  final bool top;

  /// Whether to inset the bottom edge (home indicator / nav bar).
  final bool bottom;

  /// Whether to inset the left edge.
  final bool left;

  /// Whether to inset the right edge.
  final bool right;

  /// When true, wraps [child] in [AppContentConstraint].
  final bool constrained;

  /// When true, the content cap is the wide one - for a table, a board, or
  /// the dashboard, which use the room a desktop window gives them. Ignored
  /// unless [constrained] is true.
  final bool wide;

  /// Paints edge-to-edge under the status bar with a transparent overlay.
  ///
  /// Pair with [pagePadding] on scroll bodies and a matching
  /// [Scaffold.backgroundColor] so the status bar matches the page canvas.
  final bool extendBehindStatusBar;

  /// Standard page padding for full-height form screens.
  ///
  /// Set [includeViewInsets] only when the parent scaffold keeps
  /// `resizeToAvoidBottomInset: false` - otherwise the scaffold already
  /// accounts for the soft keyboard and adding it again double-counts.
  static EdgeInsets pagePadding(
    BuildContext context, {
    bool extendBehindStatusBar = false,
    bool includeViewInsets = false,
  }) {
    final spacing = context.appSpacing;
    final top = extendBehindStatusBar
        ? MediaQuery.paddingOf(context).top + spacing.sm
        : spacing.sm;
    final bottom =
        spacing.xlg +
        (includeViewInsets ? MediaQuery.viewInsetsOf(context).bottom : 0);

    return EdgeInsets.fromLTRB(spacing.page, top, spacing.page, bottom);
  }

  @override
  Widget build(BuildContext context) {
    var content = child;
    if (constrained) {
      content = wide
          ? AppContentConstraint.wide(child: content)
          : AppContentConstraint(child: content);
    }

    final body = SafeArea(
      top: !extendBehindStatusBar && top,
      bottom: bottom,
      left: left,
      right: right,
      child: content,
    );

    if (!extendBehindStatusBar) {
      return body;
    }

    final pageBg = context.colorScheme.surface;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: pageBg,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: body,
    );
  }
}
