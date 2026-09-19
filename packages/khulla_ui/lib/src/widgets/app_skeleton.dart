// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: MIT

import 'package:khulla_ui/khulla_ui.dart';

/// {@template app_skeleton}
/// A pulsing placeholder block for content that is on its way.
///
/// Use it where the shape of what is loading is already known - a table of
/// rows, a detail pane of fields - so the layout does not jump when the read
/// returns. Where the shape is unknown, `AppSpinner` is honest and this is
/// not.
///
/// It pulses opacity rather than sweeping a gradient: one animation for the
/// whole screen, no shader, and nothing that reads as motion on a page a
/// librarian keeps open all day. Shimmer packages are the default reflex here
/// and they belong to a different, flashier design language.
/// {@endtemplate}
class AppSkeleton extends StatefulWidget {
  /// {@macro app_skeleton}
  const AppSkeleton({
    this.width,
    this.height = 16,
    this.radius,
    this.shape = BoxShape.rectangle,
    super.key,
  });

  /// Block width. Null fills the slot.
  final double? width;

  /// Block height.
  final double height;

  /// Corner radius. Defaults to the container rung; ignored for a circle.
  final double? radius;

  /// Rectangle for text and rows, circle for an avatar slot.
  final BoxShape shape;

  @override
  State<AppSkeleton> createState() => _AppSkeletonState();
}

class _AppSkeletonState extends State<AppSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1000),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isCircle = widget.shape == BoxShape.circle;

    return FadeTransition(
      opacity: Tween<double>(begin: 1, end: 0.5).animate(
        CurvedAnimation(
          parent: _controller,
          curve: context.appMotion.pulseCurve,
        ),
      ),
      child: SizedBox(
        width: widget.width,
        height: widget.height,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: context.appColors.skeleton,
            shape: widget.shape,
            borderRadius: isCircle
                ? null
                : BorderRadius.circular(
                    widget.radius ?? context.appRadius.container,
                  ),
          ),
        ),
      ),
    );
  }
}
