// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';
import 'package:khulla/core/config/app_config.dart';
import 'package:khulla/core/di/injection.config.dart';

/// Application-wide service locator.
final GetIt getIt = GetIt.instance;

/// Wires up every `@injectable` binding for the given [config].
///
/// The runtime [config] is registered first so flavor-aware singletons (the
/// database, the desktop window) can depend on it, then the generated
/// initializer registers the rest. Bindings are identical across flavors -
/// the flavor only decides which database file the app opens.
@InjectableInit(preferRelativeImports: true)
Future<void> configureDependencies(AppConfig config) async {
  if (!getIt.isRegistered<AppConfig>()) {
    getIt.registerSingleton<AppConfig>(config);
  }
  await getIt.init();
}
