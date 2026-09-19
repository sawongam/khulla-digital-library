// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: MIT

import 'dart:ui';

import 'package:khulla_ui/khulla_ui.dart';

/// {@template app_borders}
/// Border widths, and the dashed stroke.
///
/// There is one border width in this design - 1px - and structure comes from
/// using it everywhere rather than from varying it. The two exceptions are
/// real: a checkbox needs 1.5px to read at 16px square, and a dashed drop
/// zone needs 2px to hold a visible rhythm.
/// {@endtemplate}
class AppBorders extends ThemeExtension<AppBorders> {
  /// {@macro app_borders}
  const AppBorders({
    this.hairline = 1,
    this.checkbox = 1.5,
    this.dashedStroke = 2,
    this.dashOn = 6,
    this.dashOff = 6,
  });

  /// Every border in the system.
  final double hairline;

  /// The checkbox box, which needs the extra half pixel at 16px square.
  final double checkbox;

  /// The dashed stroke on a filter chip or a drop zone.
  final double dashedStroke;

  /// The painted length of one dash.
  final double dashOn;

  /// The gap between two dashes.
  final double dashOff;

  @override
  AppBorders copyWith({
    double? hairline,
    double? checkbox,
    double? dashedStroke,
    double? dashOn,
    double? dashOff,
  }) {
    return AppBorders(
      hairline: hairline ?? this.hairline,
      checkbox: checkbox ?? this.checkbox,
      dashedStroke: dashedStroke ?? this.dashedStroke,
      dashOn: dashOn ?? this.dashOn,
      dashOff: dashOff ?? this.dashOff,
    );
  }

  @override
  AppBorders lerp(AppBorders? other, double t) {
    if (other is! AppBorders) return this;
    return AppBorders(
      hairline: lerpDouble(hairline, other.hairline, t)!,
      checkbox: lerpDouble(checkbox, other.checkbox, t)!,
      dashedStroke: lerpDouble(dashedStroke, other.dashedStroke, t)!,
      dashOn: lerpDouble(dashOn, other.dashOn, t)!,
      dashOff: lerpDouble(dashOff, other.dashOff, t)!,
    );
  }
}
