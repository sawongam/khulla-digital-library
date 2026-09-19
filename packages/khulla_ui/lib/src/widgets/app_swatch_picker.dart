// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: MIT

import 'package:khulla_ui/khulla_ui.dart';
import 'package:khulla_ui/src/theme/app_palette.dart';

/// {@template app_swatch_picker}
/// A row of color choices, one of them active.
///
/// The color *is* the label, so each swatch is a plain filled circle and the
/// name is only a tooltip - a grid of named rows would make picking a color a
/// reading task. Selection is a ring drawn outside the swatch plus a tick on
/// it: a ring alone disappears on a pale color, a tick alone disappears on a
/// dark one.
///
/// Use for a small, fixed set of colors. Anything data-driven or longer than
/// about a dozen belongs in a dropdown.
///
/// The optional last swatch is *mix your own*: give [onCustomTap] and
/// [customLabel] and the row ends with a spectrum circle that opens whatever
/// picker the caller wants. It sits in this widget rather than beside it so
/// the presets and the escape hatch stay one control - the same size, the
/// same ring, the same row.
/// {@endtemplate}
class AppSwatchPicker<T> extends StatelessWidget {
  /// {@macro app_swatch_picker}
  const AppSwatchPicker({
    required this.value,
    required this.items,
    required this.itemColor,
    required this.itemLabel,
    required this.onChanged,
    this.customColor,
    this.customLabel,
    this.onCustomTap,
    super.key,
  }) : assert(
         (customLabel == null) == (onCustomTap == null),
         'A custom swatch needs both a label and a tap handler.',
       );

  /// The active choice, or null while a custom color is active.
  final T? value;

  /// The choices, in display order.
  final List<T> items;

  /// The color each choice paints.
  final Color Function(T value) itemColor;

  /// Turns a choice into its localized name, shown as a tooltip.
  final String Function(T value) itemLabel;

  /// Called with the new choice.
  final ValueChanged<T> onChanged;

  /// The custom color currently in use, if any. When set, the custom swatch
  /// shows it and reads as selected; otherwise it shows the spectrum.
  final Color? customColor;

  /// The localized name of the custom swatch, shown as its tooltip.
  final String? customLabel;

  /// Opens the caller's color picker. Omit to offer presets only.
  final VoidCallback? onCustomTap;

  @override
  Widget build(BuildContext context) {
    final spacing = context.appSpacing;

    return Wrap(
      spacing: spacing.sm,
      runSpacing: spacing.sm,
      children: [
        for (final item in items)
          _Swatch(
            color: itemColor(item),
            label: itemLabel(item),
            selected: item == value,
            onTap: () => onChanged(item),
          ),
        if (onCustomTap case final onTap?)
          _Swatch(
            color: customColor,
            label: customLabel!,
            selected: customColor != null,
            onTap: onTap,
          ),
      ],
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({
    required this.color,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  static const double _size = 32;
  static const double _ring = 2;
  static const double _gap = 3;

  /// The color painted, or null for the *mix your own* swatch, which shows
  /// the spectrum instead.
  final Color? color;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final motion = context.appMotion;
    final fill = color;
    // White on a dark swatch, near-black on a pale one - the same rule the
    // brand ramp uses for the ink on a primary fill.
    final tick = (fill ?? colors.textHigh).computeLuminance() > 0.45
        ? colors.textHigh
        : colors.onSuccess;

    return Tooltip(
      message: label,
      child: Semantics(
        label: label,
        selected: selected,
        button: true,
        child: AppRipple(
          onTap: onTap,
          borderRadius: BorderRadius.circular(_size),
          child: AnimatedContainer(
            duration: motion.color,
            padding: const EdgeInsets.all(_gap),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: selected
                    ? (fill ?? colors.hairlineStrong)
                    : Colors.transparent,
                width: _ring,
              ),
            ),
            child: Container(
              width: _size,
              height: _size,
              decoration: BoxDecoration(
                color: fill,
                shape: BoxShape.circle,
                gradient: fill == null
                    ? const SweepGradient(colors: AppPalette.hueStops)
                    : null,
              ),
              child: selected
                  ? Center(
                      child: AppIcon(
                        AppIcons.check,
                        size: context.appMetrics.iconInButton,
                        color: tick,
                      ),
                    )
                  : null,
            ),
          ),
        ),
      ),
    );
  }
}
