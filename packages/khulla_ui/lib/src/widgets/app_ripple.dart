// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:khulla_ui/khulla_ui.dart';

/// The press feedback every control in this design system shares.
///
/// Material's ink splash is switched off app-wide (see `AppTheme`) because
/// its color, timing and clipping all belong to a different visual language.
/// This replaces it with the one the product actually uses: a **20px circle
/// spawned at the pointer, scaling to fill the control while it fades from
/// 50% to nothing over 600ms**, on top of a 0.95 scale dip held for as long
/// as the press lasts.
///
/// Both halves matter. The scale dip is what makes a press feel physical on
/// a trackpad; the ripple is what tells you *where* you pressed on a wide
/// control. Hand-rolling either one per component is how a screen ends up
/// with three different press behaviours.
class AppRipple extends StatefulWidget {
  const AppRipple({
    required this.child,
    this.onTap,
    this.onLongPress,
    this.onSecondaryTap,
    this.rippleColor,
    this.borderRadius,
    this.pressScale,
    this.cursor = SystemMouseCursors.click,
    this.onHoverChanged,
    super.key,
  });

  /// The control's own painted surface.
  final Widget child;

  /// Null disables the control: no ripple, no scale, no cursor change.
  final VoidCallback? onTap;

  /// Long-press, which on touch is how a context menu is reached.
  final VoidCallback? onLongPress;

  /// Right-click, the pointer equivalent of [onLongPress].
  final VoidCallback? onSecondaryTap;

  /// The ripple's color. Defaults to a neutral grey that reads on both a
  /// light surface and a brand fill.
  final Color? rippleColor;

  /// Clips the ripple to the control's shape. Without it the circle spills
  /// past a rounded corner.
  final BorderRadius? borderRadius;

  /// How far the control shrinks while pressed. Defaults to the token.
  final double? pressScale;

  /// The cursor shown while enabled.
  final MouseCursor cursor;

  /// Reports hover, for a control that repaints on it - a table row, a
  /// navigation item.
  final ValueChanged<bool>? onHoverChanged;

  @override
  State<AppRipple> createState() => _AppRippleState();
}

class _AppRippleState extends State<AppRipple> with TickerProviderStateMixin {
  final List<_Ripple> _ripples = [];
  late final AnimationController _press = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 120),
    reverseDuration: const Duration(milliseconds: 200),
  );

  bool get _enabled => widget.onTap != null || widget.onLongPress != null;

  @override
  void dispose() {
    for (final ripple in _ripples) {
      ripple.controller.dispose();
    }
    _press.dispose();
    super.dispose();
  }

  void _spawn(Offset localPosition) {
    final controller = AnimationController(
      vsync: this,
      duration: context.appMotion.ripple,
    );
    final ripple = _Ripple(origin: localPosition, controller: controller);
    setState(() => _ripples.add(ripple));
    unawaited(
      controller.forward().whenComplete(() {
        if (!mounted) {
          controller.dispose();
          return;
        }
        setState(() => _ripples.remove(ripple));
        controller.dispose();
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final motion = context.appMotion;
    final color = widget.rippleColor ?? context.appColors.rippleNeutral;
    final scale = widget.pressScale ?? motion.pressScale;

    if (!_enabled) {
      return Opacity(opacity: 0.5, child: widget.child);
    }

    return MouseRegion(
      cursor: widget.cursor,
      onEnter: (_) => widget.onHoverChanged?.call(true),
      onExit: (_) => widget.onHoverChanged?.call(false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        onLongPress: widget.onLongPress,
        onSecondaryTap: widget.onSecondaryTap,
        onTapDown: (details) {
          _press.forward();
          _spawn(details.localPosition);
        },
        onTapUp: (_) => _press.reverse(),
        onTapCancel: _press.reverse,
        child: AnimatedBuilder(
          animation: _press,
          builder: (context, child) => Transform.scale(
            scale: 1 - (1 - scale) * _press.value,
            child: child,
          ),
          child: Stack(
            children: [
              widget.child,
              Positioned.fill(
                child: IgnorePointer(
                  child: ClipRRect(
                    borderRadius: widget.borderRadius ?? BorderRadius.zero,
                    child: CustomPaint(
                      painter: _RipplePainter(ripples: _ripples, color: color),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Ripple {
  const _Ripple({required this.origin, required this.controller});

  final Offset origin;
  final AnimationController controller;
}

class _RipplePainter extends CustomPainter {
  _RipplePainter({required this.ripples, required this.color})
    : super(
        repaint: Listenable.merge([
          for (final ripple in ripples) ripple.controller,
        ]),
      );

  /// The spawn diameter, before it scales out.
  static const double _seed = 20;

  /// How far the seed grows. Ten is enough to cover the widest control in
  /// the app from a corner tap.
  static const double _growth = 10;

  final List<_Ripple> ripples;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    for (final ripple in ripples) {
      final t = Curves.easeOut.transform(ripple.controller.value);
      final radius = _seed / 2 * (t * _growth);
      final paint = Paint()
        ..color = color.withValues(alpha: 0.5 * (1 - ripple.controller.value));
      canvas.drawCircle(ripple.origin, radius, paint);
    }
  }

  @override
  bool shouldRepaint(_RipplePainter oldDelegate) =>
      oldDelegate.ripples != ripples || oldDelegate.color != color;
}
