// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: MIT

import 'package:khulla_ui/khulla_ui.dart';

/// The label above a form control.
///
/// 12/14px at weight 500 in the label ink - a shade lighter than body text,
/// so a column of labels reads as scaffolding and the values read as content.
/// A required field is marked with a red asterisk after a space, and the
/// whole label turns red when the field is in error.
class AppFieldLabel extends StatelessWidget {
  const AppFieldLabel({
    required this.label,
    this.required = false,
    this.hasError = false,
    super.key,
  });

  /// The label text, already localized.
  final String label;

  /// Appends the red asterisk.
  final bool required;

  /// Turns the label red. The field's own border does not change.
  final bool hasError;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final style = context.appTextStyles.label.copyWith(
      color: hasError ? colors.danger : colors.ink200,
      height: 1,
    );

    return Text.rich(
      TextSpan(
        children: [
          TextSpan(text: label, style: style),
          if (required)
            TextSpan(
              text: ' *',
              style: style.copyWith(color: colors.danger),
            ),
        ],
      ),
    );
  }
}

/// The validation message under a control.
///
/// The smallest type in the system, at weight 500 so it still reads at 10px.
/// No icon: in a two-column form, a row of alert glyphs turns the whole page
/// into a warning.
class AppFieldError extends StatelessWidget {
  const AppFieldError({required this.message, super.key});

  /// The message, already localized.
  final String message;

  @override
  Widget build(BuildContext context) => Text(
    message,
    style: context.appTextStyles.micro.copyWith(
      color: context.appColors.danger,
    ),
  );
}
