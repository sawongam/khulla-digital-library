// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: MIT

import 'package:flutter/gestures.dart';
import 'package:khulla_ui/khulla_ui.dart';

/// Scroll behavior for a product that runs under a pointer as often as a
/// thumb.
///
/// Flutter omits [PointerDeviceKind.mouse] from [dragDevices] by default, so
/// on desktop and web a list can only be scrolled with the wheel - click-and-
/// drag does nothing, and any custom drag-to-pan surface silently refuses the
/// mouse. Wire this once via `MaterialApp.scrollBehavior`.
class AppScrollBehavior extends MaterialScrollBehavior {
  /// {@macro app_scroll_behavior}
  const AppScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => const <PointerDeviceKind>{
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.trackpad,
    PointerDeviceKind.stylus,
    PointerDeviceKind.invertedStylus,
  };
}
