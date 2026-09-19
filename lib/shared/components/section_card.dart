// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:khulla_ui/khulla_ui.dart';

/// A titled card: [AppSectionHeader] over a body, with the app's rhythm.
///
/// The shape every section of a detail page, a form column and a desk screen
/// takes, so two cards side by side share a heading size and an inset instead
/// of each finding their own.
///
/// Pass [bodyPadding] as [EdgeInsets.zero] when the body paints to the card's
/// edge - a table, a divided list - and the header keeps its own inset.
class SectionCard extends StatelessWidget {
  const SectionCard({
    required this.title,
    required this.child,
    this.subtitle,
    this.icon,
    this.trailing,
    this.bodyPadding,
    super.key,
  });

  /// Section heading.
  final String title;

  /// The section's body.
  final Widget child;

  /// Supporting line under [title].
  final String? subtitle;

  /// Glyph beside the heading.
  final AppIconSpec? icon;

  /// The section's single action - a button, or an [AppMenuButton].
  final Widget? trailing;

  /// Inset around [child]. Defaults to none, since the card already pads.
  final EdgeInsetsGeometry? bodyPadding;

  @override
  Widget build(BuildContext context) {
    final spacing = context.appSpacing;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          AppSectionHeader(
            title: title,
            subtitle: subtitle,
            icon: icon,
            trailing: trailing,
            dense: true,
          ),
          SizedBox(height: spacing.md),
          Padding(
            padding: bodyPadding ?? EdgeInsets.zero,
            child: child,
          ),
        ],
      ),
    );
  }
}
