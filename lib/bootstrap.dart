// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'dart:async';
import 'dart:ui';

import 'package:bloc/bloc.dart';
import 'package:flutter/widgets.dart';
import 'package:khulla/app/app.dart';
import 'package:khulla/app/bloc_observer.dart';
import 'package:khulla/core/config/app_config.dart';
import 'package:khulla/core/database/app_database.dart';
import 'package:khulla/core/di/injection.dart';
import 'package:khulla/core/error/app_exception.dart';
import 'package:khulla/core/error/guard.dart';
import 'package:khulla/core/logging/app_logger.dart';
import 'package:khulla/core/window/window_setup.dart';
import 'package:khulla/features/circulation/reservation/data/reservation_expiry_scheduler.dart';
import 'package:khulla/features/settings/domain/library_settings_repository.dart';
import 'package:khulla/features/staff_auth/presentation/auth/cubit/auth_cubit.dart';
import 'package:khulla/shared/domain/reference_data_repository.dart';
import 'package:khulla/shared/domain/reference_seed_labels.dart';

/// Shared startup for every flavor: installs error and bloc observers, sizes
/// the desktop window, wires up dependency injection for the given [config],
/// opens the local database, then runs the app.
Future<void> bootstrap(AppConfig config) async {
  WidgetsFlutterBinding.ensureInitialized();

  AppLogger.verbose = !config.isProduction;

  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    if (details.silent) return;
    AppLogger.error(
      details.exception,
      stackTrace: details.stack ?? StackTrace.empty,
      source: 'FlutterError',
      fatal: true,
    );
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    AppLogger.error(
      error,
      stackTrace: stack,
      source: 'PlatformDispatcher',
      fatal: true,
    );
    return true;
  };

  Bloc.observer = const AppBlocObserver();

  // Sized and shown before the first frame so desktop never flashes a
  // default-sized white window. No-op on web and mobile.
  await configureAppWindow(config);

  await configureDependencies(config);

  await _runApp();
}

/// Opens the database and starts the app, falling back to a readable failure
/// screen rather than a crash when the catalogue cannot be reached.
Future<void> _runApp() async {
  try {
    // Drift connects lazily, so this is what actually opens the file and
    // runs migrations. Doing it here means a broken catalogue produces a
    // readable failure screen instead of a crash mid-gesture.
    await guardDatabase(
      getIt<AppDatabase>().warmUp,
      source: 'bootstrap',
    );

    // Reading the profile is what sets `MoneyFormat.current`, so the first
    // amount the app draws is already in the library's own currency rather
    // than in the default it would then have to be corrected from.
    await getIt<LibrarySettingsRepository>().findProfile();

    await getIt<ReferenceDataRepository>().ensureDefaults(
      formatName: seedFormatName,
      memberTypeName: seedMemberTypeName,
    );

    await getIt<ReservationExpiryScheduler>().start();

    // Resolved before the first frame so the router's first redirect already
    // knows whether this catalogue needs setting up, and nobody sees the
    // dashboard flash past on the way to sign-in.
    await getIt<AuthCubit>().restoreSession();
  } on AppException catch (error, stackTrace) {
    AppLogger.error(
      error,
      stackTrace: stackTrace,
      source: 'bootstrap',
      fatal: true,
    );
    runApp(
      StartupFailureApp(
        error: error,
        onRetry: () => unawaited(_runApp()),
      ),
    );
    return;
  }

  runApp(const App());
}
