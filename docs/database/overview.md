# How the database works in Khulla

A walkthrough of every database file - what it does, why it is there, and how it all connects. For the day-to-day workflow (adding tables, writing queries, running migrations), see [guide.md](guide.md); for the visual schema, see [schema.md](schema.md).

---

## Tech stack

The project uses **Drift**, a type-safe SQLite layer for Dart. It:

- Auto-generates Dart classes from your table definitions
- Runs SQLite on a **background isolate** (on native) so DB queries never freeze the UI
- Runs SQLite compiled to **WebAssembly** (on web) stored in the browser

The database is **fully local** - no backend server. Everything lives on the device. That's why it's called a "catalogue": it's a local library catalogue.

---

## The big picture

```
app startup
    │
    ▼
bootstrap()                    ← lib/bootstrap.dart
    │
    ├─ configureDependencies() ← registers AppConfig + all @injectable classes
    │       │
    │       └─ AppDatabase is created (lazily) from AppConfig
    │
    └─ AppDatabase.warmUp()    ← forces the DB file to open NOW
            │
            ├─ opens the .sqlite file on disk
            ├─ runs migrations (onCreate / onUpgrade)
            ├─ sets PRAGMA foreign_keys = ON
            │
            └─ App starts, all widgets can now use the DB
```

When a feature needs data:

```
Widget / Cubit
    │
    └─ calls a Data Source (e.g. TitleLocalDataSource)
            │
            └─ calls guardDatabase(() => db.select(db.titles).get())
                    │
                    ├─ runs the SQL on the background isolate
                    └─ returns typed Dart objects OR throws AppException
```

---

## File-by-file breakdown

---

### 1. `lib/core/config/app_config.dart` - "Which database file do we use?"

```dart
class AppConfig {
  const AppConfig({
    required this.flavor,
    required this.databaseName,   // <-- this is the key thing
    required this.windowTitle,
  });

  factory AppConfig.dev() => const AppConfig(
    flavor: Flavor.dev,
    databaseName: 'khulla_dev',   // dev build → opens "khulla_dev.sqlite"
    windowTitle: 'Khulla Digital Library (dev)',
  );

  factory AppConfig.prod() => const AppConfig(
    flavor: Flavor.prod,
    databaseName: 'khulla',       // prod build → opens "khulla.sqlite"
    windowTitle: 'Khulla Digital Library',
  );
}
```

**Why two database names?**
So when you're developing and testing, you never accidentally touch the real library's production data. `dev` build → dev DB. `prod` build → prod DB. They're two completely separate SQLite files.

The `databaseName` flows all the way down into where the file is created on disk.

---

### 2. `lib/core/database/database_platform.dart` - "Choose the right platform implementation"

```dart
export 'database_platform_web.dart'
    if (dart.library.io) 'database_platform_io.dart';
```

This is just a **conditional export**. Dart sees this at compile time and picks the right file:

- On **Android / iOS / Desktop** → uses `database_platform_io.dart`
- On **Web** → uses `database_platform_web.dart`

That's it. This is the only place in the whole data layer that branches on platform. No `if (kIsWeb)` anywhere else.

---

### 3. `lib/core/database/database_platform_io.dart` - "Native: where is the file? How is it configured?"

```dart
// Resolves the absolute path to the .sqlite file on disk
Future<String> resolveDatabasePath(String name) async {
  final directory = await getApplicationSupportDirectory();
  // e.g. /data/user/0/com.khulladigitallibrary.app/files/

  if (!directory.existsSync()) {
    await directory.create(recursive: true);
  }

  return p.join(directory.path, '$name.sqlite');
  // final path = "/data/user/.../files/khulla_dev.sqlite"
}
```

**Why Application Support and not Documents?**
Application Support is where apps store their own managed data - the user isn't meant to browse it. Documents is what shows up in Files/Finder. A library catalogue isn't something the librarian should manually move around.

```dart
// Runs on every new SQLite connection, inside the background isolate
void configureNativeConnection(CommonDatabase database) {
  try {
    database.execute('PRAGMA journal_mode = WAL');
    // WAL = Write-Ahead Logging
    // Allows READS and WRITES to happen at the same time.
    // e.g. exporting catalogue while a checkout is happening.
  } on SqliteException catch (error) {
    // If the filesystem doesn't support WAL (e.g. a network share),
    // just log a warning and continue - don't crash.
    AppLogger.warn('Could not enable write-ahead logging...');
  }
}
```

**What is WAL?** Without WAL, a write locks the entire file - nobody can read while someone is writing. With WAL, reads and writes happen simultaneously. Crucial for a library app that might be exporting a catalogue while checking out a book.

---

### 4. `lib/core/database/database_platform_web.dart` - "Web: stubs"

```dart
// On web there's no file system, so this throws if ever called
Future<String> resolveDatabasePath(String name) {
  throw UnsupportedError(
    'The web build stores the catalogue in the browser, not at a path.',
  );
}

// WAL doesn't exist in the browser's WASM virtual FS, so this does nothing
void configureNativeConnection(CommonDatabase database) {}
```

On web, Drift handles storage via the browser (OPFS or IndexedDB). No file path needed.

---

### 5. `lib/core/database/connection.dart` - "Build the actual database connection"

This is where all the pieces from the platform files come together into a real `DatabaseConnection` object.

```dart
DatabaseConnection openDatabaseConnection(AppConfig config) => driftDatabase(
  name: config.databaseName,   // e.g. 'khulla_dev'

  native: DriftNativeOptions(
    // On native: resolve the file path using our IO implementation
    databasePath: () => resolveDatabasePath(config.databaseName),
    // Run WAL pragma + any setup on the raw connection
    setup: configureNativeConnection,
  ),

  web: DriftWebOptions(
    // On web: load the SQLite WebAssembly binary
    sqlite3Wasm: Uri.parse('sqlite3.wasm'),
    // Load the Drift background worker script
    driftWorker: Uri.parse('drift_worker.js'),
    // Callback to log which storage the browser gave us
    onResult: _reportWebStorage,
  ),
);
```

**Why is this lazy?** The connection is _described_ here but nothing actually opens. The file isn't touched until the first SQL statement runs. That's intentional - `bootstrap` forces the open with `warmUp()` so failures happen at a predictable time (startup) not mid-use.

```dart
void _reportWebStorage(WasmDatabaseResult result) {
  if (result.missingFeatures.isEmpty) {
    AppLogger.info('Web storage: ${result.chosenImplementation}');
    return;
  }

  // IMPORTANT:
  // If the browser gives nothing persistent, Drift silently falls back to
  // IN-MEMORY storage. A librarian would enter a full day of checkouts and
  // lose everything on page refresh, with zero errors shown.
  // Logging is the minimum safeguard; a production web build should show
  // this on screen.
  AppLogger.warn(
    'Web storage fell back to ${result.chosenImplementation} because this '
    'browser is missing ${result.missingFeatures}.',
  );
}
```

---

### 6. `lib/core/database/app_database.dart` - "The main database class"

This is the heart of it all. Let's go line by line.

```dart
@lazySingleton          // GetIt creates exactly one instance, on first use
@DriftDatabase(         // Every table the app owns, registered here
  tables: [
    LibrarySettings, Staff, StaffRecoveryCodes, LoanRules,
    TitleFormats, MemberTypes, Titles, Copies,
    Members, Loans, Fines, Reservations,
  ],
  include: {
    // FTS5 search indexes - virtual tables can only be declared in SQL.
    'package:khulla/features/catalog/title/data/tables/titles_fts.drift',
    'package:khulla/features/members/data/tables/members_fts.drift',
  },
)
class AppDatabase extends _$AppDatabase {

  // Normal constructor used in production.
  // Takes AppConfig, builds connection, passes it to Drift's generated base class.
  AppDatabase(AppConfig config) : super(openDatabaseConnection(config));

  // Test constructor: lets tests inject a custom executor.
  // Typically an in-memory database that wipes itself after each test.
  @visibleForTesting
  AppDatabase.connect(super.e);
```

```dart
  // Bumped by 1 for every schema change (table added, column added, etc.).
  // Currently at 13 - drift_schemas/ records what each version looked like.
  @override
  int get schemaVersion => 13;
```

```dart
  @override
  MigrationStrategy get migration => MigrationStrategy(

    // Called the VERY FIRST TIME the app runs (database file doesn't exist yet)
    onCreate: _createSchema,

    // Called whenever schemaVersion increases (app update with DB changes)
    onUpgrade: _upgradeSchema,

    // Called EVERY TIME the database opens, before any query runs
    beforeOpen: (_) async {
      // SQLite foreign keys are OFF by default - always, on every connection.
      // Without this: deleting a member with active loans would silently
      // orphan those loan records instead of throwing an error.
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
```

```dart
  // Forces the lazy connection to actually open the file RIGHT NOW.
  // bootstrap() calls this so that if the file is locked, corrupted, or
  // from a newer build - we find out BEFORE the first screen renders,
  // not when a librarian tries to check out a book.
  Future<void> warmUp() => customSelect('SELECT 1').get();
  // "SELECT 1" is the simplest possible query - it just wakes up the connection.
```

```dart
  // GetIt (the DI container) calls this automatically when the app closes.
  @disposeMethod
  Future<void> dispose() => close();
```

```dart
  // First-time setup: creates all tables
  Future<void> _createSchema(Migrator m) async {
    AppLogger.info('Creating catalogue schema v$schemaVersion');
    await m.createAll(); // runs CREATE TABLE for every table in @DriftDatabase
  }
```

```dart
  Future<void> _upgradeSchema(Migrator m, int from, int to) async {
    // Drift calls this even for DOWNGRADES (from > to).
    // e.g. user had v2, installs an older v1 build.
    if (from > to) {
      // REFUSE TO OPEN instead of wiping data.
      // A library's catalogue may be irreplaceable.
      // Let the operator reinstall the newer build or restore a backup.
      AppLogger.error(
        'Schema v$from is newer than this build expects (v$to). Refusing.',
        fatal: true,
      );
      throw const DatabaseUnavailableException(
        'This library file was created by a newer version of Khulla Digital Library.',
      );
    }

    // One fromNToM: step per shipped version bump - see app_database.dart
    // for the full list, and guide.md for how to add the next one.
    // await stepByStep(from1To2: (m, schema) async { ... })(m, from, to);
    //
    // Steps must NEVER reference `this` (the live schema).
    // They must only use the snapshot object passed to them.
    // Referencing `this` inside a step is how migrations pass in dev
    // and silently corrupt a real upgrade.
  }
}
```

---

### 7. `lib/core/database/app_database.g.dart` - "Auto-generated code"

**Never edit this file manually.** It's generated by running `dart run build_runner build`.

```dart
// GENERATED CODE - DO NOT MODIFY BY HAND
abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);

  // This manager gives you type-safe query builders for every table,
  // e.g. db.managers.titles.filter(...).get()
  $AppDatabaseManager get managers => $AppDatabaseManager(this);

  // Every registered table and index, generated from @DriftDatabase above.
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [ ... ];

  @override
  DriftDatabaseOptions get options =>
      const DriftDatabaseOptions(storeDateTimeAsText: true);
      // DateTime values are stored as ISO 8601 text strings, not Unix timestamps.
      // Makes them human-readable directly in the SQLite file.
}
```

Each registered table grows this file with a `$TitlesTable` column class, a
`TitleData` row class, and query helpers on `$AppDatabaseManager`.

---

### 8. `lib/core/database/converters/money_converter.dart` - "How money is stored"

```dart
class MoneyConverter extends TypeConverter<Money, int> {
  const MoneyConverter();

  // Reading FROM the database:
  // SQLite gives an integer (e.g. 4500 paisa) → wrap it as Money(4500)
  @override
  Money fromSql(int fromDb) => Money(fromDb);

  // Writing TO the database:
  // Money object → unwrap to raw integer (e.g. Money(4500) → 4500)
  @override
  int toSql(Money value) => value.minorUnits;
}
```

**How you use it on a table column:**

```dart
class Fines extends Table {
  IntColumn get amount => integer().map(const MoneyConverter())();
  //                                 ^^^^^^^^^^^^^^^^^^^^^^^^^^^
  //                                 The column stores an int in SQLite,
  //                                 but Drift hands you a Money object.
  //                                 The converter does the conversion automatically.
}
```

**Why store as integer paisa instead of decimal rupees?**
Floating point math is imprecise. `2.99 + 1.01` might give `3.9999999999` in floating point. Storing as integer paisa (299 + 101 = 400 = Rs 4.00) is always exact.

---

### 9. `lib/core/error/guard.dart` - "Safe database calls"

Every data source method wraps itself in `guardDatabase()`:

```dart
// Example usage in a data source:
Future<List<Title>> findAll() => guardDatabase(
  () => _db.select(_db.titles).get().then(toDomain),
  source: 'TitleLocalDataSource.findAll',
);

Future<void> save(TitlesCompanion data) => guardDatabase(
  () => _db.into(_db.titles).insert(data),
  source: 'TitleLocalDataSource.save',
);
```

Internally, `guardDatabase` catches ALL possible errors and converts them:

```dart
Future<T> guardDatabase<T>(Future<T> Function() action, {String? source}) async {
  try {
    return await action();

  } on AppException {
    rethrow; // Already classified - pass it through unchanged

  } on DriftRemoteException catch (error, stackTrace) {
    // On native, the DB runs on a background ISOLATE.
    // Errors cross the isolate boundary wrapped in DriftRemoteException.
    // Must unwrap first before classifying.
    throw _classify(error.remoteCause, source: source, stackTrace: stackTrace);

  } on Object catch (error, stackTrace) {
    throw _classify(error, source: source, stackTrace: stackTrace);
  }
}
```

The `_classify()` function maps raw SQLite errors to friendly `AppException` types:

| SQLite Error                    | AppException                   | What it means                            |
| ------------------------------- | ------------------------------ | ---------------------------------------- |
| `SQLITE_CONSTRAINT_UNIQUE`      | `DuplicateRecordException`     | "That ISBN already exists"               |
| `SQLITE_CONSTRAINT_FOREIGNKEY`  | `ConflictException`            | "Record still referenced"                |
| `SQLITE_CONSTRAINT_NOTNULL`     | `InvalidInputException`        | "Missing required field"                 |
| `SQLITE_BUSY` / `SQLITE_LOCKED` | `DatabaseUnavailableException` | "DB in use by another process"           |
| `SQLITE_CORRUPT`                | `DatabaseUnavailableException` | "Database file is damaged"               |
| `InvalidDataException` (Drift)  | `InvalidInputException`        | "Row rejected before hitting SQLite"     |
| Unrecognized driver code        | `DatabaseFailureException`     | "Something went wrong with the database" |
| Non-database failure            | `UnknownException`             | "Something went wrong"                   |

**Why does this matter?**
Cubits (your BLoC layer) only ever need to catch `AppException`. They never need to know about SQLite error codes or isolate boundaries. Clean separation of concerns.

---

### 10. `lib/bootstrap.dart` - "The full startup sequence"

```dart
Future<void> bootstrap(AppConfig config) async {
  WidgetsFlutterBinding.ensureInitialized(); // Flutter engine ready

  AppLogger.verbose = !config.isProduction;  // verbose logs in dev only

  // Install global error handlers (FlutterError + PlatformDispatcher)
  FlutterError.onError = ...
  PlatformDispatcher.instance.onError = ...

  Bloc.observer = const AppBlocObserver();

  // Size/show desktop window before first frame
  await configureAppWindow(config);

  // Wire up all dependency injection bindings
  // AppDatabase is REGISTERED here but NOT created yet (@lazySingleton)
  await configureDependencies(config);

  await _runApp();
}

Future<void> _runApp() async {
  try {
    // THIS is where AppDatabase is actually created for the first time.
    // getIt<AppDatabase>() triggers the lazy singleton creation,
    // which calls openDatabaseConnection(config) and opens the file.
    // warmUp() forces migrations to run right now.
    await guardDatabase(
      getIt<AppDatabase>().warmUp,
      source: 'bootstrap',
    );
  } on AppException catch (error, stackTrace) {
    // If anything fails (locked file, corrupted DB, newer schema),
    // show a readable failure screen instead of crashing.
    runApp(StartupFailureApp(
      error: error,
      onRetry: () => unawaited(_runApp()), // Has a Retry button!
    ));
    return;
  }

  runApp(const App()); // All good, start the real app
}
```

---

## How dependency injection connects it all

```dart
// injection.dart
final GetIt getIt = GetIt.instance;

Future<void> configureDependencies(AppConfig config) async {
  // Register AppConfig FIRST because AppDatabase depends on it
  getIt.registerSingleton<AppConfig>(config);

  // Let injectable's generated code register everything else
  await getIt.init();
}
```

```dart
// app_database.dart
@lazySingleton  // ← "create once, on first use"
class AppDatabase extends _$AppDatabase {
  AppDatabase(AppConfig config) : super(openDatabaseConnection(config));
  //          ^^^^^^^^^^^
  //          Injectable sees this parameter and automatically
  //          pulls AppConfig from GetIt when creating AppDatabase.
  //          You never call `AppDatabase(config)` manually.
}
```

**How to access the database anywhere:**

```dart
// Option 1: via GetIt (for top-level use)
final db = getIt<AppDatabase>();

// Option 2: constructor injection (preferred, testable)
@injectable
class LocalTitleDataSource implements TitleLocalDataSource {
  LocalTitleDataSource(this._db); // Injectable automatically passes AppDatabase
  final AppDatabase _db;

  Future<List<TitleData>> findAll() => guardDatabase(
    () => _db.select(_db.titles).get(),
    source: 'LocalTitleDataSource.findAll',
  );
}
```

---

## How to add a table

Tables live with the sub-feature that owns them - for example
`features/catalog/title/data/tables/titles.dart` - and are registered in
`@DriftDatabase(tables: [...])` in `app_database.dart`. The full workflow
(defining the table, bumping `schemaVersion`, `make migrate`, filling in the
step, `make build`, `make db-diagram`) is in [guide.md](guide.md).

---

## Architecture diagram

```
AppConfig (flavor, databaseName)
    │
    ▼
openDatabaseConnection()          ← lib/core/database/connection.dart
    │
    ├── native → resolveDatabasePath() + configureNativeConnection()
    │            lib/core/database/database_platform_io.dart
    │            File: /app-support/khulla_dev.sqlite
    │            WAL mode: ON
    │
    └── web    → sqlite3.wasm + drift_worker.js
                 lib/core/database/database_platform_web.dart
                 Storage: OPFS or IndexedDB
    │
    ▼
AppDatabase (@lazySingleton)      ← lib/core/database/app_database.dart
    │
    ├── schemaVersion = 13
    ├── onCreate  → m.createAll()
    ├── onUpgrade → stepByStep migrations (refuse downgrades)
    ├── beforeOpen → PRAGMA foreign_keys = ON
    └── warmUp()  → called by bootstrap before first frame
    │
    ▼
guardDatabase()                   ← lib/core/error/guard.dart
    │
    └── wraps every DB call
        converts SqliteException / DriftRemoteException → AppException
    │
    ▼
Feature Data Sources
    └── use db.select(db.titles) / db.managers.titles / db.into(db.titles)
```

---

## Current schema

The visual schema lives in [`schema.md`](schema.md) - a Mermaid ER diagram
generated from the latest drift snapshot. Regenerate it with
`make db-diagram` after `make migrate` / `make build`.

It currently covers twelve tables plus two FTS5 search indexes at
`schemaVersion` 13: `library_settings`, `loan_rules`, `staff`,
`staff_recovery_codes`, `title_formats`, `titles`, `copies`, `member_types`,
`members`, `loans`, `fines` and `reservations`, with `titles_fts` and
`members_fts` kept in step by triggers.
