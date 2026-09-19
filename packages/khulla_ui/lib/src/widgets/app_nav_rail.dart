// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: MIT

import 'package:khulla_ui/khulla_ui.dart';

/// The side navigation for every window wider than a phone.
///
/// Hand-built rather than wrapped around Material's [NavigationRail], because
/// the product needs three things that widget does not offer: a destination
/// that expands into its sub-sections, a count pinned to a row, and a single
/// visual language across the collapsed and extended states. Both states are
/// the same widget with the same items in the same order, so dragging a window
/// across 1200px reveals labels rather than rebuilding the navigation.
///
/// Selection is a **warm tint plus a 4px half-height bar on the left edge**,
/// not a filled row. The tint is the same one hover uses, so moving down the
/// rail does not flash a different color at every step; the bar is what
/// actually says *you are here*, and it is deliberately short and rounded on
/// its outer edge rather than a full-height stripe.
class AppNavRail extends StatefulWidget {
  const AppNavRail({
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.destinations,
    this.extended = false,
    this.leading,
    this.trailing,
    this.footer,
    this.wrapSafeArea = true,
    super.key,
  }) : assert(destinations.length >= 2, 'Need at least 2 destinations');

  /// Index of the active destination.
  final int selectedIndex;

  /// Called with the index of the destination the user picked.
  final ValueChanged<int> onDestinationSelected;

  /// Destinations, in display order. Shared with [AppNavBar].
  final List<AppNavDestination> destinations;

  /// Whether to show labels beside the glyphs.
  final bool extended;

  /// Pinned above the destinations - the product mark.
  final Widget? leading;

  /// Pinned under the destinations, above [footer] - the theme toggle, a
  /// sign-out row.
  final Widget? trailing;

  /// The bottom-most slot, drawn full-bleed inside the rail's padding - a
  /// promo card, a storage meter.
  final Widget? footer;

  /// Whether to wrap the rail in [SafeArea]. The shell turns this off when it
  /// already wrapped the chrome row once.
  final bool wrapSafeArea;

  /// The rail's width when it is showing labels.
  static const double extendedWidth = 240;

  /// The rail's width when it is glyphs only.
  static const double collapsedWidth = 64;

  @override
  State<AppNavRail> createState() => _AppNavRailState();
}

class _AppNavRailState extends State<AppNavRail> {
  final Set<int> _expanded = <int>{};

  @override
  void initState() {
    super.initState();
    // Start collapsed apart from opt-ins: expanding every group pushes
    // Settings and Staff far down the rail on first paint. A deep link
    // straight into a sub-section still auto-expands its parent so the
    // selection stays visible.
    for (final (index, destination) in widget.destinations.indexed) {
      if (destination.expandedByDefault ||
          destination.children.any((child) => child.selected)) {
        _expanded.add(index);
      }
    }
  }

  @override
  void didUpdateWidget(AppNavRail oldWidget) {
    super.didUpdateWidget(oldWidget);
    // A route change can select a child of a collapsed group (deep link,
    // back/forward). Keep the active sub-section visible without touching
    // user-controlled toggles.
    for (final (index, destination) in widget.destinations.indexed) {
      if (destination.children.any((child) => child.selected)) {
        _expanded.add(index);
      }
    }
  }

  void _toggle(int index) => setState(() {
    if (!_expanded.remove(index)) _expanded.add(index);
  });

  @override
  Widget build(BuildContext context) {
    final spacing = context.appSpacing;
    final scheme = context.colorScheme;
    final colors = context.appColors;
    final extended = widget.extended;
    final head = widget.leading;
    final tail = widget.trailing;
    final bottom = widget.footer;
    final applySafeArea = widget.wrapSafeArea;

    final rail = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Optional slot above the destinations - product mark, search, or
        // a workspace switcher. The shell draws its brand header above the
        // rail instead, so this stays null in production.
        if (head != null)
          SizedBox(
            height: context.appMetrics.topBarHeight,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: spacing.sm),
              child: Center(child: head),
            ),
          ),
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              spacing.sm,
              spacing.xs,
              spacing.sm,
              spacing.xs,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final (index, destination) in widget.destinations.indexed)
                  AppRailItem(
                    destination: destination,
                    extended: extended,
                    selected:
                        index == widget.selectedIndex &&
                        !destination.children.any((child) => child.selected),
                    expanded: _expanded.contains(index),
                    onTap: () {
                      if (extended && destination.children.isNotEmpty) {
                        _toggle(index);
                        return;
                      }
                      widget.onDestinationSelected(index);
                    },
                    onToggle: destination.children.isEmpty || !extended
                        ? null
                        : () => _toggle(index),
                  ),
              ],
            ),
          ),
        ),
        if (tail != null)
          Padding(
            padding: EdgeInsets.fromLTRB(
              spacing.sm,
              spacing.xs,
              spacing.sm,
              spacing.xs,
            ),
            child: tail,
          ),
        if (bottom != null)
          Padding(
            padding: EdgeInsets.fromLTRB(
              spacing.sm,
              spacing.xs,
              spacing.sm,
              spacing.sm,
            ),
            child: bottom,
          ),
      ],
    );

    return Container(
      width: extended ? AppNavRail.extendedWidth : AppNavRail.collapsedWidth,
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(right: BorderSide(color: colors.hairline)),
      ),
      child: applySafeArea ? SafeArea(right: false, child: rail) : rail,
    );
  }
}
