// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: MIT

import 'package:flutter/widgets.dart';
import 'package:khulla_ui/src/icons/app_icon_spec.dart';
import 'package:solar_iconkit/solar_iconkit.dart';

/// Renders an [AppIconSpec].
///
/// This is the app's only icon widget. It is a thin wrapper over `SolarIcon`
/// that always draws in the spec's weight - the app uses one. A call site
/// names *which* icon and nothing else; selection and active state are
/// carried by [color], never by a heavier glyph. See `AppIcons`.
///
/// Like Material's `Icon`, an unset [size] or [color] resolves from the
/// ambient `IconTheme`, so icons inside a button, an app bar or a `ListTile`
/// pick up the surrounding styling with no arguments.
class AppIcon extends StatelessWidget {
  /// Draws [spec].
  const AppIcon(
    this.spec, {
    super.key,
    this.size,
    this.color,
    this.semanticLabel,
    this.matchTextDirection = false,
  });

  /// Which icon to draw. Always an `AppIcons` constant.
  final AppIconSpec spec;

  /// Width and height in logical pixels. Falls back to `IconTheme.size`, then
  /// to 24.
  final double? size;

  /// Stroke color. Falls back to `IconTheme.color`.
  final Color? color;

  /// Read aloud by a screen reader. Leave null for a decorative icon that sits
  /// beside its own label - the label is already announced.
  final String? semanticLabel;

  /// Mirror the glyph in a right-to-left locale. True for the directional
  /// icons - chevrons, arrows, the back button - false for everything else.
  final bool matchTextDirection;

  @override
  Widget build(BuildContext context) {
    return SolarIcon(
      spec.name,
      style: spec.style,
      size: size,
      color: color,
      semanticLabel: semanticLabel,
      matchTextDirection: matchTextDirection,
    );
  }
}
