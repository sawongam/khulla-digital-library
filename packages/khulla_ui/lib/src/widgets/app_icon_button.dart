// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: MIT

import 'package:khulla_ui/khulla_ui.dart';

/// {@template app_icon_button}
/// A square icon-only control, in the three sizes that pair with
/// [AppButton]'s: 35 for a table row, 40 beside a 40px button, 44 for a
/// toolbar.
///
/// [tooltip] is required, not optional: an icon-only control with no label is
/// unreachable by a screen reader and unguessable by everyone else, and on a
/// desktop tool that is most of the toolbar.
/// {@endtemplate}
class AppIconButton extends StatelessWidget {
  /// {@macro app_icon_button}
  const AppIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.tone,
    this.filled = false,
    this.outlined = false,
    this.selected = false,
    this.badge = false,
    this.badgeTone = AppStatusTone.danger,
    this.size = AppIconButtonSize.medium,
    super.key,
  });

  /// The glyph. Use the `_rounded` set.
  final AppIconSpec icon;

  /// What the control does, already localized. Doubles as the semantics
  /// label.
  final String tooltip;

  /// Called on press. Null disables the control, keeping the tooltip.
  final VoidCallback? onPressed;

  /// Overrides the glyph colour - [AppStatusTone.danger] for a destructive
  /// row action, for instance. Defaults to [ColorScheme.onSurfaceVariant].
  final AppStatusTone? tone;

  /// Gives the button a tinted fill, for a primary toolbar action.
  final bool filled;

  /// Draws a hairline outline, for a quiet toolbar action that sits
  /// beside a primary button and should read as a control.
  final bool outlined;

  /// Marks the control as the active choice - a toggled view switch.
  final bool selected;

  /// Draws an unread dot over the glyph's trailing corner - notifications
  /// waiting, a filter panel with something set.
  final bool badge;

  /// The dot's tone.
  final AppStatusTone badgeTone;

  /// How much room the control takes.
  final AppIconButtonSize size;

  @override
  Widget build(BuildContext context) {
    final spacing = context.appSpacing;
    final scheme = context.colorScheme;
    final colors = context.appColors;
    final metrics = context.appMetrics;
    final resolvedTone = tone;
    final foreground = selected
        ? scheme.primary
        : resolvedTone?.foreground(context) ?? colors.ink500;

    final side = switch (size) {
      AppIconButtonSize.small => metrics.iconButtonSmall,
      AppIconButtonSize.medium => metrics.iconButtonMedium,
      AppIconButtonSize.large => metrics.iconButtonLarge,
    };
    final radius = BorderRadius.circular(context.appRadius.container);

    final button = AppRipple(
      onTap: onPressed,
      borderRadius: radius,
      child: Container(
        width: side,
        height: side,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: filled || selected
              ? (resolvedTone ?? AppStatusTone.brand).background(context)
              : Colors.transparent,
          borderRadius: radius,
          border: outlined ? Border.all(color: colors.hairline) : null,
        ),
        child: AppIcon(icon, size: metrics.icon, color: foreground),
      ),
    );

    return Tooltip(
      message: tooltip,
      child: badge
          ? Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                button,
                Positioned(
                  top: spacing.xs,
                  right: spacing.xs,
                  child: Container(
                    width: spacing.xs,
                    height: spacing.xs,
                    decoration: BoxDecoration(
                      color: badgeTone.foreground(context),
                      shape: BoxShape.circle,
                      border: Border.all(color: scheme.surface, width: 1.5),
                    ),
                  ),
                ),
              ],
            )
          : button,
    );
  }
}

/// The three icon-button sizes, paired with [AppButton]'s heights.
enum AppIconButtonSize {
  /// 35px - inside a table row, where the row is only ~60px tall.
  small,

  /// 40px - the default, matching a small button.
  medium,

  /// 44px - a toolbar or a page header.
  large,
}
