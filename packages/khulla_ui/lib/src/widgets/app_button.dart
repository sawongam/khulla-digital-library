// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: MIT

import 'package:khulla_ui/khulla_ui.dart';

/// {@template app_button}
/// The system's only button.
///
/// Every visual decision - height, radius, shadow, the ripple, the 0.95 press
/// dip, the disabled 50%, the loading spinner that replaces the label without
/// resizing the control - lives here, so a screen picks a [variant] and a
/// [size] and never writes a style. A one-off `ElevatedButton` with a custom
/// `ButtonStyle` is the thing this exists to prevent.
/// {@endtemplate}
class AppButton extends StatefulWidget {
  /// {@macro app_button}
  const AppButton({
    required this.onPressed,
    required this.child,
    this.variant = AppButtonVariant.primary,
    this.size = AppButtonSize.small,
    this.isLoading = false,
    this.icon,
    this.trailingIcon,
    this.expand = false,
    super.key,
  });

  /// Called on press. Null disables the button; ignored while [isLoading].
  final VoidCallback? onPressed;

  /// The label, typically a [Text].
  final Widget child;

  /// What the button means.
  final AppButtonVariant variant;

  /// How much room it takes.
  final AppButtonSize size;

  /// Swaps the label for a spinner and swallows presses. The button keeps
  /// its width, so a row of controls does not reflow mid-submit.
  final bool isLoading;

  /// A glyph before the label. Worth it on a verb - *Add title*, *Check
  /// out* - and never worth it as decoration.
  final AppIconSpec? icon;

  /// A glyph after the label, for a button that opens something.
  final AppIconSpec? trailingIcon;

  /// Stretches to the slot instead of hugging the label.
  final bool expand;

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final metrics = context.appMetrics;
    final spacing = context.appSpacing;
    final motion = context.appMotion;
    final style = AppButtonStyler.resolve(context, widget.variant);

    final height = switch (widget.size) {
      AppButtonSize.small => metrics.buttonHeightSmall,
      AppButtonSize.medium => metrics.buttonHeightMedium,
      AppButtonSize.large => metrics.buttonHeightLarge,
    };

    final hasIcon = widget.icon != null || widget.trailingIcon != null;
    // Horizontal padding tightens when a glyph is present, so an icon+label
    // button reads at the same optical width as a label-only one.
    final basePadding = switch (widget.size) {
      AppButtonSize.small => spacing.sm,
      AppButtonSize.medium => spacing.md,
      AppButtonSize.large => spacing.xlg,
    };
    final padding = hasIcon ? basePadding - spacing.xxs : basePadding;

    final radius = BorderRadius.circular(
      widget.size == AppButtonSize.small
          ? context.appRadius.container
          : context.appRadius.control,
    );
    final gap = widget.size == AppButtonSize.small
        ? spacing.xs - 2
        : spacing.xs;

    final enabled = widget.onPressed != null && !widget.isLoading;
    final fill = _hovered && enabled ? style.hoverFill : style.fill;

    if (widget.variant == AppButtonVariant.link) {
      return AppLinkButton(
        onPressed: enabled ? widget.onPressed : null,
        color: style.foreground,
        child: widget.child,
      );
    }

    final label = DefaultTextStyle.merge(
      style: context.appTextStyles.button.copyWith(color: style.foreground),
      child: IconTheme.merge(
        data: IconThemeData(
          color: style.foreground,
          size: metrics.iconInButton,
        ),
        child: Row(
          mainAxisSize: widget.expand ? MainAxisSize.max : MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (widget.icon != null) ...[
              AppIcon(widget.icon!),
              SizedBox(width: gap),
            ],
            Flexible(child: widget.child),
            if (widget.trailingIcon != null) ...[
              SizedBox(width: gap),
              AppIcon(widget.trailingIcon!),
            ],
          ],
        ),
      ),
    );

    final surface = AnimatedContainer(
      duration: motion.color,
      height: height,
      padding: EdgeInsets.symmetric(horizontal: padding),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: radius,
        border: Border.all(color: style.border),
        boxShadow: style.shadowed ? context.appShadows.card : null,
      ),
      child: Center(
        widthFactor: widget.expand ? null : 1,
        child: widget.isLoading
            ? AppSpinner(color: style.foreground, size: metrics.iconLarge)
            : label,
      ),
    );

    final button = Focus(
      onFocusChange: (value) => setState(() => _focused = value),
      child: AnimatedContainer(
        duration: motion.color,
        decoration: BoxDecoration(
          borderRadius: radius,
          // A 3px ring at half strength, drawn outside the control rather
          // than recoloring its border, so focus never shifts layout.
          boxShadow: _focused && enabled
              ? [
                  BoxShadow(
                    color: style.ring.withValues(alpha: 0.5),
                    spreadRadius: 3,
                  ),
                ]
              : null,
        ),
        child: AppRipple(
          onTap: enabled ? widget.onPressed : null,
          rippleColor: style.ripple,
          borderRadius: radius,
          onHoverChanged: (value) => setState(() => _hovered = value),
          child: surface,
        ),
      ),
    );

    return widget.expand
        ? SizedBox(width: double.infinity, child: button)
        : button;
  }
}
