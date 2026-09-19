// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:khulla/app/shell/widgets/shell_destinations.dart';
import 'package:khulla/core/router/routes.dart';
import 'package:khulla/features/guide/domain/guide_topic.dart';
import 'package:khulla/features/guide/presentation/guide_content.dart';
import 'package:khulla/features/users/domain/user_role.dart';
import 'package:khulla/l10n/l10n.dart';
import 'package:khulla_ui/khulla_ui.dart';

/// What the top bar says for a given location.
class ShellPageTitle {
  const ShellPageTitle({required this.title, this.crumbs = const []});

  /// The page's name.
  final String title;

  /// The trail above it, root first, current page last. Empty on a section's
  /// own landing page, where a trail would only repeat the title.
  final List<AppBreadcrumb> crumbs;
}

/// Resolves the top bar's title and breadcrumb trail from the router's
/// current location.
///
/// The shell owns this rather than each page, because the bar lives in the
/// shell: a page that set its own title would have to reach up through an
/// inherited widget on every build, and a page pushed on the root navigator
/// would silently leave the bar showing the last section's name.
///
/// It reads the location as a path, not as a route name, so a deep link that
/// arrives from a browser address bar produces the same trail as a click.
ShellPageTitle shellPageTitle(
  BuildContext context,
  String location,
  AppLocalizations l10n, {
  required UserRole role,
  required void Function(String route) onNavigate,
}) {
  final destinations = shellDestinations(l10n, role);

  // The manual is no rail destination - it opens from the account menu -
  // so neither its landing page nor its articles match the loop below.
  // The articles are a topic enum rather than declared children, so they
  // are resolved here instead.
  if (Routes.isUnder(location, Routes.guide)) {
    if (location == Routes.guide) {
      return ShellPageTitle(title: l10n.navGuide);
    }
    final topic = guideTopicFromSlug(location.split('/').last);
    if (topic != null) {
      final article = guideArticleFor(l10n, topic);
      return ShellPageTitle(
        title: article.title,
        crumbs: [
          AppBreadcrumb(
            label: l10n.navGuide,
            onTap: () => onNavigate(Routes.guide),
          ),
          AppBreadcrumb(label: article.title),
        ],
      );
    }
    return ShellPageTitle(title: l10n.navGuide);
  }

  for (final destination in destinations) {
    if (!Routes.isUnder(location, destination.route)) continue;

    final root = AppBreadcrumb(
      label: destination.label,
      onTap: () => onNavigate(destination.route),
    );

    // The deepest declared child that still contains the location names the
    // page; anything past it is a record, which the page itself titles.
    ShellChild? matched;
    for (final child in destination.children) {
      if (Routes.isUnder(location, child.route) &&
          (matched == null || child.route.length > matched.route.length)) {
        matched = child;
      }
    }

    if (matched == null) {
      return ShellPageTitle(title: destination.label);
    }

    return ShellPageTitle(
      title: matched.label,
      crumbs: [
        root,
        AppBreadcrumb(label: matched.label),
      ],
    );
  }

  return ShellPageTitle(title: l10n.appName);
}
