// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:khulla/features/catalog/copy/domain/models/copy.dart';
import 'package:khulla/l10n/l10n.dart';
import 'package:khulla/shared/components/section_card.dart';
import 'package:khulla_ui/khulla_ui.dart';

/// The copies added to this checkout so far.
///
/// The scan field keeps focus and stays at the top: at a busy desk the
/// barcode reader is the only input, and every scan should land in the same
/// place without a click in between.
class CheckOutBasket extends StatelessWidget {
  const CheckOutBasket({
    required this.copies,
    required this.scanController,
    required this.onScanSubmitted,
    required this.onRemove,
    super.key,
  });

  final List<Copy> copies;

  /// The scan field's controller, owned by the page so it can be cleared
  /// after every submission.
  final TextEditingController scanController;

  final ValueChanged<String> onScanSubmitted;
  final void Function(Copy copy) onRemove;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final spacing = context.appSpacing;
    final scheme = context.colorScheme;

    return SectionCard(
      title: l10n.checkOutCopiesSection,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          AppTextField(
            controller: scanController,
            hintText: l10n.checkOutScanHint,
            prefixIcon: AppIcon(
              AppIcons.scan,
              size: context.appMetrics.icon,
              color: scheme.onSurfaceVariant,
            ),
            textInputAction: TextInputAction.done,
            onSubmitted: onScanSubmitted,
            onChanged: (_) {},
          ),
          SizedBox(height: spacing.md),
          if (copies.isEmpty)
            AppEmptyView(
              variant: AppFeedbackVariant.inline,
              title: l10n.checkOutCopiesEmptyTitle,
              message: l10n.checkOutCopiesEmptyBody,
            )
          else
            AppTable<Copy>(
              items: copies,
              columns: [
                AppTableColumn<Copy>(
                  id: 'barcode',
                  label: l10n.fieldBarcode,
                  flex: 2,
                  cellBuilder: (context, copy) => Text(copy.barcode),
                ),
                AppTableColumn<Copy>(
                  id: 'title',
                  label: l10n.loansColumnTitle,
                  flex: 4,
                  showFrom: FormFactor.medium,
                  cellBuilder: (context, copy) => Text(copy.titleName),
                ),
                AppTableColumn<Copy>(
                  id: 'shelf',
                  label: l10n.copiesColumnShelf,
                  flex: 2,
                  showFrom: FormFactor.large,
                  cellBuilder: (context, copy) => Text(
                    copy.shelf,
                    style: context.textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
                AppTableColumn<Copy>(
                  id: 'remove',
                  label: l10n.commonActions,
                  alignment: Alignment.centerRight,
                  cellBuilder: (context, copy) => AppIconButton(
                    icon: AppIcons.close,
                    tooltip: l10n.checkOutRemoveCopy,
                    tone: AppStatusTone.danger,
                    onPressed: () => onRemove(copy),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
