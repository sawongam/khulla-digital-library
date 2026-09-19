// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:khulla/features/catalog/shared/presentation/catalog_labels.dart';
import 'package:khulla/features/catalog/title/domain/models/title.dart'
    as catalog;
import 'package:khulla/l10n/l10n.dart';
import 'package:khulla/shared/components/section_card.dart';
import 'package:khulla_ui/khulla_ui.dart';

/// The bibliographic and shelving record in one card.
///
/// [AppDetailRow] stacks its label above its value when the slot is narrow,
/// so the same card works in a half-width column beside the copies list and
/// full width on a phone. Publication facts and library facts share one
/// surface rather than two uneven cards - shelf and lending are short lines
/// that do not need their own panel.
class TitleDetailsCard extends StatelessWidget {
  const TitleDetailsCard({required this.title, super.key});

  final catalog.Title title;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final spacing = context.appSpacing;
    final colors = context.appColors;
    final notSet = l10n.commonNotSet;
    final pages = title.pages;

    return SectionCard(
      title: l10n.titleDetailOverview,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final (index, row) in <(String, String)>[
            (l10n.fieldIsbn, title.isbn ?? notSet),
            (l10n.fieldPublisher, title.publisher ?? notSet),
            (
              l10n.fieldPublishedYear,
              title.year.isEmpty ? notSet : title.year,
            ),
            (l10n.fieldEdition, title.edition ?? notSet),
            (l10n.fieldLanguage, title.language),
            (l10n.fieldFormat, title.formatCode.formatLabel(l10n)),
            (l10n.fieldPages, pages == null ? notSet : '$pages'),
          ].indexed) ...[
            if (index > 0) SizedBox(height: spacing.sm),
            AppDetailRow(label: row.$1, child: Text(row.$2)),
          ],
          Padding(
            padding: EdgeInsets.symmetric(vertical: spacing.md),
            child: Divider(height: 1, color: colors.hairline),
          ),
          for (final (index, row) in <(String, String)>[
            (l10n.fieldShelf, title.shelf ?? notSet),
            (
              l10n.titleDetailLendable,
              title.lendable
                  ? l10n.titleDetailLendableYes
                  : l10n.titlesReferenceOnly,
            ),
            (l10n.fieldAddedOn, title.addedOn),
          ].indexed) ...[
            if (index > 0) SizedBox(height: spacing.sm),
            AppDetailRow(label: row.$1, child: Text(row.$2)),
          ],
        ],
      ),
    );
  }
}
