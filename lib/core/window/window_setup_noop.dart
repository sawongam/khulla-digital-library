// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:khulla/core/config/app_config.dart';

/// No-op on web and mobile, where the app does not own its window.
///
/// Takes [config] so the signature matches the desktop implementation and
/// `bootstrap` needs no platform check of its own.
Future<void> configureAppWindow(AppConfig config) async {}
