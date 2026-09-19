.PHONY: bootstrap install-sdk build migrate db-diagram localize analyze format format-check fix test check ci clean \
        copyright copyright-check \
        db-web run-web run-windows run-linux build-web build-windows build-linux build-apk pr seed-mock

# Overridable so CI can use the SDK already on PATH instead of installing FVM
# to shell out to the same SDK. Locally these stay on FVM, which pins .fvmrc.
FLUTTER ?= fvm flutter
DART ?= fvm dart

# ── Setup ───────────────────────────────────────────────────────────────────

## Install the Flutter SDK version pinned in .fvmrc.
install-sdk:
	fvm install

## Resolve dependencies and link local packages across the workspace.
bootstrap:
	$(DART) run melos bootstrap

# Keep in step with the `drift` version in pubspec.yaml - the worker and the
# WebAssembly build are only guaranteed to match within one release.
DRIFT_RELEASE := drift-2.34.3

## Fetch the SQLite WebAssembly build and the drift worker into web/.
## Only needed after upgrading drift - the output is checked in.
db-web:
	curl -fsSL -o web/sqlite3.wasm \
	  https://github.com/simolus3/drift/releases/download/$(DRIFT_RELEASE)/sqlite3.wasm
	curl -fsSL -o web/drift_worker.js \
	  https://github.com/simolus3/drift/releases/download/$(DRIFT_RELEASE)/drift_worker.js

# ── Code generation ─────────────────────────────────────────────────────────

## freezed, injectable, json_serializable and flutter_gen.
build:
	$(DART) run build_runner build

## Record the current schema, regenerate step-by-step migrations and their
## tests. Run after changing a table and bumping schemaVersion, before `build`.
migrate:
	$(DART) run drift_dev make-migrations

## Regenerate the Mermaid ER diagram in docs/database/schema.md from the
## latest drift schema snapshot. Run after `make migrate` / `make build`.
db-diagram:
	$(DART) tools/db_diagram.dart

## Regenerate AppLocalizations from lib/l10n/arb/.
localize:
	$(FLUTTER) gen-l10n

## Regenerate launcher icons across all platforms (Android, iOS, Web, macOS, Windows, Linux).
icons:
	$(DART) run icons_launcher:create

# ── Scratch data ────────────────────────────────────────────────────────────

## Insert mock books into the dev catalogue (platform default path).
## Override with ARGS, e.g. `make seed-mock ARGS="--clear"` or
## `make seed-mock ARGS="--db /path/to/khulla_dev.sqlite --titles 5"`.
seed-mock:
	$(DART) run script/seed_mock_books.dart $(ARGS)

## Wipe the build_runner cache. Use when codegen fails after a dependency bump.
clean:
	rm -rf .dart_tool/build

# ── Quality ─────────────────────────────────────────────────────────────────

analyze:
	$(DART) run melos run analyze

format:
	$(DART) run melos run format

## Fail if any handwritten Dart source is unformatted, without rewriting it.
## Asks git for the file list rather than walking the tree: tracked plus new,
## minus everything gitignored. That is what keeps it out of the generated
## sources, whose formatting is build_runner's business, and out of sizzbe-app/.
## Files git still lists but that are deleted on disk are filtered out.
format-check:
	@files=$$(git ls-files --cached --others --exclude-standard '*.dart' \
	  | while IFS= read -r f; do [ -f "$$f" ] && echo "$$f"; done); \
	  if [ -n "$$files" ]; then \
	    $(DART) format --output=none --set-exit-if-changed $$files; \
	  fi

fix:
	$(DART) run melos run fix

test:
	$(DART) run melos run test

## Check that handwritten Dart files carry the Khulla copyright header.
## Generated files are skipped (see tools/copyright.dart).
copyright-check:
	$(DART) tools/copyright.dart

## Stamp the Khulla copyright header onto files missing it.
copyright:
	$(DART) tools/copyright.dart --fix

## Do this before opening a pull request. Formats in place, then checks.
check: format copyright-check analyze test

## What CI runs. Same gates as `check`, except that unformatted code fails the
## build instead of being quietly rewritten on a runner nobody will commit from.
ci: format-check copyright-check analyze test

# ── Run ─────────────────────────────────────────────────────────────────────

run-web:
	$(FLUTTER) run -d chrome -t lib/main_dev.dart

run-windows:
	$(FLUTTER) run -d windows -t lib/main_dev.dart

run-linux:
	$(FLUTTER) run -d linux -t lib/main_dev.dart

# ── Release builds ──────────────────────────────────────────────────────────
#
# Desktop and web do not support `--flavor`; the entrypoint selects the flavor
# on every platform, so these all target lib/main_prod.dart directly.

build-web:
	$(FLUTTER) build web --release -t lib/main_prod.dart

build-windows:
	$(FLUTTER) build windows --release -t lib/main_prod.dart

build-linux:
	$(FLUTTER) build linux --release -t lib/main_prod.dart

build-apk:
	$(FLUTTER) build apk --release -t lib/main_prod.dart

# ── Git ─────────────────────────────────────────────────────────────────────

pr:
	git push
	gh pr create \
		--base dev \
		--title "$$(branch=$$(git branch --show-current); prefix="$${branch%%/*}"; name="$${branch#*/}"; printf '%s: ' "$$prefix"; echo "$$name" | sed 's/-/ /g' | awk '{for(i=1;i<=NF;i++) $$i=toupper(substr($$i,1,1)) substr($$i,2)}1')" \
		--body ""