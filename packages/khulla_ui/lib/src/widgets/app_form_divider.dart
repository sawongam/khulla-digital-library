// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: MIT

import 'package:khulla_ui/khulla_ui.dart';

/// {@template app_form_divider}
/// A hairline with the page rhythm either side, between two [AppFormSection]s
/// on a long form.
///
/// Without it, a split-layout form reads as one column of fields with stray
/// headings on the left; the line is what says "this group ended".
/// {@endtemplate}
class AppFormDivider extends StatelessWidget {
  /// {@macro app_form_divider}
  const AppFormDivider({super.key});

  @override
  Widget build(BuildContext context) {
    final spacing = context.appSpacing;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: spacing.lg),
      child: Divider(
        height: 1,
        thickness: 1,
        color: context.appColors.hairline,
      ),
    );
  }
}
