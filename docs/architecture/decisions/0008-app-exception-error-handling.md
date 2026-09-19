# ADR 0008 - `AppException` and `guardDatabase` for error handling

**Status:** Accepted · **Date:** 2026-09-03

## Context

A local-first app with a single SQLite database has a well-defined set of things that can go wrong: a constraint is violated, the file is locked, a row is not found, a disk is full. What the app must never do is let a raw database exception - a `SqliteException` carrying an SQLite result code - reach a widget or a cubit, because:

- **The cubit and page layers have no business knowing about SQLite.** If an `on SqliteException` catch block exists in a page, the domain boundary has already been crossed. Database driver types are an implementation detail of the data layer.
- **Raw exceptions have no stable API for the layers above.** `SqliteException.extendedResultCode` is a reliable integer, but it is not a concept a UI can reason about. A cubit needs to know that a record already exists, not that SQLite returned `SQLITE_CONSTRAINT_UNIQUE (2067)`.
- **Different platforms surface different exception types.** On native, failures arrive wrapped in `DriftRemoteException` because the database runs on a background isolate. On web, the path differs again. A catch block at the page layer that names a driver type breaks silently on the other platform.
- **Unhandled exceptions crash.** A data source method that throws a raw `SqliteException` and is not caught turns a "that ISBN is already in use" moment into a red screen and a stack trace the librarian cannot act on.

Several patterns were evaluated:

**Catch everything at the cubit.** Each cubit wraps its data-source calls in `try/catch on Object`. This is universal but leaves the cubit filtering driver types - exactly the domain-boundary violation above.

**Return a `Result<T, E>` type.** Functional pattern; the data source returns `Ok(value)` or `Err(exception)`, and cubits pattern-match on the result. This works, but Dart does not have a built-in `Result` type, and adding a third-party one (e.g., `fpdart`) is a dependency and a conceptual shift for contributors who know `try/catch`. The same information flows through a small sealed class and a `try/catch` without the functional framing.

**Convert at the data-source boundary with a sealed exception type.** The data source wraps its method bodies in `guardDatabase`, which catches driver exceptions and maps them to a small sealed `AppException` hierarchy. Everything above the data source catches `AppException` - a stable, domain-aligned type - not driver types. This is the approach chosen.

## Decision

Use **`AppException`** - a sealed class - as the only exception type that crosses the data-source boundary. Wrap every data-source method body with **`guardDatabase`**, which converts driver exceptions to `AppException` instances. Nothing above `LocalDataSource` imports a drift or sqlite3 type.

### `AppException` hierarchy

```dart
// lib/core/error/app_exception.dart
sealed class AppException implements Exception {
  const AppException({required this.source, this.stackTrace});

  final String source;
  final StackTrace? stackTrace;
}

/// The record already exists (UNIQUE / PRIMARY KEY constraint).
final class DuplicateRecordException extends AppException { … }

/// The operation conflicts with an existing reference (FOREIGN KEY constraint).
/// "This author still has titles - cannot delete."
final class ConflictException extends AppException { … }

/// The data provided was structurally invalid (NOT NULL / CHECK constraint).
final class InvalidInputException extends AppException { … }

/// The database file or connection is unavailable (locked, full, corrupt, downgrade).
final class DatabaseUnavailableException extends AppException { … }

/// A query returned no row where one was required.
final class RecordNotFoundException extends AppException { … }

/// An error that does not fit the cases above.
final class DatabaseFailureException extends AppException { … }
```

The hierarchy is deliberately small. It reflects decisions the app can act on, not every SQLite error code. An SQLite `SQLITE_IOERR_WRITE` and `SQLITE_FULL` both map to `DatabaseUnavailableException` because the app's response to both is identical: surface a localized message and a retry, not a description of the underlying OS error.

### `guardDatabase`

```dart
// lib/core/error/guard.dart
Future<T> guardDatabase<T>(
  String source,
  Future<T> Function() body,
) async {
  try {
    return await body();
  } on AppException {
    rethrow;
  } on DriftRemoteException catch (error, stackTrace) {
    // Native runs the database on a background isolate; failures arrive wrapped.
    // Unwrap before classifying - or every constraint violation degrades to
    // DatabaseFailureException.
    throw _classify(error.remoteCause, source: source, stackTrace: stackTrace);
  } on Object catch (error, stackTrace) {
    throw _classify(error, source: source, stackTrace: stackTrace);
  }
}
```

The `on AppException { rethrow }` arm handles deliberate domain rejections thrown inside the body - e.g., a data source that validates a business rule before writing and throws `InvalidInputException` explicitly. That must pass through without being re-classified.

The `DriftRemoteException` unwrap is not optional. Every native query crosses an isolate boundary; the real exception is nested inside. Without the unwrap, the `_classify` function receives a `DriftRemoteException` and falls through to `DatabaseFailureException` regardless of which constraint was violated.

### `_classify`

```dart
AppException _classify(Object error, {required String source, StackTrace? stackTrace}) {
  if (error is AppException) return error;          // already classified, cross-isolate
  if (error is DriftWrappedException) {
    return _classify(error.cause, source: source, stackTrace: stackTrace);
  }
  if (error is InvalidDataException) {
    return InvalidInputException(source: source, stackTrace: stackTrace);
  }
  if (error is SqliteException) {
    return AppException.fromSqlite(error, source: source, stackTrace: stackTrace);
  }
  return DatabaseFailureException(source: source, stackTrace: stackTrace);
}
```

`AppException.fromSqlite` reads SQLite result codes and maps them to the hierarchy. Constraint violations are read from the **extended code** - the only place SQLite names which constraint broke - and everything else from the primary code, because extended variants of `SQLITE_BUSY` and `SQLITE_READONLY` all mean the same thing to this app.

| Extended / primary code | Constant                           | Maps to                        |
| ----------------------- | ---------------------------------- | ------------------------------ |
| 2067                    | `SQLITE_CONSTRAINT_UNIQUE`         | `DuplicateRecordException`     |
| 1555                    | `SQLITE_CONSTRAINT_PRIMARYKEY`     | `DuplicateRecordException`     |
| 787                     | `SQLITE_CONSTRAINT_FOREIGNKEY`     | `ConflictException`            |
| 1299                    | `SQLITE_CONSTRAINT_NOTNULL`        | `InvalidInputException`        |
| 275                     | `SQLITE_CONSTRAINT_CHECK`          | `InvalidInputException`        |
| 5 / 6                   | `SQLITE_BUSY` / `SQLITE_LOCKED`    | `DatabaseUnavailableException` |
| 8                       | `SQLITE_READONLY`                  | `DatabaseUnavailableException` |
| 14                      | `SQLITE_CANTOPEN`                  | `DatabaseUnavailableException` |
| 13                      | `SQLITE_FULL`                      | `DatabaseUnavailableException` |
| 11 / 26                 | `SQLITE_CORRUPT` / `SQLITE_NOTADB` | `DatabaseUnavailableException` |
| anything else           | -                                  | `DatabaseFailureException`     |

### Usage pattern in a data source

```dart
// features/catalog/title/data/local_title_data_source.dart
@LazySingleton(as: TitleLocalDataSource)
class LocalTitleDataSource implements TitleLocalDataSource {
  LocalTitleDataSource(this._db);
  final AppDatabase _db;

  @override
  Future<Title> insertTitle(TitleCompanion companion) => guardDatabase(
    'LocalTitleDataSource.insertTitle',
    () async {
      final id = await _db.into(_db.titles).insert(companion);
      return _db.select(_db.titles)
          ..[where: (t) => t.id.equals(id)]
          .getSingle()
          .then((row) => row.toDomain());
    },
  );

  @override
  Stream<List<Title>> watchTitles() => guardDatabase(
    'LocalTitleDataSource.watchTitles',
    // Streams: guardDatabase handles the initial open; errors on the stream
    // are handled in the cubit's listen(onError:) - not here.
    () async => (_db.select(_db.titles)).watch().map(
          (rows) => rows.map((r) => r.toDomain()).toList(),
        ),
  );
}
```

The `source` parameter is a string that names the call site. It appears in logs and in `AppException.toString()` so that a bug report or a log line says where the failure originated without a stack trace being required.

### Cubit handling

Cubits catch `AppException`. They do not catch `Object` at the data layer - an `on Object` in a cubit is usually covering a bug, not a business case.

```dart
Future<void> loadTitles() async {
  emit(state.copyWith(status: LoadStatus.loading, error: null));
  try {
    final titles = await _repository.getTitles();
    emit(state.copyWith(status: LoadStatus.loaded, titles: titles));
  } on AppException catch (e) {
    emit(state.copyWith(status: LoadStatus.error, error: e));
  }
}
```

Writes emit the error and rethrow, so the call site (a button handler) can show a toast:

```dart
Future<void> saveTitle(TitleForm form) async {
  emit(state.copyWith(status: LoadStatus.saving, error: null));
  try {
    await _repository.saveTitle(form.toTitle());
    emit(state.copyWith(status: LoadStatus.loaded));
  } on AppException catch (e) {
    emit(state.copyWith(status: LoadStatus.error, error: e));
    rethrow;
  }
}
```

### Page rendering

Pages never read `error.message` - the raw exception message is English driver text, not a localized user string. Pages use `AppExceptionL10n.localizedMessage(context, error)` (`lib/core/error/app_exception_l10n.dart`), which pattern-matches on the sealed hierarchy and returns the correct ARB string for the locale. A `DuplicateRecordException` displays `context.l10n.errorDuplicateRecord`. A `DatabaseUnavailableException` at startup displays the startup-failure message via `StartupFailureApp`.

This indirection keeps error strings in ARB (where translators find them) and out of `AppException` (which carries codes and sources, not presentation).

## Consequences

**What this buys**

- Driver types never appear above the data source. A cubit that catches `AppException` compiles identically on native and web, against drift and against any future data source.
- The sealed hierarchy is exhaustive. A `switch` on `AppException` in the presentation layer gets a warning if a new subclass is added and the switch is not updated.
- `source` in every exception provides a free breadcrumb for the logging observer. `BlocObserver.onError` receives the exception and its source string; the log line says where in the data layer it originated without the observer needing to inspect a stack trace.
- `test/core/error/app_exception_test.dart` runs every row of the classification table against a real in-memory drift database, including the foreign-key case that requires `PRAGMA foreign_keys = ON` to be in effect. The test also proves that `guardDatabase` passes through a deliberately thrown `AppException` without re-classifying it.

**What this costs**

- Every data-source method body must be wrapped in `guardDatabase`. A method that forgets the wrapper throws a raw `SqliteException` into a cubit that expects `AppException` - which is an unhandled exception. The omission is detectable in code review but not by the analyzer today. A custom lint that flags an `async` method in a `LocalDataSource` class with no `guardDatabase` call would close this gap.
- `DriftRemoteException` lives in `package:drift/remote.dart`, marked `@experimental`. It is the only home of the type that every native isolate failure arrives in, so the import is unavoidable. It is documented with `// ignore: experimental_member_use` and pinned to the drift version.
- Adding a new `AppException` subclass requires updating `AppExceptionL10n`, adding an ARB key, and running `make localize`. This is the correct sequence - a new error condition has a new localized string - but it is three steps, and the sealed exhaustiveness warning is the only static reminder.

## Revisiting

The trigger to expand the hierarchy is a new category of database error that requires a meaningfully different response. "This record is locked by another process" is `DatabaseUnavailableException` today because this app has no other process. A sync layer that introduces write conflicts might justify a `WriteConflictException` - but only if the cubit or the UI would respond differently to it than to `DatabaseUnavailableException`. A distinction that exists only in the log string is not a reason to add a new subclass.

The trigger to change `guardDatabase` from a function to a mixin or base class is a codebase where data sources consistently forget to call it. That is a training problem first and a structural change second.
