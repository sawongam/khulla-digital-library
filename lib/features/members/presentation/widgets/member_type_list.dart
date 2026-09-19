// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:khulla/features/members/domain/models/member_type.dart';
import 'package:khulla/features/members/presentation/widgets/member_type_row.dart';
import 'package:khulla/l10n/l10n.dart';
import 'package:khulla_ui/khulla_ui.dart';

/// The category rows inside the sheet body: an inline empty state
/// when there is nothing yet, otherwise one [MemberTypeRow] per type.
///
/// `canArchive` guards the last active category — archiving it would leave
/// new members with nowhere to go.
class MemberTypeList extends StatelessWidget {
  const MemberTypeList({
    required this.types,
    required this.onAdd,
    required this.onEdit,
    required this.onArchive,
    required this.onRestore,
    super.key,
  });

  final List<MemberType> types;
  final VoidCallback onAdd;
  final void Function(MemberType type) onEdit;
  final void Function(MemberType type) onArchive;
  final void Function(MemberType type) onRestore;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final activeCount = types.where((type) => !type.isArchived).length;

    if (types.isEmpty) {
      return AppEmptyView(
        variant: AppFeedbackVariant.inline,
        title: l10n.memberTypesEmptyTitle,
        message: l10n.memberTypesEmptyBody,
        actionLabel: l10n.memberTypeAddCategory,
        onAction: onAdd,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final type in types)
          Padding(
            padding: EdgeInsets.only(bottom: context.appSpacing.sm),
            child: MemberTypeRow(
              type: type,
              canArchive: !type.isArchived && activeCount > 1,
              onEdit: () => onEdit(type),
              onArchive: () => onArchive(type),
              onRestore: () => onRestore(type),
            ),
          ),
      ],
    );
  }
}
