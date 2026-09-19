// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: MIT

import 'package:khulla_ui/khulla_ui.dart';

/// Wraps a glyph or control before it is handed to `InputDecoration`'s
/// `prefixIcon` / `suffixIcon` slot.
///
/// Material applies a **minimum** 48px box to those slots (see
/// `InputDecorator`), and a minimum propagates down: an `AppIcon` sized 16
/// inside it is asked for at least 48px, and because the underlying SVG is
/// drawn with `BoxFit.contain` it happily grows to fill - which is how a
/// search field ends up with a magnifier the size of the field itself.
///
/// Centring the child inside that box breaks the chain: the affix still
/// occupies the tappable 48px Material wants, and the glyph keeps the size it
/// asked for. Fields must not pass a bare icon to those slots.
class AppFieldAffix extends StatelessWidget {
  const AppFieldAffix({required this.child, super.key});

  /// The glyph or control to centre.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Center(
      widthFactor: 1,
      heightFactor: 1,
      child: IconTheme.merge(
        data: IconThemeData(size: context.appMetrics.icon),
        child: child,
      ),
    );
  }
}
