// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:equatable/equatable.dart';
import 'package:sqlite3/common.dart';

/// Typed, user-presentable failures surfaced by the data layer.
///
/// The data layer catches driver-level errors and converts them with
/// [AppException.fromSqlite] so presentation code only ever deals
/// with this small, exhaustive set of cases. The `message` carried here is a
/// developer-facing fallback — presentation should render
/// `AppExceptionL10n.localizedMessage` instead.
sealed class AppException extends Equatable implements Exception {
  const AppException(this.message);

  /// Maps a SQLite error onto the closest domain-level failure.
  ///
  /// SQLite reports everything as a numeric result code, but they mean very
  /// different things to a librarian: a unique violation is "that accession
  /// number already exists", a foreign-key violation is "that record is still
  /// referenced", a busy database is "try again in a moment". Classifying
  /// here keeps that judgement out of every repository.
  ///
  /// Constraint failures are read from the *extended* code, which is the only
  /// place SQLite says which constraint broke. Everything else is read from
  /// the primary code, because its extended variants (`SQLITE_BUSY_SNAPSHOT`,
  /// `SQLITE_READONLY_ROLLBACK`, …) all mean the same thing to us.
  factory AppException.fromSqlite(SqliteException error) {
    final detail = error.toString();

    if (error.resultCode == SqlError.SQLITE_CONSTRAINT) {
      return switch (error.extendedResultCode) {
        SqlExtendedError.SQLITE_CONSTRAINT_UNIQUE ||
        SqlExtendedError.SQLITE_CONSTRAINT_PRIMARYKEY =>
          DuplicateRecordException(detail),
        SqlExtendedError.SQLITE_CONSTRAINT_FOREIGNKEY =>
          const ConflictException(
            'That record is still referenced by another.',
          ),
        SqlExtendedError.SQLITE_CONSTRAINT_NOTNULL ||
        SqlExtendedError.SQLITE_CONSTRAINT_CHECK =>
          const InvalidInputException(),
        _ => DatabaseFailureException(detail),
      };
    }

    return switch (error.resultCode) {
      SqlError.SQLITE_BUSY ||
      SqlError.SQLITE_LOCKED => const DatabaseUnavailableException(
        'The library database is in use by another process.',
      ),
      SqlError.SQLITE_READONLY => const DatabaseUnavailableException(
        'The library database is read-only.',
      ),
      SqlError.SQLITE_CANTOPEN => const DatabaseUnavailableException(
        'The library database could not be opened.',
      ),
      SqlError.SQLITE_FULL => const DatabaseUnavailableException(
        'There is no room left to write to the library database.',
      ),
      // Nothing will work until these are resolved, and neither is something
      // a retry can fix — the operator needs a backup.
      SqlError.SQLITE_CORRUPT ||
      SqlError.SQLITE_NOTADB => const DatabaseUnavailableException(
        'The library database file is damaged.',
      ),
      _ => DatabaseFailureException(detail),
    };
  }

  /// Developer-facing fallback copy. Not for display.
  final String message;

  @override
  List<Object?> get props => [message];
}

/// A write violated a uniqueness rule — a duplicate ISBN, accession number,
/// or membership id.
class DuplicateRecordException extends AppException {
  const DuplicateRecordException([String? message])
    : super(message ?? 'That record already exists.');
}

/// The requested record does not exist, or was deleted by another window.
class NotFoundException extends AppException {
  const NotFoundException([String? message])
    : super(message ?? 'We could not find that.');
}

/// The payload failed a domain rule before or during persistence.
class InvalidInputException extends AppException {
  const InvalidInputException([String? message])
    : super(message ?? 'Some of those details are not valid.');
}

/// The action conflicts with the current state — returning a copy that is not
/// on loan, borrowing one that is already out.
class ConflictException extends AppException {
  const ConflictException([String? message])
    : super(message ?? 'That action conflicts with the current record.');
}

/// The database could not be opened, was closed underneath a query, or is
/// read-only. Distinct from a failed statement: nothing will work until it is
/// resolved.
class DatabaseUnavailableException extends AppException {
  const DatabaseUnavailableException([String? message])
    : super(message ?? 'The library database is unavailable.');
}

/// A statement failed for a reason we could not classify further.
class DatabaseFailureException extends AppException {
  const DatabaseFailureException([String? message])
    : super(message ?? 'The database rejected that change.');
}

/// Reading or writing a file failed — a cover image, an import, an export.
class StorageException extends AppException {
  const StorageException([String? message])
    : super(message ?? 'A file could not be read or written.');
}

/// Anything we could not classify.
class UnknownException extends AppException {
  const UnknownException() : super('An unexpected error occurred.');
}
