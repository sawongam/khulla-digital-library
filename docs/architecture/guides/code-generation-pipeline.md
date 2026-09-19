# ADR 0030 - Code generation pipeline

**Status:** Accepted · **Date:** 2026-09-03

## Context

Four distinct code generators run against this codebase:

- **`freezed`** - generates `copyWith`, `==`, `hashCode`, `toString`, and the private constructor wiring for `@freezed` state and model classes.
- **`injectable`** - generates the `getIt` registration calls (`injection.config.dart`) from `@injectable` and `@lazySingleton` annotations.
- **`drift_dev`** - generates typed query classes, table companions, and the `_$AppDatabase` base class from drift `Table` declarations; also runs `make-migrations` to generate step-by-step migration code and migration tests.
- **`flutter_gen`** - generates the `Assets` class from the `flutter.assets` entry in `pubspec.yaml`.

Each generator reads source files and writes output files, typically `*.g.dart` part files or standalone libraries. They do not know about each other. The build system (`build_runner`) coordinates them.

Without deliberate rules about when to run codegen and what to commit, a multi-contributor project will have:

- Stale generated files that diverge from the source that generated them.
- Merge conflicts in generated files that no human should be editing.
- CI failures that are "works on my machine" because one developer ran `make build` and another did not.
- Confusion about which generated files are "source" (record of shipped schema) vs "derived" (can be regenerated from source).

## Decision

Generated files are **not committed**, with two explicit exceptions. `make build` regenerates everything. CI runs `make build` before `make analyze` so a stale generated file fails the build rather than reaching a reviewer.

### What is generated and not committed

| Generator            | Output                              | Committed? |
| -------------------- | ----------------------------------- | ---------- |
| `freezed`            | `*.freezed.dart`                    | No         |
| `injectable`         | `lib/core/di/injection.config.dart` | No         |
| `drift_dev` (schema) | `*.g.dart` part files               | No         |
| `flutter_gen`        | `lib/gen/assets.gen.dart`           | No         |
| `flutter gen-l10n`   | `lib/l10n/gen/`                     | No         |

None of these files should ever be hand-edited. If the content of a generated file looks wrong, the fix is in the source it was generated from.

### The two committed exceptions

| Generator                   | Output                               | Committed? | Why                                                                                                |
| --------------------------- | ------------------------------------ | ---------- | -------------------------------------------------------------------------------------------------- |
| `drift_dev make-migrations` | `drift_schemas/drift_schema_vN.json` | **Yes**    | The record of each shipped schema version; without it `make-migrations` cannot detect what changed |
| `drift_dev make-migrations` | `app_database.steps.dart`            | **Yes**    | The step-by-step migration code; hand-edited to fill in `Migrator` calls after generation          |
| `drift_dev make-migrations` | `test/drift/` migration tests        | **Yes**    | Proves the v1→vN upgrade path matches a clean vN install; red test = migration is broken           |

These are committed because they are **records and contracts**, not derived output. A `drift_schema_v3.json` cannot be regenerated from today's source - it records what the schema looked like when v3 shipped. Deleting it breaks the append-only migration guarantee. `app_database.steps.dart` is partially hand-edited (the `Migrator` calls inside each step) and must be committed for those edits to survive.

### Two generators writing to the same output slot

`build_runner` enforces that only one builder can write a given file. `freezed` and `drift_dev` both write `*.g.dart` part files. Two builders cannot claim the same `part of` file.

The rule that prevents a collision: **table files and database files carry no `@freezed` or `@JsonSerializable` annotations, and domain model files carry no drift table declarations.** Tables are schema; domain models are `@freezed`. The mapper files (`<name>_row_mappers.dart`) bridge them with plain extension methods, carrying neither annotation. As long as this boundary holds, there is no file that both `freezed` and `drift_dev` need to write.

`injectable` writes a standalone file (`injection.config.dart`), not a part file, so it never conflicts with either.

### `build.yaml`

`build.yaml` configures the generators. The drift-specific options are required:

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

`store_date_time_values_as_text: true` stores `DateTime` as ISO-8601 strings with timezone offsets rather than unix timestamps. This must be set before the first migration exists - changing it after requires migrating every date column. `named_parameters: true` generates `namedVariables` for queries, which gives clearer SQL in logs.

### `make build` vs `make migrate`

Two commands interact with code generation:

**`make build`** - runs `build_runner build --delete-conflicting-outputs`. Regenerates all `*.freezed.dart`, `*.g.dart`, `injection.config.dart`, and `assets.gen.dart`. Run after any change to a `@freezed` class, an `@injectable` annotation, a drift `Table` class, or `pubspec.yaml`'s asset list.

**`make migrate`** - runs `drift_dev make-migrations`. Writes a new `drift_schema_vN.json`, regenerates `app_database.steps.dart`, and generates a migration test under `test/drift/`. Run only after changing a `Table` class and bumping `schemaVersion`. Always run `make migrate` before `make build` on a schema change - `make build` generates the query code from the current schema, and it must see the updated schema.

The order matters:

```
Schema change:
  1. Edit the Table class
  2. Bump schemaVersion
  3. make migrate          ← writes the schema record and step stub
  4. Fill in the migration step (Migrator calls)
  5. make build            ← generates query code from the updated schema
  6. make test             ← migration test must be green

Everything else:
  1. Edit source
  2. make build
  3. make check
```

### `make clean`

`make clean` deletes `.dart_tool/build`. Use when `build_runner` fails with a stale cache after a package version bump or a file rename that left an orphaned output. It is the nuclear option - it forces a full regeneration, which is slower but reliable.

### Generated files and merge conflicts

Because generated files are not committed, they produce no merge conflicts. A branch that changes a `@freezed` state and a branch that adds an `@injectable` cubit both leave `*.freezed.dart` and `injection.config.dart` out of their diffs. The only merge conflict possible in the generated pipeline is in `app_database.steps.dart` (committed, partially hand-edited) - specifically in the step-by-step file if two branches each added a migration step. The conflict is in the step file, not in the schema JSONs; each branch has its own schema JSON at a different version number, so both survive.

### CI enforcement

CI runs in order:

```sh
dart run melos bootstrap
make build
make localize
make analyze       # --fatal-infos: an info is a failure
make test
```

`make build` before `make analyze` ensures the analyzer sees fresh generated files. A source change that breaks code generation fails at `make build` with a clear error, not at `make analyze` with a confusing "class not found" message.

## Consequences

**What this buys**

- No generated files in git diffs. Reviews show only the source change; the consequence for generated code is implied.
- No merge conflicts in generated files. Two branches that each change a state class or add a cubit merge cleanly; each developer runs `make build` after pulling.
- Stale generated files fail loudly. A developer who forgets `make build` and pushes will have CI fail at `make analyze` with an "undefined method" error pointing directly to the stale state.
- The two-generator conflict (freezed + drift_dev) is prevented by the table/domain separation rule, which is independently motivated by the architecture - this is not an extra constraint added for codegen's sake.

**What this costs**

- `make build` is required on every fresh clone. This is documented everywhere but is still the most common contributor mistake.
- The distinction between "generated, not committed" and "generated but committed" (drift schema files) is non-obvious. A contributor who adds `*.steps.dart` to `.gitignore` destroys the migration record. This guide and ADR 0002 name the distinction explicitly.
- `build_runner` is slow on a cold cache. On a large codebase, `make build` can take 30–60 seconds. `make clean` followed by `make build` is slower still. Modular drift generation (which writes `.drift.dart` libraries instead of part files) can help if build times become a bottleneck - not worth it yet.
- `flutter gen-l10n` is separate from `build_runner`. Forgetting `make localize` after an ARB change leaves the localization class stale. It is a fast command (< 1 second) but a separate step contributors must learn.

## Revisiting

The trigger to consolidate `make build` and `make localize` into a single command is the moment they stop needing to be separate - either `flutter gen-l10n` becomes a `build_runner` builder (it has been requested but is not on the Flutter roadmap), or the cost of running both together on every change is low enough that the distinction stops mattering. Until then they stay separate because localization is fast and frequent, while full codegen is slower and needed for fewer changes.
