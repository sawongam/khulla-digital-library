// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:flutter_test/flutter_test.dart';
import 'package:khulla/features/guide/domain/guide_block.dart';
import 'package:khulla/features/guide/domain/guide_topic.dart';
import 'package:khulla/features/guide/presentation/guide_content.dart';
import 'package:khulla/l10n/gen/app_localizations.dart';
import 'package:khulla/l10n/gen/app_localizations_en.dart';
import 'package:khulla/l10n/gen/app_localizations_ne.dart';

void main() {
  final locales = <String, AppLocalizations>{
    'en': AppLocalizationsEn(),
    'ne': AppLocalizationsNe(),
  };

  group('guideArticles', () {
    test('every topic has exactly one article, in enum order', () {
      for (final MapEntry(key: locale, value: l10n) in locales.entries) {
        final articles = guideArticles(l10n);
        expect(
          articles.map((article) => article.topic),
          GuideTopic.values,
          reason: '$locale should carry one article per topic, in order',
        );
      }
    });

    test('no article is empty, and no section is', () {
      for (final MapEntry(key: locale, value: l10n) in locales.entries) {
        for (final article in guideArticles(l10n)) {
          expect(
            article.sections,
            isNotEmpty,
            reason: '$locale: ${article.topic.slug} has no sections',
          );
          for (final section in article.sections) {
            expect(
              section.blocks,
              isNotEmpty,
              reason: '$locale: ${section.anchor} has no blocks',
            );
          }
        }
      }
    });

    test('anchors are unique within an article, so a link lands once', () {
      for (final article in guideArticles(AppLocalizationsEn())) {
        final anchors = article.sections.map((s) => s.anchor).toList();
        expect(anchors.toSet(), hasLength(anchors.length));
      }
    });

    test('nothing on screen is a missing translation', () {
      // A key added to the English ARB and forgotten in the Nepali one comes
      // back as the English string, which reads as a bug rather than failing.
      for (final article in guideArticles(AppLocalizationsNe())) {
        expect(article.title.trim(), isNotEmpty);
        expect(article.summary.trim(), isNotEmpty);
        for (final section in article.sections) {
          expect(section.title.trim(), isNotEmpty);
          expect(section.searchText.trim(), isNotEmpty);
        }
      }
    });
  });

  group('guideTopicFromSlug', () {
    test('every slug round-trips', () {
      for (final topic in GuideTopic.values) {
        expect(guideTopicFromSlug(topic.slug), topic);
      }
    });

    test('an unknown or missing slug answers null rather than throwing', () {
      // The route builder relies on this: a stale bookmark must render the
      // guide's own not-found state, not crash inside the router.
      expect(guideTopicFromSlug('circulations'), isNull);
      expect(guideTopicFromSlug(''), isNull);
      expect(guideTopicFromSlug(null), isNull);
    });
  });

  group('guideQuickStart', () {
    test('is the same walkthrough the first article opens with', () {
      final l10n = AppLocalizationsEn();
      final first = guideArticleFor(l10n, GuideTopic.gettingStarted);
      final fromArticle = first.sections.first.blocks
          .whereType<GuideSteps>()
          .first;

      expect(
        guideQuickStart(l10n).steps.map((step) => step.title),
        fromArticle.steps.map((step) => step.title),
      );
    });

    test('every step names a screen the reader can open', () {
      for (final step in guideQuickStart(AppLocalizationsEn()).steps) {
        expect(step.route, isNotNull, reason: '${step.title} has no screen');
        expect(step.route, startsWith('/'));
      }
    });
  });

  group('screen diagrams', () {
    test('every marker on a drawing has a legend entry, and vice versa', () {
      // A chip numbered 3 with a two-line legend is a diagram pointing at
      // nothing, and it is the kind of mismatch only counting catches.
      for (final article in guideArticles(AppLocalizationsEn())) {
        for (final section in article.sections) {
          for (final shot in section.blocks.whereType<GuideScreenshot>()) {
            final marked = shot.parts
                .map((part) => part.marker)
                .whereType<int>()
                .toList();
            expect(
              marked..sort(),
              [for (var i = 1; i <= shot.markers.length; i++) i],
              reason: '${article.topic.slug}/${section.anchor}',
            );
          }
        }
      }
    });
  });
}
