// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: MIT

import 'package:khulla_ui/khulla_ui.dart';

/// {@template app_picker_field}
/// A field that looks like [AppTextField] but opens something instead of
/// taking keystrokes - a date picker, a member lookup, a shelf browser.
///
/// It takes an already-formatted [value] string. Formatting a date or an
/// amount is locale- and currency-dependent, and the design system does
/// neither: the caller formats, this lays out.
/// {@endtemplate}
class AppPickerField extends StatelessWidget {
  /// {@macro app_picker_field}
  const AppPickerField({
    required this.onTap,
    this.value,
    this.label,
    this.hintText,
    this.errorText,
    this.icon = AppIcons.chevronDown,
    this.required = false,
    this.enabled = true,
    this.onClear,
    this.clearTooltip,
    super.key,
  });

  /// Opens the picker. Null disables the field.
  final VoidCallback? onTap;

  /// The chosen value, already formatted. Null shows [hintText].
  final String? value;

  /// Label shown above the field.
  final String? label;

  /// Placeholder while nothing is chosen.
  ///
  /// Defaults to [label] when omitted so labelled fields always show a hint.
  final String? hintText;

  /// Validation message shown under the field.
  final String? errorText;

  /// Trailing glyph. Use `AppIcons.calendar` for a date,
  /// `AppIcons.search` for a lookup.
  final AppIconSpec icon;

  /// When true, the label shows a required asterisk.
  final bool required;

  /// Whether the field is interactive.
  final bool enabled;

  /// Clears the selection. Shows a clear button in place of [icon] once
  /// [value] is set.
  final VoidCallback? onClear;

  /// Tooltip on the clear button, required whenever [onClear] is set.
  final String? clearTooltip;

  @override
  Widget build(BuildContext context) {
    final spacing = context.appSpacing;
    final metrics = context.appMetrics;
    final scheme = context.colorScheme;
    final typography = context.textTheme;
    final fieldLabel = label;
    final hint = hintText ?? fieldLabel;
    final selected = value;
    final hasValue = selected != null && selected.isNotEmpty;
    final clear = onClear;
    final clearLabel = clearTooltip;

    // The trailing glyph lives in a plain Row, not the decoration's
    // suffix slot: Material enforces a 48px minimum box on that slot,
    // which is what pushed the box taller than its neighbours and left
    // the calendar floating. Same content-sized pattern as the
    // dropdown, so the two match in any row.
    final trailing = hasValue && clear != null && clearLabel != null
        ? Tooltip(
            message: clearLabel,
            child: InkWell(
              onTap: clear,
              child: Padding(
                padding: const EdgeInsets.all(2),
                child: AppIcon(
                  AppIcons.close,
                  size: metrics.icon,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
          )
        : AppIcon(
            icon,
            size: metrics.icon,
            color: scheme.onSurfaceVariant,
          );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (fieldLabel != null) ...[
          AppFieldLabel(label: fieldLabel, required: required),
          SizedBox(height: metrics.labelToControlGap),
        ],
        InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(context.appRadius.container),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: metrics.fieldHeight),
            child: InputDecorator(
              isEmpty: !hasValue,
              decoration: InputDecoration(
                isDense: true,
                hintText: hint,
                errorText: errorText,
                enabled: enabled,
                contentPadding: EdgeInsetsDirectional.only(
                  start: spacing.sm,
                  end: spacing.sm,
                  top: spacing.xs,
                  bottom: spacing.xs,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: hasValue
                        ? Text(
                            selected,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: typography.bodyMedium?.copyWith(
                              color: enabled
                                  ? scheme.onSurface
                                  : scheme.onSurfaceVariant,
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                  SizedBox(width: spacing.menuIconGap),
                  trailing,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
