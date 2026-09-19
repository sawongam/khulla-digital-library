// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: MIT

import 'package:khulla_ui/khulla_ui.dart';

/// The tinted row plus the active bar, shared by every rail item.
///
/// The bar is drawn *outside* the row's padding and clipped to nothing when
/// the row is not selected, so selection never shifts the label. Selection
/// is a warm tint plus a 4px half-height bar on the left edge, not a filled
/// row - the tint matches hover so moving down the rail does not flash.
class AppRailRowSurface extends StatefulWidget {
  const AppRailRowSurface({
    required this.selected,
    required this.radius,
    required this.onTap,
    required this.child,
    super.key,
  });

  final bool selected;
  final BorderRadius radius;
  final VoidCallback onTap;
  final Widget child;

  @override
  State<AppRailRowSurface> createState() => _AppRailRowSurfaceState();
}

class _AppRailRowSurfaceState extends State<AppRailRowSurface> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final motion = context.appMotion;
    final tinted = widget.selected || _hovered;

    return AppRipple(
      onTap: widget.onTap,
      borderRadius: widget.radius,
      pressScale: 1,
      onHoverChanged: (value) => setState(() => _hovered = value),
      child: Stack(
        children: [
          AnimatedContainer(
            duration: motion.color,
            decoration: BoxDecoration(
              color: tinted ? colors.tints.navRow : Colors.transparent,
              borderRadius: widget.radius,
            ),
            child: widget.child,
          ),
          PositionedDirectional(
            start: 0,
            top: 0,
            bottom: 0,
            child: Center(
              child: AnimatedContainer(
                duration: motion.layout,
                curve: motion.standard,
                width: 4,
                height: widget.selected
                    ? context.appMetrics.navRowHeight / 2
                    : 0,
                decoration: BoxDecoration(
                  color: colors.brand,
                  borderRadius: BorderRadiusDirectional.horizontal(
                    end: Radius.circular(context.appRadius.pill),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
