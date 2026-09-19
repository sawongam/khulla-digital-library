// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:khulla/features/guide/domain/guide_block.dart';
import 'package:khulla_ui/khulla_ui.dart';

/// A vocabulary list: the word on one side, what it means here on the other.
///
/// It stacks to one column on a phone rather than squeezing two — a
/// definition wrapped to three words a line is harder to read than the term
/// sitting above it.
class GuideTermList extends StatelessWidget {
  const GuideTermList(this.terms, {super.key});

  /// The entries, in the order they are met on the screen.
  final GuideTerms terms;

  @override
  Widget build(BuildContext context) {
    final spacing = context.appSpacing;
    final type = context.appTextStyles;
    final colors = context.appColors;
    final stacked = context.formFactor.isCompact;
    final entries = terms.terms;

    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (index, entry) in entries.indexed)
            DecoratedBox(
              decoration: BoxDecoration(
                border: index == 0
                    ? null
                    : Border(top: BorderSide(color: colors.hairline)),
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: spacing.md,
                  vertical: spacing.sm,
                ),
                child: stacked
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            entry.term,
                            style: type.label.copyWith(color: colors.textHigh),
                          ),
                          SizedBox(height: spacing.xxs),
                          Text(
                            entry.meaning,
                            style: type.body.copyWith(color: colors.textMuted),
                          ),
                        ],
                      )
                    : Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 160,
                            child: Text(
                              entry.term,
                              style: type.label.copyWith(
                                color: colors.textHigh,
                              ),
                            ),
                          ),
                          SizedBox(width: spacing.md),
                          Expanded(
                            child: Text(
                              entry.meaning,
                              style: type.body.copyWith(
                                color: colors.textMuted,
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
            ),
        ],
      ),
    );
  }
}
