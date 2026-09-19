# ADR 0002 - Drift over raw sqflite for persistence

**Status:** Accepted · **Date:** 2026-09-02 · **Supersedes the persistence clause of** [ADR 0001](0001-local-first-flutter.md)

## Context

ADR 0001 chose `sqflite` - one API (`sqflite_common`) over three backends. That wiring exists and works: `AppDatabase`, `database_platform.dart` with its native/web conditional export, a hand-rolled append-only `Migration` list, `guardDatabase`, and `AppException.fromDatabaseException`.

What it does not have is a single table. `appMigrations` is empty. **This is the cheapest moment in the project's life to change the persistence layer** - there is no shipped catalogue whose schema was built by a frozen `up()`, so the append-only promise costs nothing to restart.

The pressure that makes the change worth making now:

- **Every row is untyped.** `row[FineTable.amount]` is an `Object?`. A typo in a column constant, a column that changed type, a nullable column read as non-null - all of them compile, and all of them fail at a librarian's desk rather than in `make analyze`.
- **Migrations are correct only by inspection.** `debugMigrationsAreWellOrdered()` catches duplicate version numbers. Nothing catches a migration that produces a _different_ schema than a fresh install would - the classic divergence where v1→v5 upgrades and clean v5 installs disagree about a column's default.
- **Every read re-runs by hand.** A checkout has to know which screens to tell. On a local-first app where the database _is_ the source of truth, that plumbing is pure cost.
- **`Money` has to be re-applied at every boundary.** `row[...].toMoney()` on the way in, `money.minorUnits` on the way out, once per column per query, forever. One forgotten call is a 100× error in a fine.

## Decision

**Adopt `drift` as the persistence layer.** Delete the hand-rolled migration framework and the sqflite backend triad; keep `AppDatabase` as the injected seam, keep `guardDatabase`, keep `AppException`, keep the `Repository → DataSource` split.

### On "no lock-in"

Worth being precise, because the framing in the request is half right.

**At the file level there is genuinely none.** Drift is a code generator over ordinary SQLite. The `.db` file it produces is a plain SQLite database with no drift-specific tables, no metadata, no magic - `sqlite3 khulla.db .dump` gives you the whole catalogue, and any other tool reads it. Backup, export and "open it in DB Browser" all keep working. That is the property that matters for a library holding its only copy of its records.

**At the Dart level there is more lock-in than raw sqflite, not less.** Table classes, generated data classes, companions and DAOs are drift API. Moving off drift later means rewriting the data layer - though not the domain models, not the cubits, and not the pages, because the repository interfaces in `domain/` never see drift at all. That boundary is the insurance, and it is already in the architecture.

Two escape hatches keep the ceiling from ever being a wall: `customSelect` / `customStatement` run arbitrary SQL against the same connection and return raw rows, and `.drift` files let a query be written as plain SQL and still get a typed result class. Nothing drift generates has to be used.

The trade is: a little more Dart-level coupling, in exchange for a compile-checked schema and migration tooling that we would otherwise have to build.

## Package set

Verified against pub.dev on 2026-09-01.

| Package         | Version   | Role                                                                        |
| --------------- | --------- | --------------------------------------------------------------------------- |
| `drift`         | `^2.34.3` | Runtime - query builder, streams, migration API                             |
| `drift_flutter` | `^0.3.1`  | `driftDatabase()` - the per-platform executor, background isolate on native |
| `sqlite3`       | `^3.5.2`  | Native SQLite, bundled via Dart build hooks                                 |
| `drift_dev`     | `^2.34.5` | Code generator + `make-migrations` CLI (dev dependency)                     |

Removed: `sqflite`, `sqflite_common`, `sqflite_common_ffi`, `sqflite_common_ffi_web`. `path`, `path_provider` and `injectable` stay.

### `sqlite3` v3 is a real change, not a version bump

`package:sqlite3` 3.x replaced platform build scripts with **Dart build hooks**, stable in Dart 3.10 / Flutter 3.38. Consequences worth knowing before the first CI run:

- **`sqlite3_flutter_libs` is end-of-life** (`0.6.0+eol`, a no-op package). Do not add it. `drift_flutter` still lists it as a dependency for older consumers; that resolves to the empty package and is harmless.
- **The build downloads prebuilt binaries** from the `sqlite3.dart` GitHub releases at build time. A fully offline or network-restricted CI runner will fail. If that becomes a problem, `hooks: user_defines: sqlite3: {source: system}` uses the OS library, and `source: source` compiles from a vendored `sqlite3.c`.
- **FTS5, R-Tree and the math functions are compiled in** by default. Catalogue full-text search over titles, authors and subjects needs no extra setup - a real win over whatever SQLite version an Android device happens to ship.
- `open.overrideFor` and `applyWorkaroundToOpenSqlite3OnOldAndroidVersions` are gone. We use neither.

### pubspec.yaml

```yaml
dependencies:
  # Local database - drift over sqlite3. One typed API across every target:
  # a background isolate on native, sqlite3-in-WebAssembly on web.
  drift: ^2.34.3
  drift_flutter: ^0.3.1
  sqlite3: ^3.5.2

dev_dependencies:
  drift_dev: ^2.34.5
```

Delete the four `sqflite*` entries. Nothing else in `dependencies` moves.

## What the code becomes

### Files deleted

```
lib/core/database/migrations/migration.dart       # drift's Migrator replaces the interface
lib/core/database/migrations/migrations.dart      # generated steps replace the list
test/core/database/migrations_test.dart           # generated migration tests replace it
```

### The platform pair survives, narrowed

The original draft of this ADR deleted `database_platform.dart` too, on the grounds that `driftDatabase()` is the same reconciliation maintained upstream. That is true of the _backend_ choice and false of everything else: `package:path_provider` imports `dart:io`, so a library that resolves an application-support path cannot be in the web compile graph at all. `drift_flutter` solves this with its own conditional export, and so must we.

What is left behind the pair is much smaller than what sqflite needed - two things drift cannot decide for us:

- **where the file lives.** Native needs a path, and drift defaults to the _documents_ directory; the catalogue is app-managed state and belongs in application support. Web has no path, only a store keyed by name.
- **write-ahead logging.** Native only, passed through `DriftNativeOptions.setup` as a top-level function (it crosses an isolate boundary, so it may not capture). The WebAssembly virtual file system does not implement WAL.

The `if (kIsWeb)` ban is unchanged: this pair is where a platform difference goes, and there is no second one.

### Files added

```
lib/core/database/
├── app_database.dart          # @DriftDatabase, MigrationStrategy, warmUp()
├── app_database.g.dart        # generated, not committed
├── app_database.steps.dart    # generated by make-migrations, COMMITTED
├── connection.dart            # driftDatabase() wiring from AppConfig
├── database_platform.dart     # kept: file location + WAL (see below)
└── converters/
    └── money_converter.dart   # Money ↔ int minor units
drift_schemas/                 # drift_schema_v1.json, v2… - COMMITTED
test/drift/                    # generated migration tests - COMMITTED
```

Table classes live with the sub-feature that owns them (`features/catalog/title/data/tables/titles.dart`), not in `core/` - `core/` owns the connection, not the schema.

The schema JSONs and the generated migration tests **are committed**, unlike `.g.dart`. They are the record of what every shipped version's schema looked like; without them `make-migrations` cannot tell what changed, and the append-only guarantee has nothing to check against. No `.gitignore` change was needed - neither is a `*.g.dart`.

Neither directory exists yet at the time of writing: there are no tables, so there is no schema to record. **The first table lands at v1**, not v2, and `make migrate` records `drift_schema_v1.json` then. Anyone who ran a build before that point should delete their dev catalogue, whose `user_version` is already 1 with nothing in it.

### Connection

```dart
// lib/core/database/connection.dart
DatabaseConnection openDatabaseConnection(AppConfig config) => driftDatabase(
  name: config.databaseName,
  native: DriftNativeOptions(
    databasePath: () => resolveDatabasePath(config.databaseName),
    setup: configureNativeConnection,
  ),
  web: DriftWebOptions(
    sqlite3Wasm: Uri.parse('sqlite3.wasm'),
    driftWorker: Uri.parse('drift_worker.js'),
    onResult: _reportWebStorage,
  ),
);
```

Both native callbacks come from `database_platform.dart`, so `path_provider` never enters the web compile graph.

`AppConfig.databaseFileName` became `databaseName` (`khulla_dev` / `khulla`, no extension) - drift appends `.sqlite` on native and uses the bare name as the OPFS or IndexedDB key on web, so one field still isolates the flavors on every platform.

`_reportWebStorage` is not decoration. On web, drift silently degrades to `inMemory` when the browser offers nothing persistent - a librarian would enter a day of circulation and lose it on refresh with no error anywhere. It logs the chosen tier either way, and warns with the missing features when the tier is a fallback. A web build that becomes a system of record needs to say so on screen, not only in a console.

### The database class

```dart
// lib/core/database/app_database.dart
@lazySingleton
@DriftDatabase()
class AppDatabase extends _$AppDatabase {
  AppDatabase(AppConfig config) : super(openDatabaseConnection(config));

  @visibleForTesting
  AppDatabase.connect(super.e);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: _createSchema,
    onUpgrade: _upgradeSchema,
    beforeOpen: (_) async {
      // Foreign keys default to OFF, per connection, and cannot be set inside
      // a transaction - which is why this is here and not in a migration.
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );

  /// Forces the connection open and runs migrations now, not on first query.
  Future<void> warmUp() => customSelect('SELECT 1').get();

  @disposeMethod
  Future<void> dispose() => close();

  Future<void> _upgradeSchema(Migrator m, int from, int to) async {
    if (from > to) {
      throw const DatabaseUnavailableException(
        'This library file was created by a newer version of Khulla.',
      );
    }
    // await stepByStep(from1To2: …)(m, from, to);  ← once make migrate runs
  }
}
```

Three details that are easy to get wrong and expensive to get wrong:

- **The downgrade guard is not optional.** Drift's `OpeningDetails.hadUpgrade` is true whenever the stored version differs from `schemaVersion` in either direction, and it routes both through `onUpgrade`. Without the `from > to` check, a v3 build opening a v5 catalogue runs no steps, reports success, and then reads a schema it does not understand. This is the one behaviour ADR 0001 called out by name, and drift does not give it to us for free.
- **`warmUp()` exists because drift connects lazily.** Nothing opens the file until the first statement. `bootstrap` needs a locked file or a newer schema to fail _before_ the first frame so it can show `StartupFailureApp`, so it runs one trivial query.
- **A migration step must never touch `this`.** Steps receive their own schema snapshot; referring to the live database inside one silently uses today's schema instead of that version's, which is how a migration passes in development and corrupts a real upgrade.

### Money

`Money` is an extension type over an `int` of minor units, which makes the converter trivial and makes forgetting it impossible:

```dart
// lib/core/database/converters/money_converter.dart
class MoneyConverter extends TypeConverter<Money, int> {
  const MoneyConverter();

  @override
  Money fromSql(int fromDb) => Money(fromDb);

  @override
  int toSql(Money value) => value.minorUnits;
}
```

```dart
class Fines extends Table {
  IntColumn get amount => integer().map(const MoneyConverter())();
}
```

The generated `Fine` data class carries a `Money amount` field. The `.toMoney()` / `.minorUnits` calls in the Money edge table stop applying to database reads and writes - those two rows collapse into this converter. The text-field and display edges are untouched.

**The column is still a plain SQLite integer of paisa.** `kMinorUnitsPerMajor` stays fixed at 100 and the storage unit stays out of the type system's reach. A converter that divided here would reinterpret every amount already stored.

### Dates

Drift stores `DateTime` as a unix timestamp integer by default; `store_date_time_values_as_text: true` in `build.yaml` stores ISO-8601 strings with offsets instead. **Choose text.** Due dates, loan dates and fine accrual dates are wall-clock facts about a library's day, and an integer timestamp silently loses the timezone the librarian was standing in. Changing this later means a data migration over every date column - drift ships a guide for it precisely because it is painful. Decide once, now, before the first migration exists.

### Error handling

`guardDatabase` and `AppException` survive; only the driver types change. The catch chain became a single `_classify` walk, because a failure can arrive nested:

```dart
} on AppException {
  rethrow;
} on DriftRemoteException catch (error, stackTrace) {
  // Native runs the database on a background isolate, so everything arrives
  // wrapped. Unwrap before classifying, or every constraint violation
  // degrades to UnknownException.
  throw _classify(error.remoteCause, source: source, stackTrace: stackTrace);
} on Object catch (error, stackTrace) {
  throw _classify(error, source: source, stackTrace: stackTrace);
}
```

`_classify` handles `SqliteException` (the result code), `InvalidDataException` (drift rejected the row before SQLite saw it), `DriftWrappedException` (recurse into its `cause`), and an `AppException` that crossed the isolate boundary intact - a deliberate domain rejection must still pass through untouched even when it was thrown on the database isolate.

One wart: `DriftRemoteException` lives in `package:drift/remote.dart`, which is marked experimental. It is the only public home of the type every isolate-side failure arrives in, so the import carries a documented `// ignore: experimental_member_use`.

`AppException.fromDatabaseException` became `AppException.fromSqlite`, reading `SqliteException` result codes instead of sqflite's `isUniqueConstraintError()` helpers. **Constraints are read from the extended code - the only place SQLite says which constraint broke - and everything else from the primary code**, because the extended variants of busy and read-only (`SQLITE_BUSY_SNAPSHOT`, `SQLITE_READONLY_ROLLBACK`, …) all mean the same thing to us and would otherwise fall through to the catch-all.

| Code          | Constant                           | Maps to                                                      |
| ------------- | ---------------------------------- | ------------------------------------------------------------ |
| 2067          | `SQLITE_CONSTRAINT_UNIQUE`         | `DuplicateRecordException`                                   |
| 1555          | `SQLITE_CONSTRAINT_PRIMARYKEY`     | `DuplicateRecordException`                                   |
| 787           | `SQLITE_CONSTRAINT_FOREIGNKEY`     | `ConflictException` - the record is still referenced         |
| 1299          | `SQLITE_CONSTRAINT_NOTNULL`        | `InvalidInputException`                                      |
| 275           | `SQLITE_CONSTRAINT_CHECK`          | `InvalidInputException`                                      |
| 5 / 6         | `SQLITE_BUSY` / `SQLITE_LOCKED`    | `DatabaseUnavailableException`                               |
| 8             | `SQLITE_READONLY`                  | `DatabaseUnavailableException`                               |
| 14            | `SQLITE_CANTOPEN`                  | `DatabaseUnavailableException`                               |
| 13            | `SQLITE_FULL`                      | `DatabaseUnavailableException`                               |
| 11 / 26       | `SQLITE_CORRUPT` / `SQLITE_NOTADB` | `DatabaseUnavailableException` - needs a backup, not a retry |
| anything else | -                                  | `DatabaseFailureException`                                   |

Note 787 moving to `ConflictException` rather than the old catch-all: under sqflite there was no FK predicate to test, so the case was invisible. "That record is still referenced" is exactly the `ConflictException` docstring, and it is the error a librarian hits deleting an author who still has titles.

`test/core/error/app_exception_test.dart` pins every row of that table, and runs the unique-violation and foreign-key cases against a real in-memory database through `guardDatabase` - which is also what proves `beforeOpen`'s `PRAGMA foreign_keys = ON` is actually in effect.

### Streams and cubits

`watch()` turns any query into an auto-updating stream: drift tracks which tables a query reads and re-runs it when a write touches one. A checkout updates the loans list, the member's page and the dashboard counts with no cross-cubit notification.

This is a real simplification but it is not free, and it comes with rules that sit alongside the existing `LoadStatus` convention:

- **Streams update more often than they need to.** Drift invalidates per table, not per row - any write to `loans` re-runs every query reading `loans`. Keep watched queries narrow and cheap. A watched query that scans ten thousand titles to compute a dashboard number will re-run on every checkout.
- **`customStatement` writes do not notify.** Raw SQL bypasses the tracking; call `notifyUpdates()` explicitly, or the screen quietly shows stale data.
- **A cubit that subscribes must cancel.** `StreamSubscription` in the cubit, cancelled in `close()`. The existing `isClosed`-after-`await` rule covers one-shot reads and does not cover a live subscription.
- **The reads-swallow/writes-rethrow split is unchanged.** A stream's error goes into `state.error` the same way a failed `load<Noun>s()` does - `stream.listen(onData, onError:)`, not an unhandled stream error taking down the zone.

Start with one-shot `get()` reads in the first feature and convert to `watch()` where a screen demonstrably needs to react to another screen's write. `LoadStatus` and the three getters stay exactly as they are.

## Build and tooling

### build.yaml

The repo has no `build.yaml` today. One is now required - `make-migrations` reads the database location from it.

```yaml
targets:
  $default:
    builders:
      drift_dev:
        options:
          databases:
            app_database: lib/core/database/app_database.dart
          schema_dir: drift_schemas/
          test_dir: test/drift/
          store_date_time_values_as_text: true
          named_parameters: true
```

**No conflict with the existing generators.** `drift_dev` is a part builder writing `<file>.g.dart`, the same output slot as `json_serializable` - two builders cannot both claim one file's part. They never will here as long as **the database file and the table files carry no `@freezed` or `@JsonSerializable` annotations**, which they should not: tables are schema, domain models are `freezed`, and mappers move between them. That is the current architecture, unchanged.

Modular generation (`drift_dev:modular`, emitting `.drift.dart` libraries instead of part files) exists and would sidestep the question entirely, but it changes how generated queries are accessed and only pays off on large schemas. Not worth it yet; revisit if build times become a problem.

`injectable` is unaffected - `AppDatabase` keeps its `@lazySingleton` and its `AppConfig` constructor parameter, so the generated wiring is identical to today's.

### Makefile

```make
## Generate schema exports, step-by-step migrations and migration tests.
## Run after changing a table and bumping schemaVersion.
migrate:
	dart run drift_dev make-migrations

DRIFT_RELEASE := drift-2.34.3

## Fetch sqlite3.wasm and the drift worker into web/.
## Only needed after upgrading drift - the output is checked in.
db-web:
	curl -L -o web/sqlite3.wasm \
	  https://github.com/simolus3/drift/releases/download/$(DRIFT_RELEASE)/sqlite3.wasm
	curl -L -o web/drift_worker.js \
	  https://github.com/simolus3/drift/releases/download/$(DRIFT_RELEASE)/drift_worker.js
```

`db-web` replaces the `sqflite_common_ffi_web:setup` call; delete `web/sqflite_sw.js` and re-fetch `web/sqlite3.wasm` from the drift release (the two builds are not interchangeable). Both assets ship as attachments on every drift tag from 2.34.2 onward - pin `DRIFT_RELEASE` to the `drift` version in `pubspec.yaml` and bump them together.

**The server must send `sqlite3.wasm` as `Content-Type: application/wasm`.** Flutter's dev server does; a static host may not, and the failure mode is drift falling back to a slower path or to memory rather than erroring.

### Definition of done - additions

The definition of done gains two steps:

- `make migrate` after changing any table or bumping `schemaVersion`, before `make build`.
- The generated migration tests are part of `make test`. A schema change with a red migration test is not done.

### Migration workflow, day to day

1. Change a table class.
2. Bump `schemaVersion`.
3. `dart run drift_dev make-migrations` - writes `drift_schemas/drift_schema_vN.json`, regenerates `app_database.steps.dart`, and generates a test under `test/drift/`.
4. Fill in the new `fromNToM:` callback with `Migrator` calls (`createTable`, `addColumn`, `alterTable(TableMigration(...))`).
5. `make test`. The generated test builds a database at the old schema, migrates it, and asserts the result matches a clean install of the new schema.

Step 5 is the thing the hand-rolled framework could not do. `debugMigrationsAreWellOrdered()` checked that version numbers were a gapless run; this checks that the _schema_ an upgrade produces is the schema a fresh install produces - the divergence that actually loses data.

The append-only rule is unchanged and now enforced rather than documented: a shipped `drift_schema_vN.json` is frozen, and editing an old step makes its test fail against the recorded schema.

## Consequences

**What this buys**

- The schema is compile-checked. A renamed column is an analyzer error at every call site, not a runtime null at the circulation desk.
- Migrations are tested, not inspected. The v1→vN path and the clean-vN install are proven equal on every `make test`.
- `Money` crosses the database boundary once, in a converter, instead of at every column read.
- Screens can react to writes without cross-cubit plumbing.
- FTS5 is available for catalogue search with no extra dependency and no per-platform doubt.
- Roughly 400 lines of hand-rolled platform and migration code stop being ours to maintain.

**What this costs**

- More generated code and a slower `build_runner`. Mitigable with modular generation if it bites.
- `drift_schemas/` and `test/drift/` are committed artifacts that must not be hand-edited - a new rule for contributors to learn.
- Dart-level coupling to drift in `data/`. `domain/` and everything above it stay clean, which is where the insurance lives.
- Build hooks download native binaries at build time; a locked-down CI needs `source: system` or a vendored `sqlite3.c`.
- Two web assets to keep in step with the `drift` version instead of one `setup` command.

**What this does not change**

Everything above the data layer. Repository and data-source interfaces, `AppException`, `guardDatabase`'s contract, `LoadStatus`, the reads-swallow/writes-rethrow rule, cubit naming, `bootstrap`'s `StartupFailureApp` path, and the ADR 0001 promise that a downgrade refuses to open rather than deleting.

## What shipped

Steps 1–4 and 6 of the original plan shipped with this decision:

1. **Dependencies swapped.** `drift 2.34.3`, `drift_flutter 0.3.1`, `sqlite3 3.5.2`, `drift_dev 2.34.5`; all four `sqflite*` packages gone. `sqlite3_flutter_libs` resolves transitively as `0.6.0+eol`, the empty package, as predicted.
2. **Web assets.** `sqlite3.wasm` re-fetched from the `drift-2.34.3` release, `drift_worker.js` added, `sqflite_sw.js` deleted, `make db-web` rewritten around a pinned `DRIFT_RELEASE`.
3. **Connection, database class, `build.yaml`.** The old migration framework and its test are deleted; `bootstrap` calls `warmUp()`; `AppConfig.databaseName` replaces `databaseFileName`; `database_platform.dart` kept and narrowed.
4. **Errors.** `AppException.fromSqlite`, the `_classify` chain in `guardDatabase`, and thirteen tests over both.
5. **Docs.** The Database, Money, definition-of-done and command-table sections of the contributor docs; the superseded clause in ADR 0001.

Verified with `make analyze` (clean, `--fatal-infos`) and `make test` (green, including a real in-memory drift database). Not verified: the app has not been run, and no build has been produced for Windows or web - **the `sqlite3` build hook is proven under `flutter test` on Linux and nowhere else yet.** That is the one step most likely to surprise.

**Step 5 - the first table - was deliberately left out.** It belonged to whichever `catalog` sub-feature landed first, with its schema reviewed as part of that feature rather than invented here. Until then `@DriftDatabase()` stayed empty and no schema was recorded, so the first table became v1 and `make migrate` wrote `drift_schema_v1.json` at that point.

## Open questions

- **Web as a system of record.** ADR 0001 already calls the web build "a convenient reader and second terminal." Drift's OPFS path is meaningfully better than IndexedDB-backed sqflite, but the browsers that fall back to `inMemory` do so silently. Whether the web build ever gets write access to a real catalogue is a product decision this ADR does not make - it only makes sure we can see the fallback in the logs.
- **Backup and export.** Unchanged by this decision, and still the first non-catalogue feature worth building. A plain SQLite file is still a plain SQLite file.
- **`shareAcrossIsolates`.** `DriftNativeOptions` can host the database in a named isolate shared across engines. Irrelevant to a single-window desktop app today; relevant if a background export or import isolate ever lands.

## Sources

- [drift on pub.dev](https://pub.dev/packages/drift) · [drift_flutter](https://pub.dev/packages/drift_flutter) · [drift_dev](https://pub.dev/packages/drift_dev) · [sqlite3](https://pub.dev/packages/sqlite3)
- [Drift - Migrations](https://drift.simonbinder.eu/migrations/) · [Step-by-step](https://drift.simonbinder.eu/migrations/step_by_step/) · [Schema exports](https://drift.simonbinder.eu/migrations/exports/) · [Migration tests](https://drift.simonbinder.eu/migrations/tests/) · [Migrator API](https://drift.simonbinder.eu/migrations/api/)
- [Drift - Supported platforms](https://drift.simonbinder.eu/platforms/) · [Web](https://drift.simonbinder.eu/platforms/web/) · [Generation options](https://drift.simonbinder.eu/generation_options/) · [Modular generation](https://drift.simonbinder.eu/generation_options/modular/) · [Streams](https://drift.simonbinder.eu/dart_api/streams/)
- [Upgrading to package:sqlite3 v3](https://github.com/simolus3/sqlite3.dart/blob/main/UPGRADING_TO_V3.md) · [sqlite3 build hook options](https://pub.dev/documentation/sqlite3/latest/topics/hook-topic.html) · [sqlite3_flutter_libs (EOL)](https://pub.dev/packages/sqlite3_flutter_libs)
- [Dart hooks](https://dart.dev/tools/hooks) · [Flutter build hooks & code assets](https://github.com/flutter/flutter/issues/129757)
- [SQLite result and error codes](https://sqlite.org/rescode.html) · [ALTER TABLE - the 12-step procedure](https://www.sqlite.org/lang_altertable.html#otheralter)
