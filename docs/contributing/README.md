# Contributing

Thanks for helping build Khulla.

## Setup

You need [FVM](https://fvm.app) and the platform toolchains: Visual Studio with _Desktop development with C++_ for Windows; `clang`, `cmake`, `ninja-build`, `libgtk-3-dev` for Linux; Xcode for macOS and iOS.

```sh
dart pub global activate fvm   # once, if you do not have FVM yet
fvm install
make bootstrap
make build                     # generated sources are not committed - required on a fresh clone
make localize
```

If a pull request bumps `.fvmrc`, run `fvm install` before `make bootstrap`.

Verify your setup with `make check`.

## Licence and the CLA

Khulla is AGPL-3.0-only and also sold under a commercial licence (see [COMMERCIAL-LICENSE.md](../../COMMERCIAL-LICENSE.md)). A pull request can only be merged once its author has agreed to the [Contributor License Agreement](../../CLA.md) - the pull request template has the line to include. You keep the copyright in your work.

## Before you open a pull request

```sh
make check      # format + copyright-check + analyze + test
```

CI runs `make ci`, which is the same set of gates with one difference: unformatted code fails the build instead of being rewritten. Run `make check` locally and the formatting is already done.

Analysis runs with `--fatal-infos`, so an info-level lint fails the build. Run `make fix` first - it resolves most of them automatically.

Never run `dart format .` or `dart analyze` from the repository root. `make format` and `make analyze` go through `melos exec`, which keeps them inside workspace packages.

## Conventions

The architecture guide is [`docs/architecture/`](../architecture/README.md). It is the accurate and complete description of how this codebase is organized - read it before your first change. The short version:

- **One public class per file**, filename matching the class in `snake_case`.
- **No hard-coded colors, spacing, or corner radii.** Read tokens from the theme. `packages/khulla_ui/lib/src/theme/app_palette.dart` is the only file allowed to contain a hex color.
- **No hard-coded user-facing strings.** Every label goes in `lib/l10n/arb/app_en.arb` and is read via `context.l10n`.
- **`App`-prefixed class names are reserved** for the design system. Feature widgets take the feature's name as a prefix instead.
- **Schema changes are append-only migrations.** Never edit a migration that has shipped - someone's catalogue was built by running exactly that SQL.
- **Every handwritten Dart file starts with the Khulla copyright header** - `SPDX-License-Identifier: AGPL-3.0-only`, or `MIT` under `packages/khulla_ui`. `make copyright` adds it to new files; `make check` fails without it. Generated files are exempt.

## Branches and commits

Branch off `dev`. Direct commits to `dev` and `prod` are blocked by a git hook.

Commit messages follow a conventional format, also enforced by a hook:

```
type(scope): message
```

Valid types: `feat`, `fix`, `chore`, `refactor`, `sync`, `ci`.

```
feat(catalog): add ISBN lookup to the title editor
fix(circulation): stop a return from clearing the loan history
```

Open pull requests against `dev`. `make pr` pushes and opens one for you.

## Releasing

`dev` is where work lands; `prod` is what ships. Merging into `prod` builds Windows, Linux, Android and web, publishes them to the releases page at the version in `pubspec.yaml`, and redeploys the web demo - no tag to push afterwards.

That makes bumping `version:` in `pubspec.yaml` part of any pull request into `prod`. CI fails the PR if that version has already been released, because merging it as it stands would publish nothing.

See [releasing.md](./releasing.md), which also covers how to hand someone a test build without releasing.

## Reporting bugs

Open an issue with the platform you hit it on (Windows, web, …), the Flutter version from `fvm flutter --version`, and the steps to reproduce. If it involves the database, say whether it happened on a fresh install or an existing catalogue - migration bugs and query bugs look identical from the outside.
