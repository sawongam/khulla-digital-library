// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

/// App-wide logger.
///
/// Set [verbose] at startup. Debug and info are silent in production so they
/// never leak into release logs; warn and error always print.
///
/// Khulla ships no telemetry - nothing here leaves the device. A library's
/// circulation records are exactly the kind of data that must not be shipped
/// to a third party by default. If a deployment does want crash reporting,
/// [error] is the single seam to forward from, and it should be opt-in.
abstract final class AppLogger {
  static const String _defaultSource = 'Khulla Digital Library';

  /// When true, [debug] and [info] write to the console. Set `false` in
  /// production.
  static bool verbose = kDebugMode;

  /// Verbose tracing for development (bloc changes, flow breadcrumbs, etc.).
  static void debug(String message, {String? source}) {
    if (!verbose) return;
    _write(message, level: 500, source: source);
  }

  /// Notable non-error events while tracing a flow.
  static void info(String message, {String? source}) {
    if (!verbose) return;
    _write(message, level: 800, source: source);
  }

  /// Recoverable problems that should still be visible in production consoles.
  static void warn(
    String message, {
    String? source,
    Object? error,
    StackTrace? stackTrace,
  }) => _write(
    message,
    level: 900,
    source: source,
    error: error,
    stackTrace: stackTrace,
  );

  /// Unexpected failures. Always written to the console.
  static void error(
    Object error, {
    StackTrace? stackTrace,
    String? source,
    bool fatal = false,
  }) {
    _write(
      error.toString(),
      level: fatal ? 1200 : 1000,
      source: source,
      error: error,
      stackTrace: stackTrace ?? StackTrace.current,
    );
  }

  static void _write(
    String message, {
    required int level,
    String? source,
    Object? error,
    StackTrace? stackTrace,
  }) {
    developer.log(
      message,
      name: source ?? _defaultSource,
      level: level,
      error: error,
      stackTrace: stackTrace,
    );
  }
}
