// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: MIT

import 'dart:ui';

import 'package:khulla_ui/khulla_ui.dart';

/// {@template app_metrics}
/// Every control dimension in the system, already resolved for the ambient
/// [AppDensity].
///
/// These numbers are what make the product feel like itself - get the colors
/// perfect and the heights wrong and it still reads as a different app. A
/// 40px button next to a 44px field next to a 52px table row is the rhythm;
/// Material's defaults (48px everything) are roughly a third looser and turn
/// a dense catalogue screen into a scrolling one.
///
/// Resolved once, in the theme, so that every widget steps up together at
/// 1600px instead of each reading [MediaQuery] and drifting apart.
/// {@endtemplate}
class AppMetrics extends ThemeExtension<AppMetrics> {
  /// {@macro app_metrics}
  const AppMetrics({
    required this.density,
    required this.fieldHeight,
    required this.tableHeaderHeight,
    required this.tableRowHeight,
    required this.tableCellPaddingY,
    required this.navRowHeight,
    required this.iconNav,
    required this.labelToControlGap,
    required this.formRowGap,
    this.buttonHeightSmall = 40,
    this.buttonHeightMedium = 44,
    this.buttonHeightLarge = 48,
    this.iconButtonSmall = 35,
    this.iconButtonMedium = 40,
    this.iconButtonLarge = 44,
    this.iconDense = 12,
    this.iconInButton = 15,
    this.icon = 16,
    this.iconLarge = 20,
    this.checkbox = 16,
    this.switchTrackWidth = 32,
    this.switchTrackHeight = 16,
    this.paginationItem = 42,
    this.railExpanded = 240,
    this.railCollapsed = 64,
    this.topBarHeight = 56,
    this.dialogWidth = 576,
    this.sideSheetMaxWidth = 384,
    this.menuMinWidth = 128,
    this.rowActionMenuWidth = 192,
    this.popoverWidth = 288,
  });

  /// Builds the scale for [density].
  factory AppMetrics.of(AppDensity density) => AppMetrics(
    density: density,
    fieldHeight: density.pick(40, 44),
    tableHeaderHeight: density.pick(36, 40),
    tableRowHeight: 51.5,
    tableCellPaddingY: 12,
    navRowHeight: density.pick(42, 46),
    iconNav: density.pick(16, 20),
    labelToControlGap: density.pick(8, 12),
    formRowGap: density.pick(12, 16),
  );

  /// The rung these values were resolved at.
  final AppDensity density;

  /// Text fields, selects, pickers.
  final double fieldHeight;

  /// A table's header row.
  final double tableHeaderHeight;

  /// A table body row. One global height for every table in the app - not
  /// tied to [AppDensity] and not overridable per table.
  final double tableRowHeight;

  /// Vertical padding inside a body cell. Global, like [tableRowHeight].
  final double tableCellPaddingY;

  /// A navigation row in the rail.
  final double navRowHeight;

  /// A navigation icon.
  final double iconNav;

  /// The gap between a field's label and its control.
  final double labelToControlGap;

  /// The gap between two form rows, and between side-by-side fields.
  final double formRowGap;

  /// The default button. Smaller than Material's, on purpose.
  final double buttonHeightSmall;

  /// A button that needs more presence - a form's primary action.
  final double buttonHeightMedium;

  /// The largest button, for a page's single most important action.
  final double buttonHeightLarge;

  /// A dense square icon button, for a table row.
  final double iconButtonSmall;

  /// The everyday icon button, matching [buttonHeightSmall].
  final double iconButtonMedium;

  /// An icon button matching [buttonHeightMedium].
  final double iconButtonLarge;

  /// A dense chevron or a bullet.
  final double iconDense;

  /// The glyph inside a button - smaller than a standalone icon, so the
  /// label stays the thing being read.
  final double iconInButton;

  /// The everyday icon size: menu items, field affordances, sort chevrons.
  final double icon;

  /// A prominent icon: an empty-state glyph, a stat tile's mark.
  final double iconLarge;

  /// The checkbox and radio box.
  final double checkbox;

  /// The switch track's width.
  final double switchTrackWidth;

  /// The switch track's height.
  final double switchTrackHeight;

  /// A pagination page button.
  final double paginationItem;

  /// The navigation rail with labels showing.
  final double railExpanded;

  /// The navigation rail showing icons only.
  final double railCollapsed;

  /// The top bar, and the rail header that lines up with it.
  final double topBarHeight;

  /// The canonical dialog width.
  final double dialogWidth;

  /// The cap on a side sheet's 75% width.
  final double sideSheetMaxWidth;

  /// The narrowest a dropdown menu may be.
  final double menuMinWidth;

  /// A row-action menu, which is fixed rather than content-sized so that
  /// every row in a table drops the same panel.
  final double rowActionMenuWidth;

  /// A popover.
  final double popoverWidth;

  /// The switch thumb, inset 2px in the track.
  double get switchThumb => switchTrackHeight - 4;

  @override
  AppMetrics copyWith({AppDensity? density}) =>
      AppMetrics.of(density ?? this.density);

  @override
  AppMetrics lerp(AppMetrics? other, double t) {
    if (other is! AppMetrics) return this;
    return AppMetrics(
      density: t < 0.5 ? density : other.density,
      fieldHeight: lerpDouble(fieldHeight, other.fieldHeight, t)!,
      tableHeaderHeight: lerpDouble(
        tableHeaderHeight,
        other.tableHeaderHeight,
        t,
      )!,
      tableRowHeight: lerpDouble(tableRowHeight, other.tableRowHeight, t)!,
      tableCellPaddingY: lerpDouble(
        tableCellPaddingY,
        other.tableCellPaddingY,
        t,
      )!,
      navRowHeight: lerpDouble(navRowHeight, other.navRowHeight, t)!,
      iconNav: lerpDouble(iconNav, other.iconNav, t)!,
      labelToControlGap: lerpDouble(
        labelToControlGap,
        other.labelToControlGap,
        t,
      )!,
      formRowGap: lerpDouble(formRowGap, other.formRowGap, t)!,
    );
  }
}
