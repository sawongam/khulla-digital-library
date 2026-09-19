// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:khulla/features/catalog/shared/presentation/catalog_labels.dart';
import 'package:khulla/features/catalog/title/domain/models/title.dart'
    as catalog;
import 'package:khulla/l10n/l10n.dart';
import 'package:khulla/shared/components/record_header.dart';
import 'package:khulla_ui/khulla_ui.dart';

/// A title's identity block: what the work is, how it stands, and what the
/// librarian can do with it.
///
/// Secondary actions sit in the open rather than behind an overflow menu. Delete
/// uses the destructive button variant so it reads clearly without competing
/// with edit for emphasis; the confirm dialog still carries the full sentence.
/// Author, format, availability and standing share one meta row under the title
/// so a librarian reads format, status and copy count in one pass.
class TitleDetailHeader extends StatelessWidget {
  const TitleDetailHeader({
    required this.title,
    this.onEdit,
    this.onDelete,
    super.key,
  });

  final catalog.Title title;

  /// Opens the title's form. Null for a role that may read the catalogue but
  /// not change it — the button is absent rather than disabled, because a
  /// control that can never be pressed is furniture.
  final VoidCallback? onEdit;

  /// Removes the title. Null for the same reason.
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final spacing = context.appSpacing;
    final colors = context.appColors;
    final scheme = context.colorScheme;
    final compact = context.formFactor.isCompact;
    final isAvailable = title.availableCount > 0;
    final muted = colors.mutedForeground;
    final metaStyle = context.appTextStyles.body.copyWith(color: muted);

    return RecordHeader(
      title: title.title,
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title.author,
            style: context.appTextStyles.bodyLarge.copyWith(color: muted),
          ),
          SizedBox(height: spacing.sm),
          Wrap(
            spacing: spacing.xs,
            runSpacing: spacing.xs,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppIcon(
                    title.formatCode.formatIcon,
                    size: context.appMetrics.iconDense,
                    color: scheme.onSurfaceVariant,
                  ),
                  SizedBox(width: spacing.xxs),
                  Text(
                    title.formatCode.formatLabel(l10n),
                    style: metaStyle,
                  ),
                ],
              ),
              const _MetaDot(),
              AppStatusBadge(
                label: isAvailable ? l10n.statusAvailable : l10n.statusOnLoan,
                tone: isAvailable ? AppStatusTone.success : AppStatusTone.brand,
              ),
              const _MetaDot(),
              Text(
                l10n.titlesCopiesOf(
                  '${title.availableCount}',
                  '${title.copyCount}',
                ),
                style: metaStyle,
              ),
              if (!title.lendable) ...[
                const _MetaDot(),
                AppStatusBadge(
                  label: l10n.titlesReferenceOnly,
                  tone: AppStatusTone.warning,
                ),
              ],
            ],
          ),
        ],
      ),
      // RecordHeader already wraps its actions in a Wrap, so these are
      // plain list items rather than a nested Wrap of their own.
      actions: [
        if (onDelete != null)
          AppButton(
            variant: AppButtonVariant.destructive,
            size: AppButtonSize.medium,
            icon: AppIcons.delete,
            onPressed: onDelete,
            child: Text(
              compact ? l10n.commonDelete : l10n.titleDetailDelete,
            ),
          ),
        if (onEdit != null)
          AppButton(
            size: AppButtonSize.medium,
            onPressed: onEdit,
            child: Text(
              compact ? l10n.commonEdit : l10n.titleDetailEdit(title.title),
            ),
          ),
      ],
    );
  }
}

class _MetaDot extends StatelessWidget {
  const _MetaDot();

  @override
  Widget build(BuildContext context) {
    return Text(
      '·',
      style: context.appTextStyles.body.copyWith(
        color: context.appColors.textMuted,
      ),
    );
  }
}
