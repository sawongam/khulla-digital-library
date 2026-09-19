// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:khulla/features/catalog/copy/domain/models/copy.dart';
import 'package:khulla/features/catalog/copy/presentation/widgets/copy_status_badge.dart';
import 'package:khulla/features/catalog/shared/domain/copy_status.dart';
import 'package:khulla/l10n/l10n.dart';
import 'package:khulla_ui/khulla_ui.dart';

/// One copy on a title's detail screen - barcode, shelf, notes, standing, and
/// who has it when it is out.
///
/// A table with a "With" column full of dashes was worse than a short row
/// list: three copies do not need column headers, and the borrower line only
/// appears when the copy is actually on loan. Shelf and notes fill the row on
/// wider slots; on a phone they stack under the barcode.
class TitleCopyRow extends StatelessWidget {
  const TitleCopyRow({
    required this.copy,
    this.onMarkLost,
    this.onMarkDamaged,
    this.onWithdraw,
    super.key,
  });

  final Copy copy;

  /// Per-copy maintenance. All three are null for a role that may read the
  /// catalogue but not change it, and the row then draws no menu at all -
  /// a menu whose every entry is disabled is worse than no menu.
  final VoidCallback? onMarkLost;
  final VoidCallback? onMarkDamaged;
  final VoidCallback? onWithdraw;

  static String _displayOrDash(String? value) =>
      value == null || value.trim().isEmpty ? '-' : value.trim();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final spacing = context.appSpacing;
    final markLost = onMarkLost;
    final markDamaged = onMarkDamaged;
    final withdraw = onWithdraw;
    final scheme = context.colorScheme;
    final checkedOut =
        copy.status == CopyStatus.onLoan && copy.borrower != null;
    final wideMeta = context.formFactor.isAtLeast(FormFactor.medium);
    final muted = context.textTheme.bodyMedium?.copyWith(
      color: scheme.onSurfaceVariant,
    );
    final mutedSmall = context.textTheme.bodySmall?.copyWith(
      color: scheme.onSurfaceVariant,
    );
    final hasNotes = copy.notes?.trim().isNotEmpty ?? false;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: spacing.sm),
      child: Row(
        children: [
          Expanded(
            flex: wideMeta ? 2 : 1,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  copy.barcode,
                  style: context.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: scheme.onSurface,
                  ),
                ),
                if (checkedOut) ...[
                  SizedBox(height: spacing.xxs),
                  Text(
                    l10n.titleDetailCopyCheckedOut(
                      copy.borrower!,
                      copy.dueDate ?? l10n.commonNotSet,
                    ),
                    style: mutedSmall,
                  ),
                ],
                if (!wideMeta) ...[
                  if (copy.shelf.isNotEmpty) ...[
                    SizedBox(height: spacing.xxs),
                    Text(
                      copy.shelf,
                      style: mutedSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  if (hasNotes) ...[
                    SizedBox(height: spacing.xxs),
                    Text(
                      copy.notes!.trim(),
                      style: mutedSmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ],
            ),
          ),
          if (wideMeta) ...[
            Expanded(
              flex: 2,
              child: Text(
                _displayOrDash(copy.shelf),
                style: muted,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Expanded(
              flex: 3,
              child: Text(
                _displayOrDash(copy.notes),
                style: muted,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
          SizedBox(width: spacing.sm),
          CopyStatusBadge(status: copy.status),
          SizedBox(width: spacing.xs),
          if (markLost != null || markDamaged != null || withdraw != null)
            AppMenuButton(
              tooltip: l10n.commonMoreActions,
              actions: [
                if (markLost != null)
                  AppMenuAction(
                    label: l10n.copiesMarkLost,
                    icon: AppIcons.help,
                    onSelected: markLost,
                  ),
                if (markDamaged != null)
                  AppMenuAction(
                    label: l10n.copiesMarkDamaged,
                    icon: AppIcons.damage,
                    onSelected: markDamaged,
                  ),
                if (withdraw != null)
                  AppMenuAction(
                    label: l10n.copiesWithdraw,
                    icon: AppIcons.delete,
                    isDestructive: true,
                    onSelected: withdraw,
                  ),
              ],
            ),
        ],
      ),
    );
  }
}
