// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:khulla/features/members/domain/member_optional_field.dart';
import 'package:khulla/features/members/presentation/member_labels.dart';
import 'package:khulla/l10n/l10n.dart';
import 'package:khulla_ui/khulla_ui.dart';

/// The optional member-form fields as a grid of checkboxes - two or three
/// across instead of one long column - so the whole choice fits on screen.
class SettingsMemberFieldGrid extends StatelessWidget {
  const SettingsMemberFieldGrid({
    required this.hidden,
    required this.onChanged,
    super.key,
  });

  /// Fields the member form currently hides.
  final Set<MemberOptionalField> hidden;

  /// Called with the field and whether it should now be shown.
  final void Function(MemberOptionalField field, bool shown) onChanged;

  static const double _minCellWidth = 200;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final spacing = context.appSpacing;

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = (constraints.maxWidth / _minCellWidth).floor().clamp(
          1,
          3,
        );
        final cell =
            (constraints.maxWidth - spacing.sm * (columns - 1)) / columns;
        return Wrap(
          spacing: spacing.sm,
          runSpacing: spacing.xs,
          children: [
            for (final field in MemberOptionalField.values)
              SizedBox(
                width: cell,
                child: AppCheckboxField(
                  value: !hidden.contains(field),
                  label: field.label(l10n),
                  onChanged: (shown) => onChanged(field, shown ?? true),
                ),
              ),
          ],
        );
      },
    );
  }
}
