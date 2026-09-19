// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:go_router/go_router.dart';
import 'package:khulla/core/lifecycle/dispose_bag.dart';
import 'package:khulla/core/router/routes.dart';
import 'package:khulla/features/guide/domain/guide_article.dart';
import 'package:khulla/features/guide/domain/guide_topic.dart';
import 'package:khulla/features/guide/presentation/guide_content.dart';
import 'package:khulla/features/guide/presentation/widgets/guide_hero.dart';
import 'package:khulla/features/guide/presentation/widgets/guide_search_results.dart';
import 'package:khulla/features/guide/presentation/widgets/guide_topic_card.dart';
import 'package:khulla/l10n/l10n.dart';
import 'package:khulla_ui/khulla_ui.dart';

/// The manual's front door: what Khulla does, section by section.
///
/// It holds no cubit because it reads nothing. The guide is built from
/// [AppLocalizations] on every build, and the only state on the screen is the
/// search query - which belongs to the field, not to the app.
class GuidePage extends StatefulWidget {
  const GuidePage({super.key});

  @override
  State<GuidePage> createState() => _GuidePageState();
}

class _GuidePageState extends State<GuidePage> with DisposeBag {
  late final TextEditingController _search = textController();
  String _query = '';

  /// Sections matching the query, in the order the manual lists them.
  ///
  /// A plain substring match over a few hundred sentences already in memory.
  /// Anything cleverer - stemming, ranking - would be guessing at which of
  /// eight articles the reader meant, and the section titles are short enough
  /// that the list stays readable unranked.
  List<GuideSearchHit> _hits(List<GuideArticle> articles) {
    final needle = _query.trim().toLowerCase();
    if (needle.isEmpty) return const [];

    return [
      for (final article in articles)
        for (final section in article.sections)
          if ('${article.title} ${section.searchText}'.toLowerCase().contains(
            needle,
          ))
            GuideSearchHit(article, section),
    ];
  }

  void _openArticle(GuideTopic topic, {String? anchor}) {
    final path = Routes.guideTopic(topic.slug);
    context.go(
      anchor == null ? path : '$path?section=${Uri.encodeComponent(anchor)}',
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final spacing = context.appSpacing;
    final type = context.appTextStyles;
    final colors = context.appColors;
    final articles = guideArticles(l10n);
    final searching = _query.trim().isNotEmpty;

    return AppPageBody(
      wide: true,
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          spacing.page,
          spacing.lg,
          spacing.page,
          spacing.xlg,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GuideHero(
              controller: _search,
              onQueryChanged: (value) => setState(() => _query = value),
              onStartWalkthrough: () => _openArticle(GuideTopic.gettingStarted),
            ),
            SizedBox(height: spacing.lg),
            if (searching)
              GuideSearchResults(
                hits: _hits(articles),
                onOpen: (hit) => _openArticle(
                  hit.article.topic,
                  anchor: hit.section.anchor,
                ),
              )
            else ...[
              Text(
                l10n.guideBrowseTitle,
                style: type.title.copyWith(color: colors.textHigh),
              ),
              SizedBox(height: spacing.xxs),
              Text(
                l10n.guideBrowseBody,
                style: type.body.copyWith(color: colors.textMuted),
              ),
              SizedBox(height: spacing.md),
              AppResponsiveGrid(
                expandedColumns: 2,
                largeColumns: 3,
                children: [
                  for (final article in articles)
                    GuideTopicCard(
                      article: article,
                      onTap: () => _openArticle(article.topic),
                    ),
                ],
              ),
              SizedBox(height: spacing.lg),
              AppCard(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppIcon(
                      AppIcons.support,
                      size: context.appMetrics.icon,
                      color: colors.ink400,
                    ),
                    SizedBox(width: spacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.guideFooterTitle,
                            style: type.sectionTitle.copyWith(
                              color: colors.textHigh,
                            ),
                          ),
                          SizedBox(height: spacing.xxs),
                          Text(
                            l10n.guideFooterBody,
                            style: type.body.copyWith(color: colors.textMuted),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
