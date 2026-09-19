// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: MIT

import 'package:khulla_ui/khulla_ui.dart';

/// {@template app_menu_action}
/// One entry in an [AppMenuButton] overflow menu.
///
/// A section header carries exactly one primary action; everything else - the
/// duplicate, the export, the delete - lives here, so a toolbar never becomes
/// a row of five equal buttons with no obvious next step.
/// {@endtemplate}
class AppMenuAction {
  /// {@macro app_menu_action}
  const AppMenuAction({
    required this.label,
    required this.onSelected,
    this.icon,
    this.isDestructive = false,
    this.enabled = true,
  });

  /// The action's localized name, phrased as the act - *Delete copy*.
  final String label;

  /// Called when the entry is chosen.
  final VoidCallback onSelected;

  /// Optional leading glyph.
  final AppIconSpec? icon;

  /// Draws the entry in [ColorScheme.error]. A destructive entry belongs at
  /// the bottom of the menu, away from the ones people use daily, and must
  /// still confirm through [AppDialog] before it does anything.
  final bool isDestructive;

  /// Whether the entry can be chosen. A disabled entry that explains itself
  /// beats a missing one that leaves people hunting.
  final bool enabled;
}
