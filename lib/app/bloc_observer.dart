// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:bloc/bloc.dart';
import 'package:khulla/core/logging/app_logger.dart';

/// Routes every uncaught bloc error into [AppLogger] with the bloc's name
/// attached, so a failure is attributable without a breakpoint.
class AppBlocObserver extends BlocObserver {
  const AppBlocObserver();

  @override
  void onError(BlocBase<dynamic> bloc, Object error, StackTrace stackTrace) {
    AppLogger.error(
      error,
      stackTrace: stackTrace,
      source: '${bloc.runtimeType}',
    );
    super.onError(bloc, error, stackTrace);
  }
}
