// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: MIT

import 'dart:ui';

import 'package:khulla_ui/khulla_ui.dart';

/// Material window size classes used for page-level layout.
///
/// Khulla is desktop- and web-first, so the ladder runs one step further than
/// a phone-only app: [expanded] is a normal windowed desktop app, [large] is
/// a maximised one where a navigation rail can afford to show its labels.
enum FormFactor {
  /// Width below [AppBreakpoints.compact]. One column, bottom navigation.
  compact,

  /// Width from [AppBreakpoints.compact] up to [AppBreakpoints.medium].
  /// Two columns where content is list-like, collapsed navigation rail.
  medium,

  /// Width from [AppBreakpoints.medium] up to [AppBreakpoints.expanded].
  /// Multi-column or two-pane, collapsed navigation rail.
  expanded,

  /// Width at or above [AppBreakpoints.expanded]. Two-pane with room for an
  /// extended navigation rail and a persistent detail pane.
  large;

  /// Whether there is room for more than one column.
  bool get isWide => this != FormFactor.compact;

  /// Whether this class uses the compact (mobile) type ramp.
  bool get isCompact => this == FormFactor.compact;

  /// Whether navigation belongs in a side rail rather than a bottom bar.
  bool get usesNavigationRail => isWide;

  /// Whether a navigation rail has room to show destination labels inline.
  bool get usesExtendedRail => this == FormFactor.large;

  /// Whether this class is [other] or wider.
  ///
  /// The enum is declared narrowest-first, so comparing ordinals is the same
  /// question as comparing widths. Use it to gate anything that needs room -
  /// a table column, a second pane - without naming a pixel value:
  /// `context.formFactor.isAtLeast(FormFactor.expanded)`.
  bool isAtLeast(FormFactor other) => index >= other.index;

  /// How many equal columns a grid of cards should use at this width.
  ///
  /// The default ladder for dashboard tiles and card grids: one on a phone,
  /// four on a maximised desktop window. Pass overrides where a particular
  /// grid wants a different ladder.
  int columns({
    int compact = 1,
    int medium = 2,
    int expanded = 3,
    int large = 4,
  }) => switch (this) {
    FormFactor.compact => compact,
    FormFactor.medium => medium,
    FormFactor.expanded => expanded,
    FormFactor.large => large,
  };
}

/// {@template app_breakpoints}
/// Window size class thresholds and content caps.
///
/// Read the class with `context.formFactor` - never compare a
/// [MediaQuery] width against a literal.
/// {@endtemplate}
class AppBreakpoints extends ThemeExtension<AppBreakpoints> {
  /// {@macro app_breakpoints}
  const AppBreakpoints({
    this.compact = 600,
    this.medium = 840,
    this.expanded = 1200,
    this.comfortable = 1600,
    this.contentMaxWidth = 720,
    this.wideContentMaxWidth = 1600,
  });

  /// Compact upper bound, exclusive. Matches Material's compact class.
  final double compact;

  /// Medium upper bound, exclusive. Expanded starts here.
  final double medium;

  /// Expanded upper bound, exclusive. Large starts here.
  final double expanded;

  /// The density step-up. Not a layout breakpoint: at this width the UI
  /// steps type, control height, icon size and gap up by exactly one notch
  /// and reflows nothing. It is the only width [AppDensity] is read from.
  final double comfortable;

  /// Max width for reading content - prose, forms, a book's detail pane.
  /// Roughly 75 characters at the body ramp, which is the readable ceiling.
  final double contentMaxWidth;

  /// Max width for dense content that genuinely uses the room: catalogue
  /// tables, circulation boards, dashboards.
  ///
  /// Set at the density step, so a maximised 1600px window fills edge to edge
  /// with the roomier rung rather than growing margins, and anything wider
  /// stops there instead of stretching a table across a 2560px monitor.
  final double wideContentMaxWidth;

  /// Resolves [width] to an [AppDensity].
  ///
  /// Density is not user-configurable; the comfortable rung is always used.
  AppDensity densityFor(double width) => AppDensity.comfortable;

  /// Resolves [width] to a [FormFactor].
  FormFactor formFactorFor(double width) {
    if (width < compact) return FormFactor.compact;
    if (width < medium) return FormFactor.medium;
    if (width < expanded) return FormFactor.expanded;
    return FormFactor.large;
  }

  @override
  AppBreakpoints copyWith({
    double? compact,
    double? medium,
    double? expanded,
    double? comfortable,
    double? contentMaxWidth,
    double? wideContentMaxWidth,
  }) {
    return AppBreakpoints(
      compact: compact ?? this.compact,
      medium: medium ?? this.medium,
      expanded: expanded ?? this.expanded,
      comfortable: comfortable ?? this.comfortable,
      contentMaxWidth: contentMaxWidth ?? this.contentMaxWidth,
      wideContentMaxWidth: wideContentMaxWidth ?? this.wideContentMaxWidth,
    );
  }

  @override
  AppBreakpoints lerp(AppBreakpoints? other, double t) {
    if (other is! AppBreakpoints) return this;
    return AppBreakpoints(
      compact: lerpDouble(compact, other.compact, t)!,
      medium: lerpDouble(medium, other.medium, t)!,
      expanded: lerpDouble(expanded, other.expanded, t)!,
      comfortable: lerpDouble(comfortable, other.comfortable, t)!,
      contentMaxWidth: lerpDouble(contentMaxWidth, other.contentMaxWidth, t)!,
      wideContentMaxWidth: lerpDouble(
        wideContentMaxWidth,
        other.wideContentMaxWidth,
        t,
      )!,
    );
  }
}
