// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: MIT

import 'package:flutter/foundation.dart';
import 'package:solar_iconkit/solar_iconkit.dart';

/// One entry in the app's icon catalog: a glyph, named once, drawn by
/// `AppIcon`.
///
/// A spec holds the underlying icon-set identifier and nothing else the call
/// site cares about. Size and color are decided where the icon is drawn, not
/// here, so the same spec serves a 16 px chip and a 48 px empty state.
///
/// This indirection is the point: every icon in the app flows through
/// `AppIcons`, so swapping the icon set later means rewriting one file rather
/// than several hundred call sites. Nothing outside `app_icons.dart` should
/// construct an `AppIconSpec`.
@immutable
class AppIconSpec {
  /// Names a glyph by its Solar identifier.
  ///
  /// [style] defaults to [SolarIconStyle.outline], the app's single weight -
  /// see `AppIcons` for why there is only one.
  const AppIconSpec(this.name, {this.style = SolarIconStyle.outline});

  /// The Solar icon name, e.g. `'alt-arrow-right'`. Always written as a
  /// `SolarIcons` constant so a typo fails to compile.
  final String name;

  /// The weight this glyph is drawn in.
  final SolarIconStyle style;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppIconSpec && other.name == name && other.style == style;

  @override
  int get hashCode => Object.hash(name, style);

  @override
  String toString() => 'AppIconSpec($name, ${style.name})';
}
