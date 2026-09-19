// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: MIT

import 'package:flutter/services.dart';
import 'package:khulla_ui/khulla_ui.dart';
import 'package:khulla_ui/src/theme/app_palette.dart';

/// {@template app_color_picker}
/// Mixes one color: a saturation/value pad, a hue slider, and a hex field.
///
/// Three ways in, because they suit different intents. The pad is for finding
/// a color by eye, the slider narrows the hue first, and the hex field is for
/// a brand color someone has been given as `#0A6A66` and must match exactly -
/// which no amount of dragging reliably hits.
///
/// The hue is held separately from the color it produces. Dragging the pad
/// down to black or left to white throws the hue away in RGB, so a picker
/// that re-derived it every frame would snap the slider to red the moment the
/// operator reached the edge of the pad.
/// {@endtemplate}
class AppColorPicker extends StatefulWidget {
  /// {@macro app_color_picker}
  const AppColorPicker({
    required this.value,
    required this.onChanged,
    required this.hexLabel,
    super.key,
  });

  /// The color being edited.
  final Color value;

  /// Called on every drag frame and on every valid hex entry.
  final ValueChanged<Color> onChanged;

  /// The localized label on the hex field.
  final String hexLabel;

  @override
  State<AppColorPicker> createState() => _AppColorPickerState();
}

class _AppColorPickerState extends State<AppColorPicker> {
  static const double _padHeight = 168;
  static const double _sliderHeight = 20;
  static const double _thumbRadius = 9;
  static const double _previewSize = 44;

  late HSVColor _hsv = HSVColor.fromColor(widget.value);
  late final TextEditingController _hex = TextEditingController(
    text: _hexOf(widget.value),
  );

  @override
  void didUpdateWidget(AppColorPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Only when the owner replaced the color - not when it is echoing back
    // what this widget just emitted, which would fight the drag.
    if (widget.value != oldWidget.value && widget.value != _hsv.toColor()) {
      _hsv = HSVColor.fromColor(widget.value);
      _hex.text = _hexOf(widget.value);
    }
  }

  @override
  void dispose() {
    _hex.dispose();
    super.dispose();
  }

  void _emit(HSVColor next, {bool syncHex = true}) {
    setState(() => _hsv = next);
    if (syncHex) _hex.text = _hexOf(next.toColor());
    widget.onChanged(next.toColor());
  }

  void _hexChanged(String text) {
    final parsed = _parseHex(text);
    if (parsed == null) return;
    final next = HSVColor.fromColor(parsed);
    // A grey has no hue of its own; keep the one the slider is on so the pad
    // does not reset under the operator.
    _emit(next.saturation == 0 ? next.withHue(_hsv.hue) : next, syncHex: false);
  }

  @override
  Widget build(BuildContext context) {
    final spacing = context.appSpacing;
    final colors = context.appColors;
    final radius = context.appRadius;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(height: _padHeight, child: _pad(radius, colors)),
        SizedBox(height: spacing.sm),
        _hueSlider(radius, colors),
        SizedBox(height: spacing.sm),
        Row(
          children: [
            Container(
              width: _previewSize,
              height: _previewSize,
              decoration: BoxDecoration(
                color: _hsv.toColor(),
                borderRadius: BorderRadius.circular(radius.container),
                border: Border.all(color: colors.hairline),
              ),
            ),
            SizedBox(width: spacing.sm),
            Expanded(
              child: AppTextField(
                label: widget.hexLabel,
                controller: _hex,
                onChanged: _hexChanged,
                textCapitalization: TextCapitalization.characters,
                prefixIcon: Text(
                  '#',
                  style: context.appTextStyles.body.copyWith(
                    color: colors.mutedForeground,
                  ),
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp('[0-9a-fA-F]')),
                  LengthLimitingTextInputFormatter(6),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _pad(AppRadius radius, AppColors colors) => LayoutBuilder(
    builder: (context, constraints) {
      void handle(Offset local) {
        final saturation = (local.dx / constraints.maxWidth).clamp(0.0, 1.0);
        final value = 1 - (local.dy / constraints.maxHeight).clamp(0.0, 1.0);
        _emit(_hsv.withSaturation(saturation).withValue(value));
      }

      return GestureDetector(
        onPanDown: (details) => handle(details.localPosition),
        onPanUpdate: (details) => handle(details.localPosition),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(radius.container),
          child: Stack(
            children: [
              // White → the hue at full strength, then clear → black over it:
              // the standard saturation/value square.
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.white,
                      HSVColor.fromAHSV(1, _hsv.hue, 1, 1).toColor(),
                    ],
                  ),
                ),
                child: const SizedBox.expand(),
              ),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black],
                  ),
                ),
                child: SizedBox.expand(),
              ),
              Positioned(
                left: _hsv.saturation * constraints.maxWidth - _thumbRadius,
                top: (1 - _hsv.value) * constraints.maxHeight - _thumbRadius,
                child: _Thumb(color: _hsv.toColor(), colors: colors),
              ),
            ],
          ),
        ),
      );
    },
  );

  Widget _hueSlider(AppRadius radius, AppColors colors) => LayoutBuilder(
    builder: (context, constraints) {
      void handle(Offset local) {
        final hue = (local.dx / constraints.maxWidth).clamp(0.0, 1.0) * 360;
        _emit(_hsv.withHue(hue));
      }

      return GestureDetector(
        onPanDown: (details) => handle(details.localPosition),
        onPanUpdate: (details) => handle(details.localPosition),
        child: SizedBox(
          height: _sliderHeight + _thumbRadius,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                height: _sliderHeight,
                margin: const EdgeInsets.only(top: _thumbRadius / 2),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(radius.pill),
                  gradient: const LinearGradient(colors: AppPalette.hueStops),
                ),
              ),
              Positioned(
                left: _hsv.hue / 360 * constraints.maxWidth - _thumbRadius,
                top: _sliderHeight / 2 + _thumbRadius / 2 - _thumbRadius,
                child: _Thumb(
                  color: HSVColor.fromAHSV(1, _hsv.hue, 1, 1).toColor(),
                  colors: colors,
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

/// The draggable handle: the color it sits on, ringed in white so it stays
/// visible over both ends of the pad.
class _Thumb extends StatelessWidget {
  const _Thumb({required this.color, required this.colors});

  final Color color;
  final AppColors colors;

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: Container(
      width: _AppColorPickerState._thumbRadius * 2,
      height: _AppColorPickerState._thumbRadius * 2,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: colors.paper, width: 2),
        boxShadow: context.appShadows.card,
      ),
    ),
  );
}

String _hexOf(Color color) => color
    .toARGB32()
    .toRadixString(16)
    .padLeft(8, '0')
    .substring(2)
    .toUpperCase();

Color? _parseHex(String text) {
  final digits = text.replaceAll('#', '').trim();
  if (digits.length != 6) return null;
  final rgb = int.tryParse(digits, radix: 16);
  if (rgb == null) return null;
  return Color.fromARGB(255, (rgb >> 16) & 0xFF, (rgb >> 8) & 0xFF, rgb & 0xFF);
}
