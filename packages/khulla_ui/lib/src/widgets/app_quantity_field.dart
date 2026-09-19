// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter/services.dart';
import 'package:khulla_ui/khulla_ui.dart';

/// How tall the minus/plus control is relative to a text field.
enum AppQuantityFieldSize {
  /// Matches [AppMetrics.fieldHeight] - sits beside a text field in a form row.
  regular,

  /// A tighter control for short prompts and dialogs.
  small,
}

/// {@template app_quantity_field}
/// A whole-number field with minus and plus at the ends.
///
/// The value is typed or stepped. Stepping slides the figure with
/// [AppSlidingNumber]. [AppPositiveIntFormatter] keeps it a non-negative
/// integer; [min] is enforced by disabling minus and by the caller on submit,
/// not by rewriting a cleared field mid-gesture.
/// {@endtemplate}
class AppQuantityField extends StatefulWidget {
  /// {@macro app_quantity_field}
  const AppQuantityField({
    required this.onChanged,
    required this.decreaseTooltip,
    required this.increaseTooltip,
    required this.controller,
    super.key,
    this.label,
    this.errorText,
    this.required = false,
    this.min = 1,
    this.max = 999,
    this.enabled = true,
    this.size = AppQuantityFieldSize.regular,
  });

  /// External label shown above the field.
  final String? label;

  /// Validation message shown under the field.
  final String? errorText;

  /// When true, the external label shows a required asterisk.
  final bool required;

  /// Called on every keystroke and after a step.
  final ValueChanged<String> onChanged;

  /// Localized tooltip for the minus control.
  final String decreaseTooltip;

  /// Localized tooltip for the plus control.
  final String increaseTooltip;

  /// The value. The stepper writes through this same controller.
  final TextEditingController controller;

  /// Inclusive lower bound for the stepper. Typing below it is still
  /// possible so the field can show [errorText].
  final int min;

  /// Inclusive upper bound for typing and the stepper.
  final int max;

  /// Whether the field accepts input.
  final bool enabled;

  /// [AppQuantityFieldSize.regular] matches a text field; [AppQuantityFieldSize.small] fits a short dialog.
  final AppQuantityFieldSize size;

  @override
  State<AppQuantityField> createState() => _AppQuantityFieldState();
}

class _AppQuantityFieldState extends State<AppQuantityField> {
  late final FocusNode _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    _focus
      ..removeListener(_onFocusChanged)
      ..dispose();
    super.dispose();
  }

  void _onFocusChanged() => setState(() {});

  int? _parsed(String text) => int.tryParse(text);

  void _step(int delta) {
    final current = _parsed(widget.controller.text);
    final next =
        (current ?? (delta > 0 ? widget.min - 1 : widget.min + 1)) + delta;
    final clamped = next.clamp(widget.min, widget.max);
    final text = clamped.toString();
    _focus.unfocus();
    unawaited(HapticFeedback.selectionClick());
    widget.controller.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
    widget.onChanged(text);
  }

  @override
  Widget build(BuildContext context) {
    final spacing = context.appSpacing;
    final colors = context.appColors;
    final metrics = context.appMetrics;
    final numeric = context.appTextStyles.numeric.copyWith(
      color: colors.ink100,
    );
    final error = widget.errorText;
    final fieldLabel = widget.label;
    final isSmall = widget.size == AppQuantityFieldSize.small;
    final controlHeight = isSmall
        ? metrics.iconButtonSmall
        : metrics.fieldHeight;
    final width = isSmall
        ? metrics.iconButtonSmall * 2.75
        : metrics.fieldHeight * 3;
    final focused = _focus.hasFocus;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (fieldLabel != null) ...[
          AppFieldLabel(
            label: fieldLabel,
            required: widget.required,
            hasError: error != null,
          ),
          SizedBox(height: metrics.labelToControlGap),
        ],
        SizedBox(
          width: width,
          child: ValueListenableBuilder<TextEditingValue>(
            valueListenable: widget.controller,
            builder: (context, value, _) {
              final parsed = _parsed(value.text);
              final canDecrease =
                  widget.enabled && parsed != null && parsed > widget.min;
              final canIncrease =
                  widget.enabled && (parsed == null || parsed < widget.max);
              final showSlide = !focused && parsed != null;

              if (isSmall) {
                return AppCompactQuantityControl(
                  controlHeight: controlHeight,
                  canDecrease: canDecrease,
                  canIncrease: canIncrease,
                  showSlide: showSlide,
                  parsed: parsed,
                  numeric: numeric,
                  colors: colors,
                  controller: widget.controller,
                  focusNode: _focus,
                  enabled: widget.enabled,
                  max: widget.max,
                  decreaseTooltip: widget.decreaseTooltip,
                  increaseTooltip: widget.increaseTooltip,
                  onChanged: widget.onChanged,
                  onDecrease: () => _step(-1),
                  onIncrease: () => _step(1),
                );
              }

              return AppRegularQuantityControl(
                controller: widget.controller,
                focusNode: _focus,
                enabled: widget.enabled,
                max: widget.max,
                numeric: numeric,
                canDecrease: canDecrease,
                canIncrease: canIncrease,
                showSlide: showSlide,
                parsed: parsed,
                decreaseTooltip: widget.decreaseTooltip,
                increaseTooltip: widget.increaseTooltip,
                onChanged: widget.onChanged,
                onDecrease: () => _step(-1),
                onIncrease: () => _step(1),
              );
            },
          ),
        ),
        if (error != null) ...[
          SizedBox(height: spacing.xxs + 2),
          AppFieldError(message: error),
        ],
      ],
    );
  }
}
