// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:khulla/features/catalog/label/domain/models/label_queue_entry.dart';
import 'package:khulla/features/catalog/label/domain/models/label_size.dart';
import 'package:khulla/features/catalog/label/presentation/label_labels.dart';
import 'package:khulla/features/catalog/label/presentation/widgets/label_preview.dart';
import 'package:khulla/l10n/l10n.dart';
import 'package:khulla/shared/components/section_card.dart';
import 'package:khulla_ui/khulla_ui.dart';

/// The layout card: sticker size plus which lines print on it.
///
/// Dumb by design — every toggle calls back out to the cubit.
class LabelLayoutCard extends StatelessWidget {
  const LabelLayoutCard({
    required this.size,
    required this.includeTitle,
    required this.includeAuthor,
    required this.includeShelf,
    required this.includeLibrary,
    required this.onSizeChanged,
    required this.onIncludeTitleChanged,
    required this.onIncludeAuthorChanged,
    required this.onIncludeShelfChanged,
    required this.onIncludeLibraryChanged,
    super.key,
  });

  final LabelSize size;
  final bool includeTitle;
  final bool includeAuthor;
  final bool includeShelf;
  final bool includeLibrary;
  final ValueChanged<LabelSize> onSizeChanged;
  final ValueChanged<bool> onIncludeTitleChanged;
  final ValueChanged<bool> onIncludeAuthorChanged;
  final ValueChanged<bool> onIncludeShelfChanged;
  final ValueChanged<bool> onIncludeLibraryChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final spacing = context.appSpacing;

    return SectionCard(
      title: l10n.labelsLayoutTitle,
      subtitle: l10n.labelsLayoutSubtitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          AppDropdownField<LabelSize>(
            label: l10n.labelsSizeTitle,
            value: size,
            items: LabelSize.values,
            itemLabel: (size) => size.label(l10n),
            onChanged: (size) {
              if (size != null) onSizeChanged(size);
            },
          ),
          SizedBox(height: spacing.md),
          AppCheckboxField(
            label: l10n.labelsIncludeTitle,
            value: includeTitle,
            onChanged: (value) => onIncludeTitleChanged(value ?? false),
          ),
          AppCheckboxField(
            label: l10n.labelsIncludeAuthor,
            value: includeAuthor,
            onChanged: (value) => onIncludeAuthorChanged(value ?? false),
          ),
          AppCheckboxField(
            label: l10n.labelsIncludeShelf,
            value: includeShelf,
            onChanged: (value) => onIncludeShelfChanged(value ?? false),
          ),
          AppCheckboxField(
            label: l10n.labelsIncludeLibrary,
            value: includeLibrary,
            onChanged: (value) => onIncludeLibraryChanged(value ?? false),
          ),
        ],
      ),
    );
  }
}

/// The preview card: the first queued sticker at print size, plus the print
/// action.
class LabelPreviewCard extends StatelessWidget {
  const LabelPreviewCard({
    required this.queue,
    required this.size,
    required this.includeTitle,
    required this.includeAuthor,
    required this.includeShelf,
    required this.includeLibrary,
    required this.libraryName,
    required this.isPrinting,
    required this.onPrint,
    super.key,
  });

  final List<LabelQueueEntry> queue;
  final LabelSize size;
  final bool includeTitle;
  final bool includeAuthor;
  final bool includeShelf;
  final bool includeLibrary;
  final String? libraryName;
  final bool isPrinting;
  final VoidCallback onPrint;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final spacing = context.appSpacing;

    return SectionCard(
      title: l10n.labelsPreviewTitle,
      subtitle: l10n.labelsPreviewSubtitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (queue.isEmpty)
            Padding(
              padding: EdgeInsets.symmetric(vertical: spacing.lg),
              child: Center(
                child: Text(
                  l10n.labelsPreviewEmpty,
                  textAlign: TextAlign.center,
                  style: context.textTheme.bodyMedium?.copyWith(
                    color: context.appColors.textMuted,
                  ),
                ),
              ),
            )
          else
            Center(
              child: Builder(
                builder: (context) {
                  final entry = queue.first;
                  return LabelPreview(
                    barcode: entry.copy.barcode,
                    width: size.width,
                    height: size.height,
                    title: includeTitle ? entry.copy.titleName : null,
                    author: includeAuthor ? entry.author : null,
                    shelf: includeShelf ? entry.copy.shelf : null,
                    libraryName: includeLibrary ? libraryName : null,
                  );
                },
              ),
            ),
          SizedBox(height: spacing.md),
          AppButton(
            icon: AppIcons.printer,
            onPressed: queue.isEmpty || isPrinting ? null : onPrint,
            child: Text(l10n.labelsPrint),
          ),
        ],
      ),
    );
  }
}
