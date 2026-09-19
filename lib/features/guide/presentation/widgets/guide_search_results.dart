// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:khulla/features/guide/domain/guide_article.dart';
import 'package:khulla/l10n/l10n.dart';
import 'package:khulla_ui/khulla_ui.dart';

/// One section that matched a query, with the article it came from.
class GuideSearchHit {
  const GuideSearchHit(this.article, this.section);

  /// Which article it lives in.
  final GuideArticle article;

  /// The section itself.
  final GuideSection section;
}

/// The sections matching whatever is in the search field.
///
/// Search returns *sections* rather than articles, because an article is
/// eight screens of prose and "it is in Circulation somewhere" is not an
/// answer. Opening a hit lands on the heading that matched.
class GuideSearchResults extends StatelessWidget {
  const GuideSearchResults({
    required this.hits,
    required this.onOpen,
    super.key,
  });

  /// What matched, in article order.
  final List<GuideSearchHit> hits;

  /// Opens one, scrolled to its section.
  final void Function(GuideSearchHit hit) onOpen;

  @override
  Widget build(BuildContext context) {
    final spacing = context.appSpacing;
    final type = context.appTextStyles;
    final colors = context.appColors;
    final l10n = context.l10n;

    if (hits.isEmpty) {
      return AppEmptyView(
        icon: AppIcons.noResults,
        title: l10n.guideSearchEmptyTitle,
        message: l10n.guideSearchEmptyBody,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.guideSearchResults(hits.length),
          style: type.micro.copyWith(color: colors.ink400),
        ),
        SizedBox(height: spacing.sm),
        for (final hit in hits)
          Padding(
            padding: EdgeInsets.only(bottom: spacing.xs),
            child: AppCard(
              onTap: () => onOpen(hit),
              child: Row(
                children: [
                  AppIcon(
                    hit.article.topic.icon,
                    size: 16,
                    color: colors.ink400,
                  ),
                  SizedBox(width: spacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          hit.section.title,
                          style: type.label.copyWith(color: colors.textHigh),
                        ),
                        SizedBox(height: spacing.xxs),
                        Text(
                          hit.article.title,
                          style: type.caption.copyWith(
                            color: colors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  AppIcon(
                    AppIcons.chevronRight,
                    size: 16,
                    color: colors.ink400,
                    matchTextDirection: true,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
