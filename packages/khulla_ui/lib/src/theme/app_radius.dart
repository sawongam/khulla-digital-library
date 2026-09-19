// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: MIT

import 'dart:ui';

import 'package:khulla_ui/khulla_ui.dart';

/// {@template app_radius}
/// The corner-radius scale, named by the *level* a shape sits at rather than
/// by its size.
///
/// The hierarchy is the point, and it is the single easiest thing to get
/// wrong: **a control is rounder than the container it sits in, and an item
/// inside a container is sharper than the container.** Buttons at 8, panels
/// and fields at 6, menu rows and tab triggers at 4. Flattening everything to
/// one value - usually 8 - is what makes an interface read as generic.
///
/// Kept separate from [AppSpacing] so radius can be tuned without moving
/// layout, even where the numbers happen to coincide.
/// {@endtemplate}
class AppRadius extends ThemeExtension<AppRadius> {
  /// {@macro app_radius}
  const AppRadius({
    this.item = 4,
    this.container = 6,
    this.control = 8,
    this.sheet = 10,
    this.pill = 999,
  });

  /// Rows nested inside a container: menu items, select options, tab
  /// triggers, the dialog close chip.
  final double item;

  /// The dominant radius. Fields, selects, table wrappers, cards, popovers,
  /// tooltips - anything that is a *surface* holding content.
  final double container;

  /// Controls: buttons, dialogs, navigation rows. Deliberately one step
  /// rounder than [container], so an action reads as sitting on top of the
  /// surface rather than being cut out of it.
  final double control;

  /// The top corners of a bottom sheet. Its own rung because it is the one
  /// shape in the system that is rounded on two corners only.
  final double sheet;

  /// Fully rounded: badges, avatars, switches, progress bars.
  /// [BorderRadius] clamps to the shortest side, so this is always a stadium.
  final double pill;

  @override
  AppRadius copyWith({
    double? item,
    double? container,
    double? control,
    double? sheet,
    double? pill,
  }) {
    return AppRadius(
      item: item ?? this.item,
      container: container ?? this.container,
      control: control ?? this.control,
      sheet: sheet ?? this.sheet,
      pill: pill ?? this.pill,
    );
  }

  @override
  AppRadius lerp(AppRadius? other, double t) {
    if (other is! AppRadius) return this;
    return AppRadius(
      item: lerpDouble(item, other.item, t)!,
      container: lerpDouble(container, other.container, t)!,
      control: lerpDouble(control, other.control, t)!,
      sheet: lerpDouble(sheet, other.sheet, t)!,
      pill: lerpDouble(pill, other.pill, t)!,
    );
  }
}
