// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: MIT

import 'package:khulla_ui/khulla_ui.dart';

/// {@template app_checkbox_field}
/// A checkbox with its label and optional explanation, laid out as one row
/// that is entirely tappable.
///
/// The whole row is the target, not just the 16px box - a checkbox alone is
/// well under any reasonable minimum and is the control people miss most.
///
/// The box itself is a **tick in an outlined square, not a filled block**:
/// checked, the border and the tick turn brand and the fill stays empty. In a
/// list of fifteen permissions, fifteen filled red squares is a wall.
/// {@endtemplate}
class AppCheckboxField extends StatelessWidget {
  /// {@macro app_checkbox_field}
  const AppCheckboxField({
    required this.value,
    required this.label,
    required this.onChanged,
    this.description,
    this.tristate = false,
    super.key,
  });

  /// Current state. Null is the indeterminate state when [tristate] is set.
  final bool? value;

  /// What ticking the box means.
  final String label;

  /// Called with the next state. Null disables the row.
  final ValueChanged<bool?>? onChanged;

  /// Supporting line under [label] - the consequence of ticking it.
  final String? description;

  /// Whether the box cycles through an indeterminate state.
  final bool tristate;

  @override
  Widget build(BuildContext context) {
    final spacing = context.appSpacing;
    final scheme = context.colorScheme;
    final enabled = onChanged != null;
    final caption = description;

    return AppRipple(
      onTap: enabled ? () => onChanged!(!(value ?? false)) : null,
      borderRadius: BorderRadius.circular(context.appRadius.container),
      pressScale: 1,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: spacing.xxs),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox.square(
              dimension: context.appMetrics.checkbox,
              child: Checkbox(
                value: value,
                tristate: tristate,
                onChanged: onChanged,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
            SizedBox(width: spacing.sm),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 1),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      style: context.appTextStyles.body.copyWith(
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
            ),
          ],
        ),
      ),
    );
  }
}
