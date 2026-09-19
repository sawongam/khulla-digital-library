// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: MIT

import 'package:khulla_ui/khulla_ui.dart';

/// {@template app_form_section}
/// A titled group of related fields, with the vertical rhythm the form recipe
/// calls for: [AppSpacing.sm] between fields, [AppSpacing.lg] before the next
/// section.
///
/// Grouping is what makes a long editor readable - *Identification*,
/// *Availability*, *Fines* - so prefer three short sections to one column of
/// twelve fields.
///
/// Given a wide slot it splits in two: the heading and its explanation on the
/// left, the fields on the right. That is what lets a form live at the same
/// page width as a table instead of a narrow 720px ribbon down the middle of
/// a desktop window - and it shortens the page, because the explanation no
/// longer costs two lines above every group. The fields column is still
/// capped: a text input the width of a monitor is not easier to fill in.
/// {@endtemplate}
class AppFormSection extends StatelessWidget {
  /// {@macro app_form_section}
  const AppFormSection({
    required this.children,
    this.title,
    this.description,
    this.trailing,
    super.key,
  });

  /// The fields, in tab order.
  final List<Widget> children;

  /// Section heading. Omit for a lead section that needs no title.
  final String? title;

  /// Supporting line under [title].
  final String? description;

  /// One action for the section - *Add another copy*.
  final Widget? trailing;

  /// Slot width at or above which the heading moves beside the fields.
  static const double splitFrom = 880;

  /// Width of the heading column in the split layout.
  static const double headingWidth = 280;

  /// Widest the fields column gets, however wide the page is.
  static const double fieldsMaxWidth = 720;

  @override
  Widget build(BuildContext context) {
    final spacing = context.appSpacing;
    final heading = title;

    final fields = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final (index, field) in children.indexed) ...[
          if (index > 0) SizedBox(height: spacing.sm),
          field,
        ],
      ],
    );

    if (heading == null) return fields;

    final header = AppSectionHeader(
      title: heading,
      subtitle: description,
      trailing: trailing,
      dense: true,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < splitFrom) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              header,
              SizedBox(height: spacing.md),
              fields,
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: headingWidth, child: header),
            SizedBox(width: spacing.xlg),
            Expanded(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: fieldsMaxWidth),
                child: fields,
              ),
            ),
          ],
        );
      },
    );
  }
}
