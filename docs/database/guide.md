# Database guide - how to work with the DB in Khulla

Everything you need to add tables, query data, write data, do migrations, and remove things safely.  
This is the **how-to** companion to [overview.md](overview.md), which covers the _what_ and _why_.

---

## Quick reference

| Task                      | Command                                                    |
| ------------------------- | ---------------------------------------------------------- |
| Added/changed a table     | `make migrate` then `make build` then `make db-diagram`    |
| Just changed non-DB code  | `make build`                                               |
| Refresh the visual schema | `make db-diagram`                                          |
| Run tests                 | `make test`                                                |
| Generate code only        | `dart run build_runner build --delete-conflicting-outputs` |

---

## Where do tables live?

> **Rule:** Tables live with the sub-feature that owns them. NOT in `core/`.

```
lib/
├── core/
│   └── database/
│       └── app_database.dart   ← only registers tables, does NOT define them
│
└── features/
    └── catalog/
        └── title/
            └── data/
                └── tables/
                    └── titles.dart   <-- table class goes here
```

`core/` owns the **connection** (how to open the DB).  
Features own the **schema** (what tables exist).

---

## How to add a table - full step-by-step

Let's say you want to add a `Books` table. Here's the full flow:

---

### Step 1 - Create the Table class

```dart
// lib/features/catalog/title/data/tables/titles.dart

import 'package:drift/drift.dart';
import 'package:khulla/core/database/converters/money_converter.dart';

class Titles extends Table {
  // Auto-incrementing primary key
  IntColumn get id => integer().autoIncrement()();

  // Required text, max 500 chars
  TextColumn get title => text().withLength(max: 500)();

  // Unique column - DB will reject duplicates automatically
  TextColumn get isbn => text().withLength(min: 10, max: 13).unique()();

  // Nullable column - author might not be known yet
  TextColumn get author => text().nullable()();

  // Money stored as integer paisa (use MoneyConverter, never store as double!)
  // The generated class will give you `Money finePerDay`, not `int finePerDay`
  IntColumn get finePerDay => integer().map(const MoneyConverter())();

  // DateTime stored as ISO-8601 text (configured in build.yaml)
  DateTimeColumn get addedAt => dateTime().withDefault(currentDateAndTime)();

  // Boolean stored as 0/1
  BoolColumn get isAvailable => boolean().withDefault(const Constant(true))();

  // Foreign key to another table (must have foreign_keys ON - already done in beforeOpen)
  IntColumn get authorId => integer().references(Authors, #id).nullable()();
}
```

**Column types cheat sheet:**

| Dart type   | Column builder                            | Notes                                |
| ----------- | ----------------------------------------- | ------------------------------------ |
| `int`       | `integer()`                               |                                      |
| `String`    | `text()`                                  |                                      |
| `bool`      | `boolean()`                               | stored as 0/1                        |
| `DateTime`  | `dateTime()`                              | stored as ISO-8601 text (our config) |
| `double`    | `real()`                                  | avoid for money!                     |
| `Uint8List` | `blob()`                                  | binary data                          |
| `Money`     | `integer().map(const MoneyConverter())()` | always use this for money            |

**Column modifiers:**

```dart
text().withLength(min: 1, max: 255)()   // min/max length
text().nullable()()                      // makes column nullable
text().unique()()                        // DB-level unique constraint
integer().withDefault(const Constant(0))() // default value
dateTime().withDefault(currentDateAndTime)() // default = now
integer().autoIncrement()()              // primary key (also makes it the PK)
integer().references(OtherTable, #columnName)() // foreign key
```

---

### Step 2 - Register the Table in AppDatabase

Open `lib/core/database/app_database.dart` and add your table:

```dart
// BEFORE:
@DriftDatabase()
class AppDatabase extends _$AppDatabase { ... }

// AFTER:
@DriftDatabase(tables: [Titles])   // ← add your table here
class AppDatabase extends _$AppDatabase { ... }
```

If you have multiple tables:

```dart
@DriftDatabase(tables: [Titles, Authors, Members, Loans, Fines])
class AppDatabase extends _$AppDatabase { ... }
```

---

### Step 3 - Bump the Schema Version

Still in `app_database.dart`, increment `schemaVersion` by **exactly 1**:

```dart
// BEFORE (first table ever):
@override
int get schemaVersion => 1;

// AFTER (adding the Titles table):
@override
int get schemaVersion => 2;
```

> ⚠️ **Always bump by exactly 1.** Never skip. Never go backward.  
> Every integer is a snapshot of a real database somewhere in the world.

---

### Step 4 - Run `make migrate`

```bash
make migrate
# runs: dart run drift_dev make-migrations
```

This does three things automatically:

1. Writes `drift_schemas/drift_schema_v2.json` - a snapshot of what the schema looks like at v2
2. Regenerates `lib/core/database/app_database.steps.dart` - the step-by-step migration file
3. Generates `test/drift/` - auto-generated tests that prove the migration is correct

---

### Step 5 - Fill in the Migration Step

After `make migrate`, open `lib/core/database/app_database.dart`.  
The `_upgradeSchema` method now has a generated `stepByStep` call waiting for you to fill in:

```dart
Future<void> _upgradeSchema(Migrator m, int from, int to) async {
  if (from > to) {
    throw const DatabaseUnavailableException(...);
  }

  // This was generated by make migrate - fill in the callback:
  await stepByStep(
    from1To2: (m, schema) async {
      // Creating a brand new table:
      await m.createTable(schema.titles);

      // Adding a column to an existing table:
      // await m.addColumn(schema.titles, schema.titles.author);

      // Renaming/altering a table (more complex - see the Migration section below):
      // await m.alterTable(TableMigration(schema.titles));
    },
  )(m, from, to);
}
```

> ⚠️ **Critical rule: NEVER use `this` inside a step.**  
> Steps receive their own `schema` snapshot object. Using `this` (the live database)  
> inside a step uses today's schema instead - migrations pass in dev and corrupt real upgrades.
>
> ```dart
> // WRONG - uses live schema
> from1To2: (m, schema) async {
>   await m.createTable(titles);   // `titles` refers to `this.titles`
> }
>
> // CORRECT - uses the snapshot
> from1To2: (m, schema) async {
>   await m.createTable(schema.titles);   // `schema.titles` is the v2 snapshot
> }
> ```

---

### Step 6 - Regenerate Code and Test

```bash
make build    # regenerates app_database.g.dart with TitleData, TitlesCompanion, etc.
make test     # runs the generated migration tests
```

The auto-generated migration test checks that:

- Upgrading from v1 → v2 produces the **same schema** as a fresh v2 install
- This is the thing hand-rolled migration frameworks couldn't do

If the test is red → your migration step has a bug. Fix the step before merging.

---

### Summary: adding a table

```
1. Create Table class          lib/features/<name>/data/tables/<name>.dart
2. Add to @DriftDatabase       lib/core/database/app_database.dart
3. Bump schemaVersion          app_database.dart  (by exactly +1)
4. make migrate                writes schema JSON + steps + tests
5. Fill the migration step     _upgradeSchema → from1To2 callback
6. make build                  regenerates .g.dart
7. make db-diagram              refreshes docs/database/schema.md
8. make test                   migration tests must be green
```

---

## How to access / query data

After `make build`, Drift generates typed classes for your table.  
For a `Titles` table, you get:

- `TitleData` - a row read from the database (immutable)
- `TitlesCompanion` - used for inserts and updates (fields are optional `Value<T>`)
- `db.titles` - the table object used to build queries
- `db.managers.titles` - the newer manager API for simpler queries

---

### Where Queries Live

Queries go in a **local data source** class. Never put SQL in a Cubit or widget.

```
lib/features/catalog/title/data/
├── tables/
│   └── titles.dart                        ← Table definition
├── local_title_data_source.dart           ← interface (abstract)
├── drift_title_data_source.dart           ← Drift implementation
└── mappers/
    └── title_row_mappers.dart             ← TitleData → Title domain model
```

---

### Creating a Data Source

```dart
// lib/features/catalog/title/data/local_title_data_source.dart

abstract interface class LocalTitleDataSource {
  Future<List<Title>> findAll();
  Future<Title?> findById(int id);
  Future<List<Title>> search(String query);
  Future<void> save(Title title);
  Future<void> delete(int id);
  Stream<List<Title>> watchAll(); // reactive stream
}
```

```dart
// lib/features/catalog/title/data/drift_title_data_source.dart

import 'package:injectable/injectable.dart';
import 'package:khulla/core/database/app_database.dart';
import 'package:khulla/core/error/guard.dart';

@LazySingleton(as: LocalTitleDataSource)  // DI: register this as the implementation
class DriftTitleDataSource implements LocalTitleDataSource {
  DriftTitleDataSource(this._db);
  final AppDatabase _db;

  // ...queries below
}
```

---

### Reading Data

Always wrap in `guardDatabase()`. It converts SQLite errors into `AppException`.

```dart
// Select ALL rows
Future<List<TitleData>> findAll() => guardDatabase(
  () => _db.select(_db.titles).get(),
  source: 'DriftTitleDataSource.findAll',
);

// Select ONE row by primary key
Future<TitleData?> findById(int id) => guardDatabase(
  () => (_db.select(_db.titles)
    ..where((t) => t.id.equals(id)))
    .getSingleOrNull(),
  source: 'DriftTitleDataSource.findById',
);

// Filter with WHERE clause
Future<List<TitleData>> findAvailable() => guardDatabase(
  () => (_db.select(_db.titles)
    ..where((t) => t.isAvailable.equals(true)))
    .get(),
  source: 'DriftTitleDataSource.findAvailable',
);

// Order results
Future<List<TitleData>> findAllSorted() => guardDatabase(
  () => (_db.select(_db.titles)
    ..orderBy([(t) => OrderingTerm(expression: t.title)]))
    .get(),
  source: 'DriftTitleDataSource.findAllSorted',
);

// Limit results
Future<List<TitleData>> findRecent(int limit) => guardDatabase(
  () => (_db.select(_db.titles)
    ..orderBy([(t) => OrderingTerm(expression: t.addedAt, mode: OrderingMode.desc)])
    ..limit(limit))
    .get(),
  source: 'DriftTitleDataSource.findRecent',
);

// Search with LIKE
Future<List<TitleData>> search(String query) => guardDatabase(
  () => (_db.select(_db.titles)
    ..where((t) => t.title.like('%$query%') | t.isbn.like('%$query%')))
    .get(),
  source: 'DriftTitleDataSource.search',
);
```

---

### Reactive Streams - `watch()` vs `get()`

`watch()` returns a `Stream` that **automatically re-runs** when the data changes.  
Any write to the `titles` table → the stream emits a new list. No manual refresh needed.

```dart
// Returns a stream that updates whenever titles change
Stream<List<TitleData>> watchAll() => _db.select(_db.titles).watch();

// With filter
Stream<List<TitleData>> watchAvailable() =>
  (_db.select(_db.titles)
    ..where((t) => t.isAvailable.equals(true)))
    .watch();
```

**In the Cubit, subscribe and cancel properly:**

```dart
class TitleCubit extends Cubit<TitleState> {
  TitleCubit(this._dataSource) : super(const TitleState());
  final LocalTitleDataSource _dataSource;

  StreamSubscription<List<Title>>? _subscription;  // keep a reference

  void watchTitles() {
    _subscription?.cancel(); // cancel previous if any
    _subscription = _dataSource.watchAll()
      .map((rows) => rows.map(toDomain).toList())
      .listen(
        (titles) => emit(state.copyWith(status: LoadStatus.loaded, titles: titles, error: null)),
        onError: (Object e) {
          if (e is AppException) emit(state.copyWith(status: LoadStatus.failure, error: e));
        },
      );
  }

  @override
  Future<void> close() {
    _subscription?.cancel(); // MUST cancel on close
    return super.close();
  }
}
```

> ⚠️ **Watch rules:**
>
> - Drift invalidates per **table**, not per row. Any write to `titles` re-runs every watcher of `titles`.
> - Keep watched queries narrow. A watched query that scans 10,000 rows re-runs on every single insert.
> - `customStatement` writes do NOT notify watchers. Call `notifyUpdates({db.titles})` explicitly if you use raw SQL writes.
> - Start with `get()` (one-shot reads). Switch to `watch()` only when a screen genuinely needs to react to another screen's writes.

---

### Writing Data

**Insert:**

```dart
// Insert a new row - throws DuplicateRecordException if ISBN already exists
Future<void> save(TitlesCompanion data) => guardDatabase(
  () => _db.into(_db.titles).insert(data),
  source: 'DriftTitleDataSource.save',
);

// Usage:
await _dataSource.save(TitlesCompanion.insert(
  title: 'The Great Gatsby',
  isbn: '9780743273565',
  finePerDay: const Money(500),  // 5.00 rupees per day (in paisa)
  addedAt: Value(DateTime.now()),
));
```

**Insert or update (upsert):**

```dart
Future<void> upsert(TitlesCompanion data) => guardDatabase(
  () => _db.into(_db.titles).insertOnConflictUpdate(data),
  source: 'DriftTitleDataSource.upsert',
);
```

**Update:**

```dart
// Update specific columns of a specific row
Future<void> markUnavailable(int id) => guardDatabase(
  () => (_db.update(_db.titles)
    ..where((t) => t.id.equals(id)))
    .write(const TitlesCompanion(isAvailable: Value(false))),
  source: 'DriftTitleDataSource.markUnavailable',
);

// Update with Companion (only specified fields are updated)
Future<void> updateTitle(int id, String newTitle) => guardDatabase(
  () => (_db.update(_db.titles)
    ..where((t) => t.id.equals(id)))
    .write(TitlesCompanion(title: Value(newTitle))),
  source: 'DriftTitleDataSource.updateTitle',
);
```

**Delete:**

```dart
// Delete by ID
Future<void> delete(int id) => guardDatabase(
  () => (_db.delete(_db.titles)
    ..where((t) => t.id.equals(id)))
    .go(),
  source: 'DriftTitleDataSource.delete',
);

// Delete all rows (dangerous!)
Future<void> deleteAll() => guardDatabase(
  () => _db.delete(_db.titles).go(),
  source: 'DriftTitleDataSource.deleteAll',
);
```

**Transactions - multiple writes atomically:**

```dart
// Either ALL writes succeed, or NONE do
Future<void> checkOutCopy(int copyId, int memberId) => guardDatabase(
  () => _db.transaction(() async {
    await (_db.update(_db.copies)
      ..where((c) => c.id.equals(copyId)))
      .write(const CopiesCompanion(isCheckedOut: Value(true)));

    await _db.into(_db.loans).insert(LoansCompanion.insert(
      copyId: copyId,
      memberId: memberId,
      loanDate: Value(DateTime.now()),
    ));
  }),
  source: 'DriftTitleDataSource.checkOutCopy',
);
```

---

### Mapping Rows to Domain Models

A `TitleData` (generated DB row) must **never leave the data layer**.  
Map it to a domain `Title` model using mappers.

```dart
// lib/features/catalog/title/data/mappers/title_row_mappers.dart

import 'package:khulla/features/catalog/title/data/tables/titles.dart';
import 'package:khulla/features/catalog/title/domain/models/title.dart';

extension TitleRowMapper on TitleData {
  Title toDomain() => Title(
    id: id,
    name: title,
    isbn: isbn,
    finePerDay: finePerDay,   // already Money, thanks to MoneyConverter
    addedAt: addedAt,
    isAvailable: isAvailable,
  );
}

extension TitleDomainMapper on Title {
  TitlesCompanion toCompanion() => TitlesCompanion(
    id: id != null ? Value(id!) : const Value.absent(),
    title: Value(name),
    isbn: Value(isbn),
    finePerDay: Value(finePerDay),
  );
}
```

Then in your data source:

```dart
Future<List<Title>> findAll() => guardDatabase(
  () => _db.select(_db.titles)
    .get()
    .then((rows) => rows.map((r) => r.toDomain()).toList()),
  source: 'DriftTitleDataSource.findAll',
);
```

---

## How migrations work

Migrations are how you evolve the database schema over time **without losing existing data**.

### The Golden Rules

1. **Migrations are append-only.** A shipped step is frozen. Someone's database was built by running exactly that SQL. Fix a mistake with the _next_ migration - never by editing an old one.
2. **Never touch `this` inside a step.** Use the `schema` snapshot passed to the callback.
3. **Bump `schemaVersion` by exactly +1** per change.
4. **`make migrate` before `make build`.** The schema snapshot must exist before code generation.
5. **Migration tests must be green.** A red migration test means the step is wrong.

---

### What Happens at Different Schema States

| Scenario                              | What happens                                                |
| ------------------------------------- | ----------------------------------------------------------- |
| Fresh install (no DB file exists)     | `onCreate` runs - `m.createAll()` creates all tables        |
| Same version as DB file               | Nothing runs - DB opens normally                            |
| App is newer (v1 → v2)                | `onUpgrade` runs your step-by-step migration                |
| App is OLDER than DB file (downgrade) | **Refuses to open** - throws `DatabaseUnavailableException` |

### Adding a Column (v1 → v2)

```dart
// In your Table class, add the new column:
class Titles extends Table {
  // ... existing columns ...
  TextColumn get subtitle => text().nullable()();  // NEW
}

// Bump schemaVersion to 2, then run make migrate, then fill the step:
from1To2: (m, schema) async {
  await m.addColumn(schema.titles, schema.titles.subtitle);
},
```

### Renaming a Column (NOT directly supported in SQLite)

SQLite doesn't support `ALTER TABLE RENAME COLUMN` before version 3.25.  
Drift's `TableMigration` handles this by recreating the table:

```dart
from2To3: (m, schema) async {
  // Copy data from old column `author` to new column `authorName`
  await m.alterTable(
    TableMigration(
      schema.titles,
      columnTransformer: {
        schema.titles.authorName: schema.titles.author,  // old → new
      },
      newColumns: [schema.titles.authorName],
    ),
  );
},
```

### Adding a Table (v1 → v2)

```dart
from1To2: (m, schema) async {
  await m.createTable(schema.authors);  // creates the Authors table
},
```

### Dropping a Column (v2 → v3)

SQLite doesn't support `DROP COLUMN` on older versions either.  
Use `TableMigration` to recreate without the old column:

```dart
from2To3: (m, schema) async {
  await m.alterTable(
    TableMigration(schema.titles),  // recreates table with current columns only
  );
},
```

---

## How to remove a table or column

### Removing a Column

1. Delete the column from your `Table` class
2. Bump `schemaVersion`
3. `make migrate`
4. Fill the step with `TableMigration` (SQLite won't DROP the column, Drift recreates the table):

```dart
from2To3: (m, schema) async {
  // `schema.titles` now reflects the updated table (without the old column)
  await m.alterTable(TableMigration(schema.titles));
},
```

### Removing a Table

1. Remove the `Table` class from your codebase
2. Remove it from `@DriftDatabase(tables: [...])`
3. Bump `schemaVersion`
4. `make migrate`
5. Fill the step:

```dart
from2To3: (m, schema) async {
  await m.dropTable(schema.oldTable);
  // Note: schema at this version still knows about oldTable
},
```

> ⚠️ **If the table has foreign keys pointing to it**, you must delete all child records first  
> (or set them to null), otherwise the FK constraint will block the deletion.

---

## Joins - querying multiple tables

Drift supports joining tables with typed results:

```dart
// Join titles with authors
Future<List<TitleWithAuthor>> findAllWithAuthor() => guardDatabase(
  () async {
    final query = _db.select(_db.titles).join([
      leftOuterJoin(
        _db.authors,
        _db.authors.id.equalsExp(_db.titles.authorId),
      ),
    ]);

    final rows = await query.get();
    return rows.map((row) {
      final title = row.readTable(_db.titles);
      final author = row.readTableOrNull(_db.authors);
      return TitleWithAuthor(title: title.toDomain(), author: author?.toDomain());
    }).toList();
  },
  source: 'DriftTitleDataSource.findAllWithAuthor',
);
```

---

## Aggregates - COUNT, SUM, etc.

```dart
// Count all titles
Future<int> countTitles() => guardDatabase(
  () async {
    final countExp = _db.titles.id.count();
    final query = _db.selectOnly(_db.titles)..addColumns([countExp]);
    final result = await query.getSingle();
    return result.read(countExp) ?? 0;
  },
  source: 'DriftTitleDataSource.countTitles',
);

// Sum of all fines (returns Money)
Future<Money> totalFinesOwed() => guardDatabase(
  () async {
    final sumExp = _db.fines.amount.sum();
    final query = _db.selectOnly(_db.fines)..addColumns([sumExp]);
    final result = await query.getSingle();
    return Money(result.read(sumExp) ?? 0);
  },
  source: 'DriftFineDataSource.totalFinesOwed',
);
```

---

## Testing with an in-memory database

For tests, use `AppDatabase.connect()` with an in-memory database.  
It wipes itself after each test - no cleanup needed.

```dart
// test/features/catalog/title/data/drift_title_data_source_test.dart

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:khulla/core/database/app_database.dart';

void main() {
  late AppDatabase db;
  late DriftTitleDataSource dataSource;

  setUp(() {
    // NativeDatabase.memory() = in-memory SQLite, wiped after each test
    db = AppDatabase.connect(NativeDatabase.memory());
    dataSource = DriftTitleDataSource(db);
  });

  tearDown(() => db.close());

  test('findAll returns empty list when no titles exist', () async {
    final result = await dataSource.findAll();
    expect(result, isEmpty);
  });

  test('save then findById returns the title', () async {
    await dataSource.save(TitlesCompanion.insert(
      title: 'Test Book',
      isbn: '1234567890',
      finePerDay: const Money(100),
    ));

    final result = await dataSource.findById(1);
    expect(result?.name, 'Test Book');
  });

  test('duplicate ISBN throws DuplicateRecordException', () async {
    final companion = TitlesCompanion.insert(
      title: 'Book One',
      isbn: '1234567890',
      finePerDay: const Money(100),
    );
    await dataSource.save(companion);

    expect(
      () => dataSource.save(companion),
      throwsA(isA<DuplicateRecordException>()),
    );
  });
}
```

---

## Error handling

All database errors are converted to `AppException` by `guardDatabase`. Cubits catch these:

```dart
// In a Cubit - reads swallow the error into state:
Future<void> loadTitles() async {
  emit(state.copyWith(status: LoadStatus.loading, error: null));
  try {
    final titles = await _dataSource.findAll();
    emit(state.copyWith(status: LoadStatus.loaded, titles: titles));
  } on AppException catch (e) {
    emit(state.copyWith(status: LoadStatus.failure, error: e));
    // DO NOT rethrow for reads - the screen watches state.error
  }
}

// In a Cubit - writes rethrow so the gesture can show a toast:
Future<void> saveTitle(Title title) async {
  try {
    await _dataSource.save(title.toCompanion());
    emit(state.copyWith(status: LoadStatus.loaded));
  } on AppException catch (e) {
    emit(state.copyWith(status: LoadStatus.failure, error: e));
    rethrow;  // ← rethrow for writes so the UI can show a toast
  }
}
```

**The AppException types you'll encounter:**

| Exception                      | When you see it                             | Example                           |
| ------------------------------ | ------------------------------------------- | --------------------------------- |
| `DuplicateRecordException`     | Unique/primary key violation                | Duplicate ISBN                    |
| `ConflictException`            | Foreign key violation                       | Deleting author who has titles    |
| `InvalidInputException`        | NOT NULL or CHECK constraint                | Required field left empty         |
| `DatabaseUnavailableException` | DB locked, corrupted, or newer              | App on a network share            |
| `NotFoundException`            | Row doesn't exist (you throw this manually) | `getSingleOrNull()` returned null |
| `DatabaseFailureException`     | Unclassified SQLite error                   | Rare edge cases                   |
| `UnknownException`             | Anything else                               | Should not happen in normal use   |

---

## Checklist - definition of done for DB changes

Every schema change must complete all of these before it's considered done:

- [ ] Table class created or updated in the right sub-feature folder
- [ ] Table registered in `@DriftDatabase(tables: [...])`
- [ ] `schemaVersion` bumped by exactly 1
- [ ] `make migrate` run - `drift_schemas/` and `test/drift/` updated
- [ ] Migration step filled in (never using `this`)
- [ ] `make build` run - `.g.dart` files regenerated
- [ ] `make db-diagram` run - `docs/database/schema.md` refreshed
- [ ] `make test` is green - migration tests pass
- [ ] Data source reads/writes wrapped in `guardDatabase`
- [ ] Domain mapper created (`toDomain()`, `toCompanion()`)
- [ ] `drift_schemas/drift_schema_vN.json` committed alongside code changes

---

## 💡 Tips & Gotchas

**1. `Value<T>` vs `const Value.absent()` in Companions**

When writing to the DB with a Companion:

- `Value(x)` - include this field in the INSERT/UPDATE
- `const Value.absent()` - skip this field (use DB default / don't update it)

```dart
// Update only the title, leave everything else untouched:
TitlesCompanion(title: Value('New Title'))
//               isbn: absent (not updated)
//               finePerDay: absent (not updated)
```

**2. Never interpolate `Money` directly**

```dart
// ❌ WRONG - prints raw paisa: "Rs 4500"
Text('Amount: $finePerDay');

// ✅ CORRECT - prints formatted: "Rs 45.00"
Text('Amount: ${finePerDay.display()}');
```

**3. `customStatement` writes don't notify watchers**

```dart
await _db.customStatement('DELETE FROM titles WHERE is_available = 0');
// Streams watching titles won't update!

// Fix - notify manually:
await _db.customStatement('DELETE FROM titles WHERE is_available = 0');
_db.notifyUpdates({TableUpdate.onTable(_db.titles, kind: UpdateKind.delete)});
```

**4. Foreign keys are ON - deletions will fail if records are referenced**

```dart
// Trying to delete an author who has titles will throw ConflictException
// Either delete the titles first, or set authorId = null on them
await _db.transaction(() async {
  await (_db.update(_db.titles)
    ..where((t) => t.authorId.equals(authorId)))
    .write(const TitlesCompanion(authorId: Value(null)));

  await (_db.delete(_db.authors)
    ..where((a) => a.id.equals(authorId)))
    .go();
});
```

**5. DateTime is stored as ISO-8601 text (NOT unix timestamp)**

This is configured in `build.yaml`. It means:

- Human-readable in the SQLite file
- Always preserves timezone info
- Changing this setting after data exists = migration over every date column

**6. Don't put `db.managers` queries in production yet for complex joins**

The `managers` API is great for simple CRUD. For complex joins, use the classic query API (`.select().join()`) - it's more explicit and easier to debug.
