// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: MIT

import 'package:khulla_ui/khulla_ui.dart';

/// A link has no box: no height, no padding, no ripple - only the underline
/// on hover that every link on the web has.
///
/// Rendered by [AppButton] for [AppButtonVariant.link], and usable directly
/// when a box-less action is needed without the button's loading and icon
/// machinery.
class AppLinkButton extends StatefulWidget {
  const AppLinkButton({
    required this.onPressed,
    required this.color,
    required this.child,
    super.key,
  });

  final VoidCallback? onPressed;
  final Color color;
  final Widget child;

  @override
  State<AppLinkButton> createState() => _AppLinkButtonState();
}

class _AppLinkButtonState extends State<AppLinkButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    return MouseRegion(
      cursor: enabled ? SystemMouseCursors.click : MouseCursor.defer,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onPressed,
        child: Opacity(
          opacity: enabled ? 1 : 0.5,
          child: DefaultTextStyle.merge(
            style: context.appTextStyles.button.copyWith(
              color: widget.color,
              decoration: _hovered ? TextDecoration.underline : null,
              decorationColor: widget.color,
            ),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
