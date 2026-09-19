// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:khulla_ui/khulla_ui.dart';

/// One of the dashboard's board sections, with its heading and its body.
///
/// Not every section wants a card. A chart needs a bounded plotting surface,
/// so it keeps one; a ranked list, a set of bars or a worklist is already a
/// list, and putting a border around it only adds a rectangle to a page that
/// has too many. Pass [framed] as false for those, and the section sits on
/// the canvas under its heading instead.
///
/// [minBodyHeight] is a floor, not a fixed height: the section grows with
/// text scaling instead of clipping it.
class DashboardSectionCard extends StatelessWidget {
  const DashboardSectionCard({
    required this.title,
    required this.child,
    this.subtitle,
    this.icon,
    this.trailing,
    this.minBodyHeight = 0,
    this.bodyPadding,
    this.framed = true,
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

  /// The section's single control — a period picker, a *view all* link.
  final Widget? trailing;

  /// Floor for the body's height, so two cards side by side start level.
  final double minBodyHeight;

  /// Padding around the body. Zero-horizontal for a card holding a table,
  /// which draws its own row insets.
  final EdgeInsetsGeometry? bodyPadding;

  /// Whether the section draws a card around itself. False leaves it on the
  /// page canvas, which is right for anything that is already a list.
  final bool framed;

  @override
  Widget build(BuildContext context) {
    final spacing = context.appSpacing;
    final body = Padding(
      padding: bodyPadding ?? EdgeInsets.zero,
      child: child,
    );

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        AppSectionHeader(
          title: title,
          subtitle: subtitle,
          icon: icon,
          trailing: trailing,
          dense: framed,
        ),
        SizedBox(height: spacing.md),
        if (minBodyHeight > 0)
          ConstrainedBox(
            constraints: BoxConstraints(minHeight: minBodyHeight),
            child: body,
          )
        else
          body,
      ],
    );

    if (!framed) return content;

    return AppCard(padding: EdgeInsets.all(spacing.md), child: content);
  }
}
