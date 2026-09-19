// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: MIT

import 'package:khulla_ui/khulla_ui.dart';

/// {@template app_text_styles}
/// The type scale, resolved for the ambient [AppDensity].
///
/// Every size in this system is a **pair**: a base value and a value one step
/// up, taken at 1600px. 12→14 for body, 18→22 for a page header, 10→12 for a
/// badge. Sizes are never written alone, and there are no intermediate rungs
/// - a screen either reads at the base rung or at the wide one, and the whole
/// screen moves together.
///
/// The scale is deliberately small. 12px body and 10px badges are what let a
/// catalogue put forty rows on screen; a 14px "comfortable" default would
/// halve that. Because of it, text scaling is clamped app-side rather than
/// left unbounded.
///
/// Only four weights are used: 400 for body and table values, 500 for
/// interactive text (buttons, labels, tabs, titles), 600 for column headers
/// and badges, 700 for an empty state's heading and nothing else.
/// {@endtemplate}
class AppTextStyles extends ThemeExtension<AppTextStyles> {
  /// {@macro app_text_styles}
  const AppTextStyles({this.density = AppDensity.comfortable});

  /// The rung these styles were resolved at.
  final AppDensity density;

  /// Body copy, table cells, field text - the default everything falls to.
  TextStyle get body => _style(density.pick(12, 14), FontWeight.w400);

  /// Counts, money, and other figures that must not jitter as digits change.
  TextStyle get numeric => body.copyWith(
    fontFeatures: const [FontFeature.tabularFigures()],
  );

  /// Secondary body: navigation labels, section prose, tooltips.
  TextStyle get bodyLarge => _style(density.pick(14, 16), FontWeight.w400);

  /// Fine print: a caption, a helper line, a timestamp.
  TextStyle get caption => _style(density.pick(11, 12), FontWeight.w400);

  /// Badges and field error messages. The smallest type in the system.
  TextStyle get micro => _style(density.pick(10, 12), FontWeight.w500);

  /// Field labels, menu items, tab labels - interactive text at body size.
  TextStyle get label => _style(density.pick(12, 14), FontWeight.w500);

  /// Button labels.
  TextStyle get button => _style(14, FontWeight.w500);

  /// Table column headers.
  TextStyle get columnHeader => _style(density.pick(12, 14), FontWeight.w600);

  /// A subsection heading inside a card or a form.
  TextStyle get sectionTitle => _style(density.pick(14, 16), FontWeight.w600);

  /// A dialog title, a sheet title, an empty state's heading.
  TextStyle get title =>
      _style(density.pick(18, 20), FontWeight.w500, tight: true);

  /// The page header. One rung wider than [title] at the wide density,
  /// because a page title has the room a dialog's does not.
  TextStyle get pageHeader =>
      _style(density.pick(18, 22), FontWeight.w500, tight: true);

  /// A form dialog's title - the same rung as [title], one step heavier so it
  /// reads above section headings without jumping to [displaySmall].
  TextStyle get formTitle =>
      _style(density.pick(18, 20), FontWeight.w600, tight: true);

  /// A card primitive's title, and a stat tile's figure.
  TextStyle get displaySmall => _style(24, FontWeight.w600, tight: true);

  /// A sheet's form title - the largest type the product uses.
  TextStyle get displayMedium => _style(30, FontWeight.w500, tight: true);

  /// Builds the Material [TextTheme] these styles back.
  ///
  /// The mapping is deliberate rather than mechanical: `bodyMedium` is the
  /// 12/14 default because it is what a bare [Text] resolves to, and
  /// `labelSmall` is the badge rung because that is what badges reach for.
  TextTheme get textTheme => TextTheme(
    displayLarge: _style(36, FontWeight.w700, tight: true),
    displayMedium: displayMedium,
    displaySmall: displaySmall,
    headlineLarge: displayMedium,
    headlineMedium: displaySmall,
    headlineSmall: formTitle,
    titleLarge: pageHeader,
    titleMedium: title,
    titleSmall: sectionTitle,
    bodyLarge: bodyLarge,
    bodyMedium: body,
    bodySmall: caption,
    labelLarge: button,
    labelMedium: label,
    labelSmall: micro.copyWith(fontWeight: FontWeight.w600),
  );

  /// Line height is 1.5 for reading and 1.2 for titles, which also take a
  /// little negative tracking - at 18px and up, default spacing reads loose.
  static TextStyle _style(
    double size,
    FontWeight weight, {
    bool tight = false,
  }) => TextStyle(
    fontSize: size,
    fontWeight: weight,
    height: tight ? 1.2 : 1.5,
    letterSpacing: tight ? -0.4 : 0,
  );

  @override
  AppTextStyles copyWith({AppDensity? density}) =>
      AppTextStyles(density: density ?? this.density);

  @override
  AppTextStyles lerp(AppTextStyles? other, double t) =>
      other is AppTextStyles && t >= 0.5 ? other : this;
}
