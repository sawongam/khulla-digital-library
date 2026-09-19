# ADR 0015 - Melos monorepo structure

**Status:** Accepted · **Date:** 2026-09-03

## Context

Khulla is one app and one design-system package today. The app imports `package:khulla_ui/khulla_ui.dart`; the design system knows nothing about the app. Without a workspace tool, `pub get` in the app resolves `khulla_ui` from `path: packages/khulla_ui` in `pubspec.yaml`. That works for a single developer running one terminal. It breaks in several ways as the project grows:

- **Commands run from the root do not cross package boundaries.** `dart format .` from the repo root formats files in `lib/` but ignores `packages/khulla_ui/lib/`. `dart analyze` from the root may or may not pick up `khulla_ui`'s analysis options depending on what it finds first. The result is a repository where "I ran the checks" means "I ran them on the app, maybe."
- **Bootstrapping is manual and error-prone.** A fresh clone needs `flutter pub get` in the root _and_ `flutter pub get` in `packages/khulla_ui`. Missing the second step produces import errors that look like the design system is broken.
- **Scripts that should run across all packages need manual repetition.** `make check` would have to be written as two separate commands, one per package. Adding a third package means updating the Makefile in a non-obvious place.

Melos solves all three: it defines the workspace in one file, `melos bootstrap` runs `pub get` across every package and links local path dependencies, and `melos exec` runs any command in every package that matches a filter. The Makefile delegates to `melos exec`; adding a package to `melos.yaml` is the only step required to include it in every workspace command.

## Decision

Use **Melos** as the workspace manager. The workspace is defined in `melos.yaml` at the repository root. Every package (current: `.` and `packages/khulla_ui`) is a Melos package. Workspace-wide commands are defined in `melos.yaml` and exposed through the `Makefile`.

### Workspace layout

```
khulla-digital-library/
├── melos.yaml               # workspace definition
├── Makefile                 # human-facing commands, delegates to melos
├── pubspec.yaml             # the app
├── lib/
├── packages/
│   └── khulla_ui/
│       ├── pubspec.yaml     # the design system
│       └── lib/
└── …
```

`melos.yaml`:

```yaml
name: khulla_workspace

packages:
  - .
  - packages/**

scripts:
  analyze:
    run: melos exec -- dart analyze --fatal-infos
    description: Analyze every package.

  format:
    run: melos exec -- dart format --output=none --set-exit-if-changed .
    description: Check formatting across every package.

  fix:
    run: melos exec -- dart fix --apply
    description: Apply automatic fixes across every package.

  test:
    run: melos exec --fail-fast -- flutter test
    description: Run tests across every package.

  build:
    run: dart run build_runner build --delete-conflicting-outputs
    description: Run code generation (app only - khulla_ui has no generators).
    packageFilters:
      scope: khulla

  localize:
    run: flutter gen-l10n
    description: Regenerate AppLocalizations from ARB files.
    packageFilters:
      scope: khulla
```

### `make` as the human interface

Developers never type `melos run analyze` directly - the Makefile wraps everything:

```makefile
bootstrap:
	dart run melos bootstrap

build:
	dart run melos run build

localize:
	dart run melos run localize

check: format analyze test

analyze:
	dart run melos run analyze

format:
	dart run melos run format

fix:
	dart run melos run fix

test:
	dart run melos run test
```

The split between Melos (workspace orchestration) and Make (human-facing interface) means contributors type `make check` and do not need to know about Melos until they add a new script or package.

### Why `dart format .` from the root is banned

`analyzer.exclude` in `analysis_options.yaml` uses a **replacement** semantic when inherited via `include:`. An including file's `analyzer.exclude` replaces the included one's - it does not merge. Running `dart format .` from the repo root picks up the root's `analysis_options.yaml` but may miss the generated-file globs that live in a package's own options, depending on which package it finds first. `melos exec -- dart format` runs in each package directory, picking up that package's analysis options correctly.

The same applies to `dart analyze`: running it from the root is unreliable for a multi-package repo. `melos exec -- dart analyze` is reliable.

### `melos bootstrap` vs `flutter pub get`

`flutter pub get` in the root resolves the app's dependencies and writes a `pubspec.lock` for the app only. `packages/khulla_ui/pubspec.lock` is not updated. `melos bootstrap` runs `pub get` in every package in dependency order and links local packages via `pubspec_overrides.yaml` (written by Melos, gitignored). After `melos bootstrap`, the app resolves `package:khulla_ui` from the local path, not from pub.dev.

A fresh clone that runs `flutter pub get` before `melos bootstrap` will appear to work - the app resolves `khulla_ui` from the path entry in `pubspec.yaml` - but `khulla_ui`'s own dependencies may be unresolved, producing confusing import errors. `dart run melos bootstrap` is always the first step.

### Adding a new package

1. Create the directory under `packages/`.
2. Add a `pubspec.yaml` with a `name:` and `environment:` matching the workspace SDK constraint.
3. `dart run melos bootstrap` - Melos picks it up automatically from the `packages/**` glob.
4. Every workspace command (`make analyze`, `make test`) now includes the new package with no Makefile change.

If the new package needs to be a dependency of the app, add it to the app's `pubspec.yaml` as a path dependency and re-bootstrap.

### `sizzbe-app/` is excluded

`sizzbe-app/` is a read-only reference copy of the codebase these conventions came from. It is gitignored and excluded from Melos via:

```yaml
packages:
  - .
  - packages/**
# sizzbe-app/ is intentionally absent - it is not a workspace package
```

It is also excluded from `analysis_options.yaml`'s `analyzer.exclude` list and from `dart format`. Never import from it; never edit it.

## Consequences

**What this buys**

- `make check` runs format, analyze, and test across every package. A lint failure in `khulla_ui` surfaces as a CI failure with a clear package label.
- `dart run melos bootstrap` is one command for any number of packages. A third package is three lines in `melos.yaml` and a `pub get` away from being included in every check.
- Generated files from `melos exec` stay inside each package's directory. No root-level pollution.
- The Makefile is stable: it delegates to Melos, so adding a package does not require updating make targets.

**What this costs**

- `dart run melos bootstrap` is not `flutter pub get`. A contributor who runs `flutter pub get` and then tries to run the app will encounter `khulla_ui` dependency resolution errors if Melos has not been run. This is documented in the README and the contributing guide but is still the most common setup mistake.
- `pubspec_overrides.yaml` files are written by Melos into each package directory. They are gitignored. After a `git clean -fd`, they are gone and `melos bootstrap` must be re-run. This surprises contributors who use aggressive git clean.
- Melos is a dev dependency (`dart pub global activate melos`). CI must install it before running workspace commands. `dart run melos` (via `dev_dependencies: melos: …` in the root pubspec) sidesteps the global activation requirement and is the preferred invocation - it uses the pinned version in the lockfile rather than whatever the system has.

## Revisiting

The trigger to re-evaluate Melos is a Dart/Flutter native workspace feature that covers the same ground - bootstrapping, cross-package script execution, and per-package analysis options. Dart workspaces (the `workspace:` key in `pubspec.yaml`, stable in Dart 3.5) cover dependency resolution but not script execution; Melos still handles the `exec` layer. When the two converge, migrating the dependency management to native workspaces while keeping Melos only for scripts is the natural path.
