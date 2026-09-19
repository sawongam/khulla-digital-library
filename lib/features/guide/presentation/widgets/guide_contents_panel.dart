// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:khulla/features/guide/domain/guide_article.dart';
import 'package:khulla/l10n/l10n.dart';
import 'package:khulla_ui/khulla_ui.dart';

/// The article's table of contents, pinned beside the prose.
///
/// Only drawn on a large window, where the column it occupies is room the
/// text was never going to use. Below that it would be a second list above
/// the article - the reader already has one, on the guide's landing page.
class GuideContentsPanel extends StatelessWidget {
  const GuideContentsPanel({
    required this.article,
    required this.activeAnchor,
    required this.onSelected,
    super.key,
  });

  /// Whose contents these are.
  final GuideArticle article;

  /// The section nearest the top of the viewport.
  final String? activeAnchor;

  /// Jumps to a section.
  final void Function(GuideSection section) onSelected;

  @override
  Widget build(BuildContext context) {
    final spacing = context.appSpacing;
    final type = context.appTextStyles;
    final colors = context.appColors;
    final scheme = context.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          context.l10n.guideOnThisPage,
          style: type.micro.copyWith(
            color: colors.ink400,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: spacing.xs),
        for (final section in article.sections)
          _ContentsRow(
            label: section.title,
            selected: section.anchor == activeAnchor,
            onTap: () => onSelected(section),
            accent: scheme.primary,
          ),
      ],
    );
  }
}

class _ContentsRow extends StatelessWidget {
  const _ContentsRow({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.accent,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final spacing = context.appSpacing;
    final colors = context.appColors;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: spacing.xxs),
          // The row stretches its marker to the height of the label, and a
          // row inside a `mainAxisSize.min` column has no height to stretch
          // to until something measures one. IntrinsicHeight is that
          // measurement; without it `stretch` asserts on an unlaid-out box.
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // The marker is a rule rather than a dot, so a wrapped
                // two-line entry still reads as one selected item.
                Container(
                  width: 2,
                  constraints: const BoxConstraints(minHeight: 18),
                  color: selected ? accent : colors.hairline,
                ),
                SizedBox(width: spacing.xs),
                Expanded(
                  child: Text(
                    label,
                    style: context.appTextStyles.caption.copyWith(
                      color: selected ? colors.textHigh : colors.textMuted,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
