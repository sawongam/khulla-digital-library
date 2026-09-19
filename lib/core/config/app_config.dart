// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:khulla/core/config/flavor.dart';

/// Immutable, per-flavor runtime configuration.
///
/// Resolved once at startup in the flavor entrypoint and registered in the
/// service locator so the database and other services can depend on it.
///
/// Khulla stores its data on the device, so a flavor mostly decides *which*
/// database file the app opens - running the dev build must never touch a
/// real library's catalogue.
class AppConfig {
  const AppConfig({
    required this.flavor,
    required this.databaseName,
    required this.windowTitle,
  });

  factory AppConfig.dev() => const AppConfig(
    flavor: Flavor.dev,
    databaseName: 'khulla_dev',
    windowTitle: 'Khulla Digital Library (dev)',
  );

  factory AppConfig.prod() => const AppConfig(
    flavor: Flavor.prod,
    databaseName: 'khulla',
    windowTitle: 'Khulla Digital Library',
  );

  /// Which build this is.
  final Flavor flavor;

  /// Name of this flavor's catalogue, without an extension.
  ///
  /// On native it becomes `<name>.sqlite` in the application support
  /// directory; on web it is the key of the browser storage drift opens.
  /// Running the dev build must never touch a real library's catalogue, so
  /// this is the one field that keeps the flavors apart on every platform.
  final String databaseName;

  /// Native window title on desktop. Ignored on mobile and web.
  final String windowTitle;

  /// Whether this is the release flavor. Gates verbose logging.
  bool get isProduction => flavor == Flavor.prod;
}
