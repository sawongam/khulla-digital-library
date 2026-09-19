// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:khulla_ui/khulla_ui.dart';
import 'package:toastification/toastification.dart';

/// App-wide toast helper backed by [toastification].
///
/// Anchored bottom-centre and capped in width so it reads the same in a
/// maximised desktop window as it does in a narrow one.
abstract final class AppToast {
  static const _defaultDuration = Duration(milliseconds: 2200);
  static const _animationDuration = Duration(milliseconds: 280);
  static const _iconSize = 18.0;
  static const _mutedIconSize = 17.0;

  /// Shows a toast at the bottom of the screen.
  ///
  /// [type] maps to [ToastificationType] (`info`, `success`, `warning`, `error`).
  /// [style] maps to [ToastificationStyle] (`minimal`, `fillColored`,
  /// `flatColored`, `flat`, `simple`).
  static void show(
    BuildContext context, {
    required String message,
    String? description,
    ToastificationType type = ToastificationType.info,
    ToastificationStyle style = ToastificationStyle.flat,
    Duration? autoCloseDuration,
  }) {
    final spacing = context.appSpacing;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    toastification.showCustom(
      context: context,
      alignment: Alignment.bottomCenter,
      autoCloseDuration: autoCloseDuration ?? _defaultDuration,
      animationDuration: _animationDuration,
      builder: (context, holder) {
        return Align(
          alignment: Alignment.bottomCenter,
          widthFactor: 1,
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              spacing.md,
              0,
              spacing.md,
              spacing.sm + bottomInset,
            ),
            child: _AppToastCard(
              holder: holder,
              message: message,
              description: description,
              type: type,
              style: style,
            ),
          ),
        );
      },
    );
  }

  /// Shorthand for [ToastificationType.info].
  static void info(
    BuildContext context, {
    required String message,
    String? description,
    ToastificationStyle style = ToastificationStyle.flat,
    Duration? autoCloseDuration,
  }) => show(
    context,
    message: message,
    description: description,
    style: style,
    autoCloseDuration: autoCloseDuration,
  );

  /// Shorthand for [ToastificationType.success].
  static void success(
    BuildContext context, {
    required String message,
    String? description,
    ToastificationStyle style = ToastificationStyle.flat,
    Duration? autoCloseDuration,
  }) => show(
    context,
    message: message,
    description: description,
    type: ToastificationType.success,
    style: style,
    autoCloseDuration: autoCloseDuration,
  );

  /// Shorthand for [ToastificationType.warning].
  static void warning(
    BuildContext context, {
    required String message,
    String? description,
    ToastificationStyle style = ToastificationStyle.flat,
    Duration? autoCloseDuration,
  }) => show(
    context,
    message: message,
    description: description,
    type: ToastificationType.warning,
    style: style,
    autoCloseDuration: autoCloseDuration,
  );

  /// Shorthand for [ToastificationType.error].
  static void error(
    BuildContext context, {
    required String message,
    String? description,
    ToastificationStyle style = ToastificationStyle.flat,
    Duration? autoCloseDuration,
  }) => show(
    context,
    message: message,
    description: description,
    type: ToastificationType.error,
    style: style,
    autoCloseDuration: autoCloseDuration,
  );
}

class _AppToastCard extends StatelessWidget {
  const _AppToastCard({
    required this.holder,
    required this.message,
    required this.type,
    required this.style,
    this.description,
  });

  final ToastificationItem holder;
  final String message;
  final String? description;
  final ToastificationType type;

  /// The catalog glyph for a toast type.
  ///
  /// `ToastificationType.icon` hands back a Material `IconData`, which the app
  /// does not draw - see `AppIcons`.
  static AppIconSpec _glyphFor(ToastificationType type) => switch (type) {
    ToastificationType.success => AppIcons.success,
    ToastificationType.warning => AppIcons.warning,
    ToastificationType.error => AppIcons.error,
    ToastificationType.info || _ => AppIcons.info,
  };
  final ToastificationStyle style;

  bool get _isMutedInfo =>
      type == ToastificationType.info &&
      (style == ToastificationStyle.minimal ||
          style == ToastificationStyle.flat);

  @override
  Widget build(BuildContext context) {
    final spacing = context.appSpacing;
    final scheme = context.colorScheme;
    final isSimple = style == ToastificationStyle.simple;
    final isMutedInfo = _isMutedInfo;

    final titleColor = _titleColor(scheme);
    final subtitleColor = _subtitleColor(scheme);
    final iconColor = isMutedInfo
        ? scheme.primary
        : isSimple
        ? scheme.onInverseSurface
        : type.color;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: _backgroundColor(scheme),
        borderRadius: BorderRadius.circular(context.appRadius.container),
        border: _border(scheme),
        boxShadow: _boxShadow(context),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          spacing.md,
          isMutedInfo ? spacing.xs + 2 : spacing.sm,
          isMutedInfo ? spacing.sm : spacing.md,
          isMutedInfo ? spacing.xs + 2 : spacing.sm,
        ),
        child: Row(
          children: [
            _ToastIcon(
              icon: isMutedInfo ? AppIcons.info : _glyphFor(type),
              color: iconColor,
              size: isMutedInfo ? AppToast._mutedIconSize : AppToast._iconSize,
              bordered: !isMutedInfo,
            ),
            SizedBox(width: isMutedInfo ? spacing.xs + 2 : spacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    message,
                    style:
                        (isMutedInfo
                                ? context.textTheme.bodySmall
                                : context.textTheme.bodyMedium)
                            ?.copyWith(
                              color: titleColor,
                              fontWeight: FontWeight.w500,
                              height: 1.3,
                            ),
                  ),
                  if (description case final body?) ...[
                    SizedBox(height: spacing.xxs),
                    Text(
                      body,
                      style: context.textTheme.bodySmall?.copyWith(
                        color: subtitleColor,
                        fontWeight: FontWeight.w400,
                        height: 1.3,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (!isMutedInfo) ...[
              SizedBox(width: spacing.xs),
              _ToastCloseButton(holder: holder, color: subtitleColor),
            ],
          ],
        ),
      ),
    );
  }

  List<BoxShadow>? _boxShadow(BuildContext context) {
    if (style == ToastificationStyle.simple || _isMutedInfo) {
      return null;
    }
    // A toast floats over the page, so it takes the overlay depth - the same
    // one a dialog and a side sheet use.
    return context.appShadows.overlay;
  }

  Color _titleColor(ColorScheme scheme) {
    if (style == ToastificationStyle.simple) {
      return scheme.onInverseSurface;
    }
    if (style == ToastificationStyle.fillColored) {
      return scheme.onPrimary;
    }
    return scheme.onSurface;
  }

  Color _subtitleColor(ColorScheme scheme) {
    if (style == ToastificationStyle.simple) {
      return scheme.onInverseSurface.withValues(alpha: 0.75);
    }
    if (style == ToastificationStyle.fillColored) {
      return scheme.onPrimary.withValues(alpha: 0.85);
    }
    return scheme.onSurfaceVariant;
  }

  Color _backgroundColor(ColorScheme scheme) {
    if (_isMutedInfo) {
      return scheme.surface;
    }
    return switch (style) {
      ToastificationStyle.simple => scheme.inverseSurface,
      ToastificationStyle.fillColored => type.color,
      ToastificationStyle.flatColored => type.color.withValues(alpha: 0.12),
      ToastificationStyle.minimal || ToastificationStyle.flat => scheme.surface,
    };
  }

  Border? _border(ColorScheme scheme) {
    if (_isMutedInfo) {
      return Border.all(
        color: Color.alphaBlend(
          scheme.onSurface.withValues(alpha: 0.10),
          scheme.surface,
        ),
      );
    }
    return switch (style) {
      ToastificationStyle.flat || ToastificationStyle.minimal => Border.all(
        color: scheme.outlineVariant.withValues(alpha: 0.8),
      ),
      ToastificationStyle.flatColored => Border.all(
        color: type.color.withValues(alpha: 0.35),
      ),
      ToastificationStyle.simple || ToastificationStyle.fillColored => null,
    };
  }
}

class _ToastIcon extends StatelessWidget {
  const _ToastIcon({
    required this.icon,
    required this.color,
    required this.size,
    this.bordered = true,
  });

  final AppIconSpec icon;
  final Color color;
  final double size;
  final bool bordered;

  @override
  Widget build(BuildContext context) {
    final child = AppIcon(icon, size: size, color: color);

    if (!bordered) {
      return child;
    }

    final spacing = context.appSpacing;

    return DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Padding(
        padding: EdgeInsets.all(spacing.xxs + 1),
        child: child,
      ),
    );
  }
}

class _ToastCloseButton extends StatelessWidget {
  const _ToastCloseButton({required this.holder, required this.color});

  final ToastificationItem holder;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () => toastification.dismiss(holder),
      icon: AppIcon(AppIcons.close, size: AppToast._iconSize, color: color),
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
      constraints: const BoxConstraints.tightFor(width: 28, height: 28),
    );
  }
}
