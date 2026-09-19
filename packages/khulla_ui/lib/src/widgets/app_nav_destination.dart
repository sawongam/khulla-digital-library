// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: MIT

import 'package:khulla_ui/khulla_ui.dart';

/// A single navigation destination, shared by [AppNavBar] and [AppNavRail].
///
/// One destination list drives both the compact bottom bar and the wide side
/// rail, so a window that is resized across a breakpoint keeps the same
/// destinations in the same order.
class AppNavDestination {
  const AppNavDestination({
    required this.icon,
    required this.label,
    this.badge,
    this.children = const [],
    this.expandedByDefault = false,
  });

  /// The destination's glyph.
  ///
  /// One glyph serves both states: selection is carried by the icon's colour
  /// and the surface behind it, never by swapping in a heavier weight. See
  /// `AppIcons`.
  final Widget icon;

  /// Short destination name. Doubles as the rail tooltip when collapsed.
  final String label;

  /// A count pinned to the trailing edge of the rail item - items waiting at
  /// the desk, unread notices. Already formatted; null draws nothing.
  final String? badge;

  /// The sections nested under this one, revealed when the rail is extended
  /// and this destination is expanded. Empty means a leaf destination.
  final List<AppNavChild> children;

  /// Whether this group starts expanded on first paint. The app sets this
  /// for the one section it wants open at startup; a deep link into any
  /// other sub-section still auto-expands its own parent.
  final bool expandedByDefault;
}

/// One row nested under an [AppNavDestination] in an extended rail.
///
/// A child carries its own selection and callback rather than an index: it
/// points at a route inside its parent's branch, which the parent's index
/// cannot express.
class AppNavChild {
  const AppNavChild({
    required this.label,
    required this.selected,
    required this.onSelected,
    this.badge,
  });

  /// The sub-section's name.
  final String label;

  /// Whether this is the route currently showing.
  final bool selected;

  /// Called when the row is picked.
  final VoidCallback onSelected;

  /// A count pinned to the trailing edge. Already formatted.
  final String? badge;
}
