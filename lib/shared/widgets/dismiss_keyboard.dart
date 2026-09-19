// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:flutter/widgets.dart';

/// Dismisses the soft keyboard when the user taps outside the focused field.
///
/// Wrap once at the app root so every screen inherits tap-to-dismiss behavior.
class DismissKeyboard extends StatelessWidget {
  const DismissKeyboard({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (event) {
        final focusNode = FocusManager.instance.primaryFocus;
        if (focusNode == null || !focusNode.hasFocus) {
          return;
        }

        final focusContext = focusNode.context;
        if (focusContext == null) {
          focusNode.unfocus();
          return;
        }

        final renderObject = focusContext.findRenderObject();
        if (renderObject is! RenderBox || !renderObject.attached) {
          focusNode.unfocus();
          return;
        }

        final offset = renderObject.localToGlobal(Offset.zero);
        final rect = offset & renderObject.size;
        if (!rect.contains(event.position)) {
          focusNode.unfocus();
        }
      },
      child: child,
    );
  }
}
