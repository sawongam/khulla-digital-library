// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:khulla_ui/khulla_ui.dart';

/// One thing somebody has to do something about.
///
/// The attention panel is the counterpart to the activity table: that one is
/// what happened, this one is what is still owed. Every item carries the
/// route that clears it, because a list of problems with nowhere to go is a
/// worry, not a tool.
class DashboardAttentionItem {
  const DashboardAttentionItem({
    required this.label,
    required this.count,
    required this.icon,
    required this.tone,
    required this.route,
  });

  /// What needs doing, already localized.
  final String label;

  /// How many, already formatted.
  final String count;

  /// The leading glyph.
  final AppIconSpec icon;

  /// How urgent it is.
  final AppStatusTone tone;

  /// The screen that clears it.
  final String route;
}
