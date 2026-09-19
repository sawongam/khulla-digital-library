// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:khulla/core/config/app_config.dart';
import 'package:window_manager/window_manager.dart';

/// Sizes, titles, and reveals the desktop window before the first frame.
///
/// The minimum size is the point below which the navigation rail and a detail
/// pane stop fitting side by side. Without it a user can drag the window
/// narrow enough to break every two-pane screen at once, which reads as a bug
/// in the app rather than a window they made too small.
///
/// Showing the window only once Flutter is ready to paint avoids the white
/// flash a default desktop launch produces.
Future<void> configureAppWindow(AppConfig config) async {
  if (!Platform.isWindows && !Platform.isLinux && !Platform.isMacOS) return;

  await windowManager.ensureInitialized();

  final options = WindowOptions(
    size: const Size(1280, 840),
    minimumSize: const Size(960, 640),
    center: true,
    title: config.windowTitle,
  );

  await windowManager.waitUntilReadyToShow(options, () async {
    await windowManager.show();
    await windowManager.focus();
  });
}
