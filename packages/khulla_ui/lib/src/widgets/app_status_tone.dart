// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: MIT

import 'package:khulla_ui/khulla_ui.dart';

/// The standing of a record, as the six tones the product recognises.
///
/// A tone is a *meaning*, not a color: `success` is "this is settled" whether
/// it paints a returned loan, an available copy or an active member. Widgets
/// take a tone and resolve the ink, the wash and the border from the theme, so
/// a badge, a stat tile and a chart series with the same meaning match without
/// anyone passing a color.
enum AppStatusTone {
  /// No standing of its own - a count, an inert tag, a disabled row.
  neutral,

  /// Settled: returned on time, available, active.
  success,

  /// Needs an eye soon: due today, last copy out, membership expiring.
  warning,

  /// In flight: reserved, on hold, queued, imported.
  info,

  /// Wrong now: overdue, lost, suspended, destructive.
  danger,

  /// The brand accent - the primary action, the selected thing.
  brand,
}

/// Resolves a tone into the three colors a component paints with.
extension AppStatusToneColors on AppStatusTone {
  /// The ink: label text, glyph, the chart series' fill.
  Color foreground(BuildContext context) {
    final colors = context.appColors;
    return switch (this) {
      AppStatusTone.neutral => colors.ink500,
      AppStatusTone.success => colors.success,
      AppStatusTone.warning => colors.warning,
      AppStatusTone.info => colors.info,
      AppStatusTone.danger => colors.danger,
      AppStatusTone.brand => colors.brand,
    };
  }

  /// The wash a badge, an avatar or an icon chip sits on.
  ///
  /// Hand-picked per brightness rather than blended from [foreground] - a
  /// blend that reads as a soft tint on white turns muddy on a dark canvas.
  Color background(BuildContext context) {
    final colors = context.appColors;
    return switch (this) {
      AppStatusTone.neutral => colors.neutralSoft,
      AppStatusTone.success => colors.successSoft,
      AppStatusTone.warning => colors.warningSoft,
      AppStatusTone.info => colors.infoSoft,
      AppStatusTone.danger => colors.dangerSoft,
      AppStatusTone.brand => colors.brandSoft,
    };
  }

  /// The hairline around a badge. Derived from [foreground] rather than
  /// hand-picked, so a new tone cannot arrive with a border that does not
  /// belong to its hue.
  Color border(BuildContext context) =>
      foreground(context).withValues(alpha: 0.2);

  /// Content that sits on a *solid* [foreground] fill.
  Color onSolid(BuildContext context) {
    final colors = context.appColors;
    return switch (this) {
      AppStatusTone.neutral => context.colorScheme.surface,
      AppStatusTone.success => colors.onSuccess,
      AppStatusTone.warning => colors.onWarning,
      AppStatusTone.info => colors.onInfo,
      AppStatusTone.danger => colors.onDanger,
      AppStatusTone.brand => context.colorScheme.onPrimary,
    };
  }
}
