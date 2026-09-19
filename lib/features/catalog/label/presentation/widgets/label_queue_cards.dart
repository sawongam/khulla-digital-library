// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:khulla/features/catalog/label/domain/models/label_queue_entry.dart';
import 'package:khulla/l10n/l10n.dart';
import 'package:khulla/shared/components/section_card.dart';
import 'package:khulla_ui/khulla_ui.dart';

/// The scan card: a focus-kept field plus the bulk-entry shortcut.
///
/// The page owns the controller and focus node - a handheld scanner is a
/// keyboard, so focus returns here after every submit.
class LabelScanCard extends StatelessWidget {
  const LabelScanCard({
    required this.scanController,
    required this.scanFocus,
    required this.onSubmitted,
    required this.onBulkQueue,
    super.key,
  });

  final TextEditingController scanController;
  final FocusNode scanFocus;
  final ValueChanged<String> onSubmitted;
  final VoidCallback onBulkQueue;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return SectionCard(
      title: l10n.labelsScanTitle,
      subtitle: l10n.labelsScanSubtitle,
      trailing: AppTextButton(
        icon: AppIcons.bulkEntry,
        onPressed: onBulkQueue,
        child: Text(l10n.labelsBulkAction),
      ),
      child: AppTextField(
        controller: scanController,
        focusNode: scanFocus,
        autofocus: true,
        hintText: l10n.labelsScanHint,
        prefixIcon: const AppIcon(AppIcons.barcode),
        textInputAction: TextInputAction.done,
        onChanged: (_) {},
        onSubmitted: onSubmitted,
      ),
    );
  }
}

/// The queue card: every queued sticker with its per-copy count stepper.
///
/// Dumb by design - counts and removals call back out so the cubit writes
/// stay with the page.
class LabelQueueCard extends StatelessWidget {
  const LabelQueueCard({
    required this.queue,
    required this.labelCount,
    required this.onClearQueue,
    required this.onCountChanged,
    required this.onRemove,
    super.key,
  });

  final List<LabelQueueEntry> queue;
  final int labelCount;
  final VoidCallback onClearQueue;
  final void Function(LabelQueueEntry entry, int count) onCountChanged;
  final void Function(LabelQueueEntry entry) onRemove;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.appColors;
    final muted = context.textTheme.bodyMedium?.copyWith(
      color: colors.textMuted,
    );

    return SectionCard(
      title: l10n.labelsQueueTitle,
      subtitle: l10n.labelsQueueSubtitle('$labelCount'),
      trailing: queue.isEmpty
          ? null
          : AppTextButton(
              onPressed: onClearQueue,
              child: Text(l10n.labelsClearQueue),
            ),
      child: queue.isEmpty
          ? AppEmptyView(
              icon: AppIcons.qrCode,
              title: l10n.labelsQueueEmptyTitle,
              message: l10n.labelsQueueEmptyBody,
              variant: AppFeedbackVariant.inline,
            )
          : AppTable<LabelQueueEntry>(
              items: queue,
              columns: [
                AppTableColumn<LabelQueueEntry>(
                  id: 'barcode',
                  label: l10n.labelsColumnBarcode,
                  flex: 2,
                  cellBuilder: (context, entry) => Text(entry.copy.barcode),
                ),
                AppTableColumn<LabelQueueEntry>(
                  id: 'title',
                  label: l10n.labelsColumnTitle,
                  flex: 3,
                  showFrom: FormFactor.medium,
                  cellBuilder: (context, entry) => Text(
                    entry.copy.titleName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                AppTableColumn<LabelQueueEntry>(
                  id: 'shelf',
                  label: l10n.labelsColumnShelf,
                  flex: 2,
                  showFrom: FormFactor.expanded,
                  cellBuilder: (context, entry) =>
                      Text(entry.copy.shelf, style: muted),
                ),
                AppTableColumn<LabelQueueEntry>(
                  id: 'count',
                  label: l10n.labelsColumnCopies,
                  flex: 3,
                  cellBuilder: (context, entry) => LabelCountStepper(
                    count: entry.count,
                    onChanged: (next) => onCountChanged(entry, next),
                  ),
                ),
                AppTableColumn<LabelQueueEntry>(
                  id: 'actions',
                  label: l10n.commonActions,
                  cellBuilder: (context, entry) => AppIconButton(
                    icon: AppIcons.close,
                    tooltip: l10n.labelsRemove,
                    size: AppIconButtonSize.small,
                    onPressed: () => onRemove(entry),
                  ),
                ),
              ],
            ),
    );
  }
}

/// How many stickers one queued copy gets: minus, the number, plus.
class LabelCountStepper extends StatelessWidget {
  const LabelCountStepper({
    required this.count,
    required this.onChanged,
    super.key,
  });

  final int count;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        AppIconButton(
          icon: AppIcons.remove,
          tooltip: l10n.commonDecrease,
          size: AppIconButtonSize.small,
          onPressed: count <= 1 ? null : () => onChanged(count - 1),
        ),
        SizedBox(
          width: 28,
          child: Text(
            '$count',
            textAlign: TextAlign.center,
            style: context.textTheme.bodyMedium,
          ),
        ),
        AppIconButton(
          icon: AppIcons.add,
          tooltip: l10n.commonIncrease,
          size: AppIconButtonSize.small,
          onPressed: () => onChanged(count + 1),
        ),
      ],
    );
  }
}
