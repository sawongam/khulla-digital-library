// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: MIT

import 'package:khulla_ui/khulla_ui.dart';

/// {@template app_switch_field}
/// A setting row: label, explanation, and a switch on the trailing edge.
///
/// A switch means the change takes effect immediately - that is what
/// separates it from [AppCheckboxField], which collects a value the form
/// submits later. Use it in Settings, not in an editor.
/// {@endtemplate}
class AppSwitchField extends StatelessWidget {
  /// {@macro app_switch_field}
  const AppSwitchField({
    required this.value,
    required this.label,
    required this.onChanged,
    this.description,
    this.stacked = false,
    super.key,
  });

  /// Whether the setting is on.
  final bool value;

  /// What the setting does.
  final String label;

  /// Called with the next state. Null disables the row.
  final ValueChanged<bool>? onChanged;

  /// Supporting line under [label].
  final String? description;

  /// When true, the label sits above the switch so the control lines up with
  /// [AppTextField] in an [AppFormRow]. The default inline layout is for
  /// settings pages.
  final bool stacked;

  @override
  Widget build(BuildContext context) {
    final spacing = context.appSpacing;
    final scheme = context.colorScheme;
    final metrics = context.appMetrics;
    final enabled = onChanged != null;
    final caption = description;

    if (stacked) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          AppFieldLabel(label: label),
          SizedBox(height: metrics.labelToControlGap),
          SizedBox(
            height: metrics.fieldHeight,
            child: AppRipple(
              onTap: enabled ? () => onChanged!(!value) : null,
              borderRadius: BorderRadius.circular(context.appRadius.container),
              pressScale: 1,
              child: Row(
                children: [
                  if (caption != null)
                    Expanded(
                      child: Text(
                        caption,
                        style: context.appTextStyles.caption.copyWith(
                          color: context.appColors.mutedForeground,
                        ),
                      ),
                    ),
                  _AppSwitchControl(value: value, onChanged: onChanged),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return AppRipple(
      onTap: enabled ? () => onChanged!(!value) : null,
      borderRadius: BorderRadius.circular(context.appRadius.container),
      pressScale: 1,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: spacing.xs),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: context.appTextStyles.label.copyWith(
                      color: enabled
                          ? scheme.onSurface
                          : context.appColors.ink500,
                    ),
                  ),
                  if (caption != null) ...[
                    SizedBox(height: spacing.xxs),
                    Text(
                      caption,
                      style: context.appTextStyles.caption.copyWith(
                        color: context.appColors.mutedForeground,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            SizedBox(width: spacing.md),
            _AppSwitchControl(value: value, onChanged: onChanged),
          ],
        ),
      ),
    );
  }
}

class _AppSwitchControl extends StatelessWidget {
  const _AppSwitchControl({
    required this.value,
    required this.onChanged,
  });

  final bool value;
  final ValueChanged<bool>? onChanged;

  static const _materialSwitchWidth = 52;

  @override
  Widget build(BuildContext context) {
    final metrics = context.appMetrics;
    final scale = metrics.switchTrackWidth / _materialSwitchWidth;

    return Transform.scale(
      scale: scale,
      alignment: Alignment.centerRight,
      child: Switch(
        value: value,
        onChanged: onChanged,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }
}
