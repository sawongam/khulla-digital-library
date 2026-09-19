// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:khulla/features/guide/domain/guide_block.dart';
import 'package:khulla/features/guide/domain/guide_topic.dart';

/// One topic's article: a heading, a promise, and the sections under it.
class GuideArticle {
  const GuideArticle({
    required this.topic,
    required this.title,
    required this.summary,
    required this.sections,
    this.route,
  });

  /// Which topic this is.
  final GuideTopic topic;

  /// The article's name, as the card and the header both say it.
  final String title;

  /// One line on what the reader will be able to do afterwards.
  final String summary;

  /// The sections, in reading order.
  final List<GuideSection> sections;

  /// The screen the article is about, when it is about one. The article
  /// header offers it as *Open this screen*, so the manual can be read with
  /// the thing it describes one click away.
  final String? route;

  /// Everything searchable in the article, joined.
  String get searchText => [
    title,
    summary,
    for (final section in sections) section.searchText,
  ].join(' ');
}

/// One heading inside an article, and the blocks under it.
///
/// A section is also the unit the table of contents lists and the unit search
/// returns, which is why it carries an [anchor]: the contents jump to it, and
/// a result opens the article scrolled to it.
class GuideSection {
  const GuideSection({
    required this.anchor,
    required this.title,
    required this.blocks,
  });

  /// A slug unique within the article - the scroll target.
  final String anchor;

  /// The heading.
  final String title;

  /// The content under it, in reading order.
  final List<GuideBlock> blocks;

  /// The heading plus everything in the blocks.
  String get searchText =>
      [title, for (final block in blocks) block.searchText].join(' ');
}
