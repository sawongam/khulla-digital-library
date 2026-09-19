// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:khulla/features/catalog/copy/domain/models/copy.dart';
import 'package:khulla/features/catalog/title/presentation/widgets/title_copy_row.dart';
import 'package:khulla/l10n/l10n.dart';
import 'package:khulla/shared/components/section_card.dart';
import 'package:khulla_ui/khulla_ui.dart';

/// Every item of this work the library holds.
///
/// A short row list rather than a table: a title has a handful of copies, so
/// column headers and a "With" column of dashes bought more chrome than
/// clarity. Add-copy is wired through [onAddCopy]; per-copy maintenance routes
/// through the three action callbacks on each [TitleCopyRow].
class TitleCopiesCard extends StatelessWidget {
  const TitleCopiesCard({
    required this.copies,
    this.onAddCopy,
    this.onMarkLost,
    this.onMarkDamaged,
    this.onWithdraw,
    super.key,
  });

  final List<Copy> copies;

  /// Opens the add-copies dialog. Null for a role that may read the catalogue
  /// but not change it — the button is absent rather than disabled.
  final VoidCallback? onAddCopy;

  /// Per-copy maintenance, passed down to each row. Null for a role that may
  /// read the catalogue but not change it.
  final void Function(Copy copy)? onMarkLost;
  final void Function(Copy copy)? onMarkDamaged;
  final void Function(Copy copy)? onWithdraw;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.appColors;
    final addCopy = onAddCopy;
    final markLost = onMarkLost;
    final markDamaged = onMarkDamaged;
    final withdraw = onWithdraw;

    return SectionCard(
      title: l10n.titleDetailCopiesTitle,
      subtitle: l10n.titleDetailCopiesSubtitle,
      trailing: addCopy == null
          ? null
          : AppTextButton(
              onPressed: addCopy,
              child: Text(l10n.titleDetailAddCopy),
            ),
      child: copies.isEmpty
          ? AppEmptyView(
              variant: AppFeedbackVariant.inline,
              title: l10n.titleDetailCopiesEmptyTitle,
              message: l10n.titleDetailCopiesEmptyBody,
              actionLabel: addCopy == null ? null : l10n.titleDetailAddCopy,
              onAction: addCopy,
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final (index, copy) in copies.indexed) ...[
                  if (index > 0) Divider(height: 1, color: colors.hairline),
                  TitleCopyRow(
                    copy: copy,
                    onMarkLost: markLost == null ? null : () => markLost(copy),
                    onMarkDamaged: markDamaged == null
                        ? null
                        : () => markDamaged(copy),
                    onWithdraw: withdraw == null ? null : () => withdraw(copy),
                  ),
                ],
              ],
            ),
    );
  }
}
