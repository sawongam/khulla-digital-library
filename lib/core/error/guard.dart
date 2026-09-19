// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:drift/drift.dart';
// `drift/remote.dart` is marked experimental, but it is the only public home
// of DriftRemoteException — the wrapper every failure on the database isolate
// arrives in. Not unwrapping it would degrade every constraint violation to
// UnknownException.
// ignore: experimental_member_use
import 'package:drift/remote.dart';
import 'package:khulla/core/error/app_exception.dart';
import 'package:khulla/core/logging/app_logger.dart';
import 'package:sqlite3/common.dart';

/// Runs [action], converting anything it throws into an [AppException].
///
/// Every data-source method that touches the database wraps its body in this
/// so a cubit only ever has to catch [AppException]. An [AppException] thrown
/// deliberately inside [action] — a domain rule rejecting the write — passes
/// through untouched, including one thrown on the database isolate.
///
/// ```dart
/// Future<List<Title>> findAll() => guardDatabase(
///   () => _db.select(_db.titles).get().then(toDomain),
///   source: 'TitleLocalDataSource.findAll',
/// );
/// ```
Future<T> guardDatabase<T>(
  Future<T> Function() action, {
  String? source,
}) async {
  try {
    return await action();
  } on AppException {
    rethrow;
  } on DriftRemoteException catch (error, stackTrace) {
    // On native the database lives on a background isolate, so every failure
    // arrives wrapped. Unwrap before classifying, or a constraint violation
    // degrades to UnknownException and the librarian gets "something went
    // wrong" instead of "that ISBN already exists".
    throw _classify(error.remoteCause, source: source, stackTrace: stackTrace);
  } on Object catch (error, stackTrace) {
    throw _classify(error, source: source, stackTrace: stackTrace);
  }
}

AppException _classify(
  Object error, {
  required StackTrace stackTrace,
  String? source,
}) {
  switch (error) {
    case AppException():
      return error;

    case SqliteException():
      AppLogger.warn(
        'Database call failed (${error.extendedResultCode})',
        source: source,
        error: error,
        stackTrace: stackTrace,
      );
      return AppException.fromSqlite(error);

    // Drift rejected the row before it reached SQLite — a value longer than
    // the column allows, a null in a non-nullable column.
    case InvalidDataException():
      AppLogger.warn(
        'Row rejected before reaching SQLite',
        source: source,
        error: error,
        stackTrace: stackTrace,
      );
      return InvalidInputException(error.message);

    // Drift caught a driver error it could explain. The explanation is the
    // useful part for us; the cause is what carries the result code.
    case DriftWrappedException(:final cause?):
      return _classify(cause, source: source, stackTrace: stackTrace);

    case _:
      AppLogger.error(error, stackTrace: stackTrace, source: source);
      return const UnknownException();
  }
}
