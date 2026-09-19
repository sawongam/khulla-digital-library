// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:khulla_ui/khulla_ui.dart';

void main() {
  group('AppTheme', () {
    for (final brightness in Brightness.values) {
      for (final density in AppDensity.values) {
        test('carries every token extension in $brightness/$density', () {
          final theme = brightness == Brightness.light
              ? AppTheme.light(density)
              : AppTheme.dark(density);

          // context.appColors and friends assert these are present. A theme
          // built without one throws deep inside an unrelated widget's build,
          // which is a miserable way to find out.
          expect(theme.extension<AppColors>(), isNotNull);
          expect(theme.extension<AppSpacing>(), isNotNull);
          expect(theme.extension<AppRadius>(), isNotNull);
          expect(theme.extension<AppBorders>(), isNotNull);
          expect(theme.extension<AppBreakpoints>(), isNotNull);
          expect(theme.extension<AppShadows>(), isNotNull);
          expect(theme.extension<AppMetrics>(), isNotNull);
          expect(theme.extension<AppMotion>(), isNotNull);
          expect(theme.extension<AppTextStyles>(), isNotNull);
        });
      }
    }

    test('steps type and control height up exactly once at comfortable', () {
      // The comfortable rung is the shipped default. Compact still exists for
      // tests and the gallery - both rungs must stay in step with each other.
      final compact = AppTheme.light(AppDensity.compact);
      final comfortable = AppTheme.light();

      expect(compact.textTheme.bodyMedium?.fontSize, 12);
      expect(comfortable.textTheme.bodyMedium?.fontSize, 14);
      expect(compact.extension<AppMetrics>()!.fieldHeight, 40);
      expect(comfortable.extension<AppMetrics>()!.fieldHeight, 44);
      // Row height is global rather than a density rung, so the claim is that
      // the two agree - not what the number is, which design tunes.
      expect(
        compact.extension<AppMetrics>()!.tableRowHeight,
        comfortable.extension<AppMetrics>()!.tableRowHeight,
      );
      expect(compact.extension<AppMetrics>()!.tableHeaderHeight, 36);
      expect(comfortable.extension<AppMetrics>()!.tableHeaderHeight, 40);
    });

    test('keeps the radius hierarchy: control > container > item', () {
      // Flattening these to one value is the most common single error in
      // reproducing this design, so it is pinned rather than trusted.
      final radius = AppTheme.light().extension<AppRadius>()!;

      expect(radius.control, greaterThan(radius.container));
      expect(radius.container, greaterThan(radius.item));
    });

    test("replaces Material ink with the design system's own feedback", () {
      // AppRipple draws press feedback itself. If the splash factory comes
      // back, every control gets two overlapping ripples.
      final theme = AppTheme.light();

      expect(theme.splashFactory, NoSplash.splashFactory);
      expect(theme.highlightColor, Colors.transparent);
    });

    test('leaves a field border unchanged between resting and focused', () {
      // Focus is signalled by a padding nudge, not a ring or a recolour.
      final theme = AppTheme.light();
      final decoration = theme.inputDecorationTheme;

      expect(
        (decoration.focusedBorder! as OutlineInputBorder).borderSide.color,
        (decoration.enabledBorder! as OutlineInputBorder).borderSide.color,
      );
    });

    test(
      'separates canvas from card by hairline in light, by fill in dark',
      () {
        // Light: depth comes from the hairline, so the page and a card sit on
        // the same white and only the 1px border tells them apart. Dark: a
        // hairline on near-black is too weak to carry an edge on its own, so
        // the canvas drops below the card instead. Both are deliberate; the
        // thing neither may do is leave the two indistinguishable.
        final light = AppTheme.light();
        expect(light.scaffoldBackgroundColor, light.colorScheme.surface);
        expect(
          light.extension<AppColors>()!.hairline,
          isNot(light.colorScheme.surface),
          reason: 'the hairline has to be visible against the canvas',
        );

        final dark = AppTheme.dark();
        expect(
          dark.extension<AppColors>()!.secondary,
          isNot(dark.colorScheme.surface),
        );
      },
    );
  });

  group('AppBreakpoints', () {
    const breakpoints = AppBreakpoints();

    test('maps widths onto the four window size classes', () {
      expect(breakpoints.formFactorFor(360), FormFactor.compact);
      expect(breakpoints.formFactorFor(599), FormFactor.compact);
      expect(breakpoints.formFactorFor(600), FormFactor.medium);
      expect(breakpoints.formFactorFor(839), FormFactor.medium);
      expect(breakpoints.formFactorFor(840), FormFactor.expanded);
      expect(breakpoints.formFactorFor(1199), FormFactor.expanded);
      expect(breakpoints.formFactorFor(1200), FormFactor.large);
      expect(breakpoints.formFactorFor(2560), FormFactor.large);
    });

    test('puts navigation in a rail everywhere but compact', () {
      expect(FormFactor.compact.usesNavigationRail, isFalse);
      expect(FormFactor.medium.usesNavigationRail, isTrue);
      expect(FormFactor.expanded.usesNavigationRail, isTrue);
      expect(FormFactor.large.usesNavigationRail, isTrue);
    });

    test('always uses the comfortable density rung', () {
      const breakpoints = AppBreakpoints();

      expect(breakpoints.densityFor(800), AppDensity.comfortable);
      expect(breakpoints.densityFor(1600), AppDensity.comfortable);
    });

    test('extends the rail only at the largest class', () {
      expect(
        FormFactor.values.where((f) => f.usesExtendedRail),
        [FormFactor.large],
      );
    });
  });
}
