// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: MIT

import 'package:flutter/services.dart';
import 'package:khulla_ui/khulla_ui.dart';

/// {@template app_text_field}
/// The system's text field: a label above, a hairline box, an error below.
///
/// Two things about it are deliberate and easy to undo by accident.
///
/// **There is no focus ring, and the border never changes color** - not on
/// focus, not on error. Focus is signalled by the text nudging 2px to the
/// right over 300ms, which is quiet enough to live on a form of twenty fields
/// without the screen lighting up. On error the *label* turns red and the
/// message appears below; the box stays as it was.
///
/// **The field is 40px tall (44 at the wide density), not Material's 56.**
/// Two fields per row at 40px is what makes a form fit in a dialog without
/// scrolling.
/// {@endtemplate}
class AppTextField extends StatefulWidget {
  /// {@macro app_text_field}
  const AppTextField({
    required this.onChanged,
    super.key,
    this.label,
    this.hintText,
    this.errorText,
    this.required = false,
    this.keyboardType,
    this.obscureText = false,
    this.prefixIcon,
    this.prefixIconConstraints,
    this.suffixIcon,
    this.suffixIconConstraints,
    this.textAlign = TextAlign.start,
    this.textInputAction,
    this.initialValue,
    this.controller,
    this.maxLength,
    this.maxLines = 1,
    this.minLines,
    this.inputFormatters,
    this.enabled = true,
    this.autofocus = false,
    this.textCapitalization = TextCapitalization.none,
    this.onSubmitted,
    this.focusNode,
    this.readOnly = false,
    this.onTap,
    this.showCursor,
    this.enableInteractiveSelection = true,
  }) : assert(
         controller == null || initialValue == null,
         'Provide either controller or initialValue, not both.',
       );

  /// External label shown above the field. Omit for hint-only fields (e.g. search).
  final String? label;

  /// Placeholder shown inside the field while empty.
  ///
  /// Defaults to [label] when omitted so labelled fields always show a hint.
  final String? hintText;

  /// Called on every keystroke.
  final ValueChanged<String> onChanged;

  /// Validation message shown under the field.
  final String? errorText;

  /// When true, the external label shows a required asterisk.
  final bool required;

  /// Soft keyboard type.
  final TextInputType? keyboardType;

  /// Whether the value is masked.
  final bool obscureText;

  /// Leading adornment.
  final Widget? prefixIcon;

  /// Size constraints for [prefixIcon]. Tighten when the prefix is text.
  final BoxConstraints? prefixIconConstraints;

  /// Trailing adornment.
  final Widget? suffixIcon;

  /// Size constraints for [suffixIcon]. Tighten when the suffix is a control.
  final BoxConstraints? suffixIconConstraints;

  /// Alignment of the value inside the field.
  final TextAlign textAlign;

  /// Keyboard action button.
  final TextInputAction? textInputAction;

  /// Starting value for an uncontrolled field.
  final String? initialValue;

  /// External controller for a field whose text is driven by the caller.
  final TextEditingController? controller;

  /// Maximum character count. The counter itself stays hidden.
  final int? maxLength;

  /// Maximum visible lines. Pass null for an unbounded, growing field.
  final int? maxLines;

  /// Minimum visible lines.
  final int? minLines;

  /// Input masking or filtering.
  final List<TextInputFormatter>? inputFormatters;

  /// Whether the field accepts input.
  final bool enabled;

  /// Whether the field takes focus on first build.
  final bool autofocus;

  /// Auto-capitalization behavior of the soft keyboard.
  final TextCapitalization textCapitalization;

  /// Called when the keyboard action button is pressed.
  final ValueChanged<String>? onSubmitted;

  /// Optional focus node for keyboard traversal between fields.
  final FocusNode? focusNode;

  /// When true, the field is not editable (e.g. tap-to-navigate search entry).
  final bool readOnly;

  /// Called when the field is tapped. Useful with [readOnly] search affordances.
  final VoidCallback? onTap;

  /// Overrides cursor visibility. Defaults to hidden for [readOnly] tap fields.
  final bool? showCursor;

  /// Whether the field text can be selected. Defaults to false for [readOnly]
  /// tap fields.
  final bool enableInteractiveSelection;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  FocusNode? _ownedNode;
  bool _focused = false;

  FocusNode get _node => widget.focusNode ?? (_ownedNode ??= FocusNode());

  @override
  void initState() {
    super.initState();
    _node.addListener(_onFocusChanged);
  }

  @override
  void didUpdateWidget(covariant AppTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode != widget.focusNode) {
      oldWidget.focusNode?.removeListener(_onFocusChanged);
      _node.addListener(_onFocusChanged);
    }
  }

  @override
  void dispose() {
    _node.removeListener(_onFocusChanged);
    _ownedNode?.dispose();
    super.dispose();
  }

  void _onFocusChanged() {
    if (_focused == _node.hasFocus) return;
    setState(() => _focused = _node.hasFocus);
  }

  @override
  Widget build(BuildContext context) {
    final spacing = context.appSpacing;
    final colors = context.appColors;
    final metrics = context.appMetrics;
    final typography = context.appTextStyles;
    final fieldLabel = widget.label;
    final hint = widget.hintText ?? fieldLabel;
    final error = widget.errorText;
    final multiline = widget.maxLines == null || widget.maxLines! > 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (fieldLabel != null) ...[
          AppFieldLabel(
            label: fieldLabel,
            required: widget.required,
            hasError: error != null,
          ),
          SizedBox(height: metrics.labelToControlGap),
        ],
        ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: multiline ? 0 : metrics.fieldHeight,
            maxHeight: multiline ? double.infinity : metrics.fieldHeight,
          ),
          child: TextFormField(
            initialValue: widget.initialValue,
            controller: widget.controller,
            focusNode: _node,
            enabled: widget.enabled,
            readOnly: widget.readOnly,
            onTap: widget.onTap,
            showCursor:
                widget.showCursor ?? (!widget.readOnly && widget.onTap == null),
            enableInteractiveSelection:
                !(widget.readOnly && widget.onTap != null) &&
                widget.enableInteractiveSelection,
            autofocus: widget.autofocus,
            textCapitalization: widget.textCapitalization,
            onChanged: widget.onChanged,
            onFieldSubmitted: widget.onSubmitted,
            obscureText: widget.obscureText,
            keyboardType: widget.keyboardType,
            textInputAction: widget.textInputAction,
            maxLength: widget.maxLength,
            maxLines: widget.maxLines,
            minLines: widget.minLines,
            inputFormatters: widget.inputFormatters,
            textAlign: widget.textAlign,
            style: typography.body.copyWith(color: colors.ink100),
            decoration: InputDecoration(
              hintText: hint,
              prefixIcon: switch (widget.prefixIcon) {
                final prefix? => AppFieldAffix(child: prefix),
                _ => null,
              },
              prefixIconConstraints: widget.prefixIconConstraints,
              suffixIcon: switch (widget.suffixIcon) {
                final suffix? => AppFieldAffix(child: suffix),
                _ => null,
              },
              suffixIconConstraints: widget.suffixIconConstraints,
              counterText: '',
              // The signature interaction: focus moves the text 2px right
              // rather than lighting up a ring.
              contentPadding: EdgeInsetsDirectional.only(
                start: _focused ? spacing.sm + 2 : spacing.sm,
                end: spacing.sm,
                top: spacing.xs,
                bottom: spacing.xs,
              ),
            ),
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
