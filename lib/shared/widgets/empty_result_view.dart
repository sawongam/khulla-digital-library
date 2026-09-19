// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:khulla_ui/khulla_ui.dart';

/// Empty-state copy for a search or list that came back with nothing.
///
/// A thin app-side default over [AppEmptyView]: it only picks the search
/// icon, so a screen with its own icon or a first action can use
/// [AppEmptyView] directly instead of growing parameters here.
class EmptyResultView extends StatelessWidget {
  const EmptyResultView({
    required this.title,
    required this.subtitle,
    super.key,
    this.icon = AppIcons.noResults,
    this.variant = AppFeedbackVariant.centered,
  });

  /// Short heading, e.g. "No matches".
  final String title;

  /// Supporting copy shown below [title].
  final String subtitle;

  /// Badge icon, shown only in [AppFeedbackVariant.centered].
  final AppIconSpec icon;

  /// Layout: centered for a whole screen or section, inline inside a card.
  final AppFeedbackVariant variant;

  @override
  Widget build(BuildContext context) {
    return AppEmptyView(
      title: title,
      message: subtitle,
      icon: icon,
      variant: variant,
    );
  }
}
