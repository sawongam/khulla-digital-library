// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:khulla_ui/khulla_ui.dart';

/// One article of the manual - one per section of the app, plus the
/// walkthrough that comes before any of them.
///
/// The order is the order the guide lists them in, and it is the order a
/// library actually meets the app: set it up, watch the day, build the
/// catalogue, work the desk, then the things you open once a week.
///
/// [slug] is the URL segment, so it is part of the app's public surface:
/// a link handed to a colleague, or a bookmark, resolves through
/// [guideTopicFromSlug]. Renaming one breaks those links, which is why the
/// slug is written out rather than derived from the enum's name.
enum GuideTopic {
  gettingStarted('getting-started', AppIcons.discover),
  dashboard('dashboard', AppIcons.dashboard),
  catalog('catalog', AppIcons.book),
  circulation('circulation', AppIcons.transfer),
  members('members', AppIcons.people),
  reports('reports', AppIcons.insights),
  staff('staff', AppIcons.idCard),
  settings('settings', AppIcons.settings);

  GuideTopic(this.slug, this.icon);

  /// The URL segment under `/guide`.
  final String slug;

  /// The glyph the topic card and the article header wear.
  final AppIconSpec icon;
}

/// The topic [slug] names, or null when nothing does.
///
/// Null is a real answer rather than a failure: a typed or stale
/// `/guide/whatever` renders the guide's own "no such article" state instead
/// of throwing inside a route builder.
GuideTopic? guideTopicFromSlug(String? slug) {
  for (final topic in GuideTopic.values) {
    if (topic.slug == slug) return topic;
  }
  return null;
}
