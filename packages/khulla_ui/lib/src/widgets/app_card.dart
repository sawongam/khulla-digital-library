// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: MIT

import 'package:khulla_ui/khulla_ui.dart';

/// A bordered block: 1px hairline, 6px corners, 16px of padding, **no
/// shadow and no fill**.
///
/// This is the product's real card, and it is not the shadcn/Material one. A
/// dashboard holding twelve surfaces with drop shadows and grey fills reads
/// as a mockup; the same twelve separated by hairlines read as a tool. Set
/// [filled] for the rarer variant that does carry a fill and a shadow - a
/// standalone panel with nothing around it to give it an edge.
///
/// Hovering a tappable card raises its hairline rather than lifting it, which
/// says "this responds to a click" without adding a second depth level to
/// every list.
class AppCard extends StatefulWidget {
  const AppCard({
    required this.child,
    this.padding,
    this.onTap,
    this.selected = false,
    this.bordered = true,
    this.filled = false,
    this.tone,
    this.clipBehavior = Clip.antiAlias,
    super.key,
  });

  /// The card's content.
  final Widget child;

  /// Inner padding. Defaults to `spacing.md` on every side.
  final EdgeInsetsGeometry? padding;

  /// Makes the whole card pressable, with hover and focus feedback.
  final VoidCallback? onTap;

  /// Draws the selected outline - a picked row, an active filter panel.
  final bool selected;

  /// Whether to draw the hairline. Turn it off for a card nested inside
  /// another surface that already has one.
  final bool bordered;

  /// Switches to the filled variant: the grey card surface plus the small
  /// shadow. Use it for a surface with no neighbours to define its edge.
  final bool filled;

  /// Tints the card's fill and hairline with a status wash - a warning
  /// banner, a danger panel. Null keeps the neutral surface.
  final AppStatusTone? tone;

  /// How the card clips its child. Antialiased by default so a full-bleed
  /// image or a table inside it follows the corner radius.
  final Clip clipBehavior;

  @override
  State<AppCard> createState() => _AppCardState();
}

class _AppCardState extends State<AppCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final spacing = context.appSpacing;
    final scheme = context.colorScheme;
    final colors = context.appColors;
    final shadows = context.appShadows;
    final tone = widget.tone;
    final interactive = widget.onTap != null;
    final lifted = interactive && _hovered;

    final fill = switch (tone) {
      null => widget.filled ? scheme.surfaceContainerHigh : Colors.transparent,
      final value => value.background(context),
    };
    final borderColor = switch (tone) {
      _ when widget.selected => scheme.primary,
      null => colors.hairline,
      final value => value.border(context),
    };

    final body = Padding(
      padding: widget.padding ?? EdgeInsets.all(spacing.md),
      child: widget.child,
    );

    return MouseRegion(
      cursor: interactive ? SystemMouseCursors.click : MouseCursor.defer,
      onEnter: interactive ? (_) => setState(() => _hovered = true) : null,
      onExit: interactive ? (_) => setState(() => _hovered = false) : null,
      child: AnimatedContainer(
        duration: context.appMotion.color,
        curve: context.appMotion.standard,
        decoration: BoxDecoration(
          color: fill,
          borderRadius: BorderRadius.circular(context.appRadius.container),
          border: widget.bordered
              ? Border.all(
                  color: lifted && !widget.selected
                      ? colors.hairlineStrong
                      : borderColor,
                )
              : null,
          boxShadow: widget.filled ? shadows.card : null,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(context.appRadius.container),
          clipBehavior: widget.clipBehavior,
          child: interactive
              ? AppRipple(
                  onTap: widget.onTap,
                  borderRadius: BorderRadius.circular(
                    context.appRadius.container,
                  ),
                  pressScale: 1,
                  child: body,
                )
              : body,
        ),
      ),
    );
  }
}
