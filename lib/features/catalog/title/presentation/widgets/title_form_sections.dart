// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:khulla/features/catalog/shared/presentation/catalog_labels.dart';
import 'package:khulla/features/catalog/title/domain/models/title_format.dart';
import 'package:khulla/l10n/l10n.dart';
import 'package:khulla_ui/khulla_ui.dart';

/// The bibliographic half of the title form: title and author, the
/// imprint row, the format row, and the description.
///
/// Error strings arrive as parameters and clear through the matching
/// callbacks so validation state stays with the dialog.
class TitleFormBibliographicSection extends StatelessWidget {
  const TitleFormBibliographicSection({
    required this.title,
    required this.author,
    required this.isbn,
    required this.publisher,
    required this.year,
    required this.edition,
    required this.pages,
    required this.language,
    required this.description,
    required this.formats,
    required this.selectedFormat,
    required this.titleError,
    required this.authorError,
    required this.formatError,
    required this.onTitleChanged,
    required this.onAuthorChanged,
    required this.onFormatChanged,
    required this.onAddFormat,
    required this.isLookingUpIsbn,
    required this.onLookUpIsbn,
    super.key,
  });

  final TextEditingController title;
  final TextEditingController author;
  final TextEditingController isbn;
  final TextEditingController publisher;
  final TextEditingController year;
  final TextEditingController edition;
  final TextEditingController pages;
  final TextEditingController language;
  final TextEditingController description;
  final List<TitleFormat> formats;
  final TitleFormat? selectedFormat;
  final String? titleError;
  final String? authorError;
  final String? formatError;
  final VoidCallback onTitleChanged;
  final VoidCallback onAuthorChanged;
  final ValueChanged<TitleFormat?> onFormatChanged;
  final VoidCallback onAddFormat;

  /// True while the ISBN lookup request is out.
  final bool isLookingUpIsbn;

  /// Asks the online catalogue about the ISBN field's value.
  final VoidCallback onLookUpIsbn;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return AppFormSection(
      title: l10n.titleFormBibliographic,
      children: [
        AppFormRow(
          flexes: const [3, 2],
          children: [
            AppTextField(
              label: l10n.fieldTitle,
              required: true,
              controller: title,
              errorText: titleError,
              textCapitalization: TextCapitalization.words,
              onChanged: (_) => onTitleChanged(),
            ),
            AppTextField(
              label: l10n.fieldAuthor,
              required: true,
              controller: author,
              errorText: authorError,
              textCapitalization: TextCapitalization.words,
              onChanged: (_) => onAuthorChanged(),
            ),
          ],
        ),
        AppFormRow(
          children: [
            _IsbnField(
              controller: isbn,
              isLookingUp: isLookingUpIsbn,
              onLookUp: onLookUpIsbn,
            ),
            AppTextField(
              label: l10n.fieldPublisher,
              controller: publisher,
              textCapitalization: TextCapitalization.words,
              onChanged: (_) {},
            ),
            AppTextField(
              label: l10n.fieldPublishedYear,
              controller: year,
              keyboardType: TextInputType.number,
              onChanged: (_) {},
            ),
          ],
        ),
        AppFormRow(
          children: [
            AppTextField(
              label: l10n.fieldEdition,
              controller: edition,
              onChanged: (_) {},
            ),
            AppTextField(
              label: l10n.fieldPages,
              controller: pages,
              keyboardType: TextInputType.number,
              onChanged: (_) {},
            ),
            AppDropdownField<TitleFormat>(
              label: l10n.fieldFormat,
              required: true,
              value: selectedFormat,
              items: formats,
              itemLabel: (format) => format.label(l10n),
              itemIcon: (format) => format.icon,
              errorText: formatError,
              footerActionLabel: l10n.titleFormAddFormat,
              onFooterAction: onAddFormat,
              onChanged: onFormatChanged,
            ),
            AppTextField(
              label: l10n.fieldLanguage,
              controller: language,
              textCapitalization: TextCapitalization.words,
              onChanged: (_) {},
            ),
          ],
        ),
        AppTextField(
          label: l10n.fieldDescription,
          controller: description,
          maxLines: 3,
          minLines: 2,
          textCapitalization: TextCapitalization.sentences,
          onChanged: (_) {},
        ),
      ],
    );
  }
}

/// The ISBN field with its "Look up" button beside it.
///
/// The button is disabled until the field has text, and shows a spinner while
/// the request is out. It listens to the controller itself so typing does not
/// rebuild the whole form.
class _IsbnField extends StatelessWidget {
  const _IsbnField({
    required this.controller,
    required this.isLookingUp,
    required this.onLookUp,
  });

  final TextEditingController controller;
  final bool isLookingUp;
  final VoidCallback onLookUp;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final spacing = context.appSpacing;
    final size = context.appMetrics.fieldHeight >= 44
        ? AppButtonSize.medium
        : AppButtonSize.small;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: AppTextField(
            label: l10n.fieldIsbn,
            controller: controller,
            onChanged: (_) {},
          ),
        ),
        SizedBox(width: spacing.sm),
        ListenableBuilder(
          listenable: controller,
          builder: (context, _) => Tooltip(
            message: l10n.isbnLookUpTooltip,
            child: AppButton(
              variant: AppButtonVariant.secondary,
              size: size,
              icon: AppIcons.search,
              isLoading: isLookingUp,
              onPressed: controller.text.trim().isEmpty ? null : onLookUp,
              child: Text(l10n.isbnLookUp),
            ),
          ),
        ),
      ],
    );
  }
}

/// The shelving half of the title form: shelf mark, replacement cost, the
/// initial-copies stepper on create, and the lendable switch.
class TitleFormShelvingSection extends StatelessWidget {
  const TitleFormShelvingSection({
    required this.shelf,
    required this.replacementCost,
    required this.initialCopies,
    required this.isEditing,
    required this.costError,
    required this.copiesError,
    required this.lendable,
    required this.onCostChanged,
    required this.onCopiesChanged,
    required this.onLendableChanged,
    super.key,
  });

  final TextEditingController shelf;
  final TextEditingController replacementCost;
  final TextEditingController initialCopies;
  final bool isEditing;
  final String? costError;
  final String? copiesError;
  final bool lendable;
  final VoidCallback onCostChanged;
  final VoidCallback onCopiesChanged;
  final ValueChanged<bool> onLendableChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return AppFormSection(
      title: l10n.titleFormShelving,
      description: l10n.titleFormShelvingDescription,
      children: [
        AppFormRow(
          // The stepper keeps its compact width while its control stays
          // fieldHeight tall like the text fields: flex 0 stops the row
          // stretching it full-width. Stacks below 480px so the labels
          // still fit when side by side.
          flexes: isEditing ? null : const [2, 2, 0],
          stackBelow: isEditing ? null : 480,
          children: [
            AppTextField(
              label: l10n.fieldShelf,
              controller: shelf,
              onChanged: (_) {},
            ),
            AppTextField(
              label: l10n.fieldReplacementCost,
              controller: replacementCost,
              errorText: costError,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              onChanged: (_) => onCostChanged(),
            ),
            if (!isEditing)
              AppQuantityField(
                label: l10n.titleFormInitialCopies,
                required: true,
                controller: initialCopies,
                errorText: copiesError,
                decreaseTooltip: l10n.commonDecrease,
                increaseTooltip: l10n.commonIncrease,
                onChanged: (_) => onCopiesChanged(),
              ),
          ],
        ),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: FractionallySizedBox(
            widthFactor: 0.4,
            child: AppSwitchField(
              value: lendable,
              label: l10n.titleFormLendable,
              description: l10n.titleFormLendableDescription,
              stacked: true,
              onChanged: onLendableChanged,
            ),
          ),
        ),
      ],
    );
  }
}
