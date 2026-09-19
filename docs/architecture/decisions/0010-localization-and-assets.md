# ADR 0010 - Localization and asset generation strategy

**Status:** Accepted · **Date:** 2026-09-03

## Context

A library management system used in schools and community libraries across multiple regions needs two things beyond raw `String` literals: localized user-facing text, and generated accessors for image and icon assets. Both have the same failure mode if handled naively - a renamed key or a deleted file produces a runtime null or a broken image, visible only when that specific string or asset is exercised in that locale.

### Strings

Hard-coded strings are untranslatable by definition. They are also unmaintainable: `Text('Add title')` in a widget is a string that appears nowhere in any translation workflow, cannot be found by a search for `addTitle`, and changes in isolation from its counterpart in every other locale.

The alternative is a type-safe generated accessor. Flutter's `flutter_localizations` package generates an `AppLocalizations` class from ARB files. Every key in the ARB file becomes a method or getter on `AppLocalizations`. A renamed key is an analyzer error at every call site. A key with a placeholder gets a method with a typed parameter. The ARB file is the single source of truth; translators edit it, and `make localize` regenerates the class.

### Assets

Asset paths as string literals are unverified at compile time. `Image.asset('assets/icons/book.png')` compiles regardless of whether that file exists. The error surfaces at render time, in a specific UI state, possibly only in the production build.

`flutter_gen` generates a type-safe `Assets` class from `pubspec.yaml`'s `flutter.assets` declaration. `Assets.icons.book` returns a string constant equal to the correct path. A deleted or renamed file is an analyzer error the next time `make build` runs.

## Decision

All user-facing strings go in **ARB files** (`lib/l10n/arb/app_en.arb` as the source locale). All asset access uses **generated `Assets.*` constants** from `package:khulla/gen/assets.gen.dart`. Neither string literals nor asset paths appear in widget code.

### Localization

#### ARB as source of truth

`lib/l10n/arb/app_en.arb` is the canonical string file. Adding a locale means adding `app_<locale>.arb`. The generated `AppLocalizations` class (`lib/l10n/gen/`) is not committed - `make localize` regenerates it from the ARB files. A fresh clone runs `make localize` before the app analyzes.

#### Access via `context.l10n`

```dart
// lib/l10n/l10n.dart
extension AppLocalizationsX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this)!;
}
```

Every call site writes `context.l10n.addTitle`, not `AppLocalizations.of(context)!.addTitle`. The extension is shorter and fails loudly (not silently with `null`) if the delegate was not registered.

#### Naming conventions

ARB keys use `lowerCamelCase`. Names express the _context and meaning_ of the string, not its current English wording:

```json
{
  "addTitle": "Add title",
  "@addTitle": { "description": "Button label to open the add-title form" },

  "errorDuplicateRecord": "A record with that identifier already exists.",
  "@errorDuplicateRecord": {
    "description": "Shown when a database insert fails with a unique constraint violation"
  },

  "loanDaysOverdue": "{count, plural, one{1 day overdue} other{{count} days overdue}}",
  "@loanDaysOverdue": {
    "description": "Fine accrual message on a loan detail page",
    "placeholders": { "count": { "type": "int" } }
  }
}
```

Naming by English wording (`"addTitleButtonLabel"`) ties the key to the current translation, forcing a rename when the copy changes. Naming by context (`"addTitle"`) stays stable.

#### What is not ARB text

- **Money amounts.** Never write a currency symbol in an ARB value. A placeholder is `{"type": "String"}` filled with `money.display()`. The currency symbol and grouping live in `MoneyFormat`.
- **Dates and times.** `DateFormat` from `intl` formats them with locale awareness; the pattern string is a parameter, not an ARB value.
- **Enum labels** that are app-logic identifiers (database column values, filter keys). Those are constants, not translated strings.
- **Error messages from `AppException`.** `AppException` carries a `source` string for logging, not a user string. The user string comes from `AppExceptionL10n.localizedMessage(context, error)`, which maps exception types to ARB keys.

#### The design system split

`AppErrorView` and `AppEmptyView` in `khulla_ui` take ready-made `String` parameters, not `AppLocalizations` keys. The app side (`ErrorRetryView`, `EmptyResultView`) in `shared/components/` resolves the localized strings and passes them in. `khulla_ui` has zero knowledge of `AppLocalizations` - it compiles without the localization dependency.

This split means a widget in `khulla_ui` can be tested with hardcoded strings and a widget in `shared/components/` is where localization knowledge lives. A violation - a `khulla_ui` widget that calls `context.l10n` - imports `package:khulla/...` and creates a circular dependency.

### Assets

#### Registration

Every asset is declared in `pubspec.yaml` under `flutter.assets`:

```yaml
flutter:
  assets:
    - assets/icons/
    - assets/images/
```

`flutter_gen` generates `lib/gen/assets.gen.dart` from this declaration on `make build`. The file is not committed; it is regenerated on each build.

#### Access

```dart
// Correct - type-safe, fails at build time if the file is deleted
Image.asset(Assets.icons.book)

// Wrong - invisible at compile time, fails at render time
Image.asset('assets/icons/book.png')
```

`Assets` is a generated class with one static field per asset file. Nested folders become nested classes: `Assets.icons.book`, `Assets.images.defaultCover`. Adding an asset file means adding it to `assets/` and to `pubspec.yaml`, then running `make build`.

#### `khulla_ui` assets

Assets used only in the design system live in `packages/khulla_ui/assets/`. They are declared in `packages/khulla_ui/pubspec.yaml` and accessed via a separate generated class in `khulla_ui`. The app's `Assets` class does not contain design-system assets; the design-system's generator does not contain app assets.

### Generated sources are not committed

`lib/l10n/gen/`, `lib/gen/assets.gen.dart`, and all `*.g.dart` / `*.freezed.dart` / `*.config.dart` files are in `.gitignore`. The source of truth is the ARB files, `pubspec.yaml`, and the Dart source that `build_runner` processes. Committing generated files means every regeneration produces a diff; it also invites merge conflicts on files no human should be editing.

The consequence is that a fresh clone does not analyze or run without running `make build` and `make localize`. This is documented in the README and the contributing guide. It is a one-time setup cost that keeps the repository clean.

### `make localize` vs `make build`

`make localize` runs `flutter gen-l10n` only - fast, regenerates just `lib/l10n/gen/`. Run it after adding an ARB key.

`make build` runs the full code generation pipeline (freezed, injectable, json_serializable, flutter_gen). It always regenerates assets. Run it after adding an asset, changing a table, or changing a `freezed` state.

They are separate commands because localization changes are common and fast; full codegen is slower and needed for fewer changes.

## Consequences

**What this buys**

- A renamed ARB key is an analyzer error at every call site. Unused keys surface as warnings. Neither issue reaches a deployed build.
- A deleted asset is an analyzer error the next `make build`. No missing images in production.
- The ARB file is the single surface a translator edits - one file per locale, no Dart knowledge required.
- Plurals, genders, and selected messages are handled by the ICU message format that `flutter_localizations` supports - no per-call-site `switch` on count.
- `khulla_ui` remains dependency-free with respect to localization, staying usable outside the app context.

**What this costs**

- `make build` is required on every fresh clone, before the app analyzes. This is called out in every setup document and enforced by CI, but it is still a step contributors can miss.
- Adding a new string is three steps: add the ARB key, run `make localize`, write the call site. Forgetting `make localize` leaves the generated class stale and produces an analyzer error - which is the right failure mode, but it can confuse a contributor who does not know the step is needed.
- Money strings cannot use ARB placeholders as numbers. This is a feature, not a bug, but it means `context.l10n.fineTotal(amount.display())` instead of a formatter inside the ARB value. Keeping the pattern consistent matters: one call site that writes `'Rs ${amount.major}'` into an ARB placeholder reintroduces the 100× risk.

## Revisiting

The trigger to add a second locale is a library in a non-English locale that needs translated strings. The infrastructure is already in place: add `app_<locale>.arb`, translate the keys, add the locale to `AppLocalizations.supportedLocales` in `app.dart`, and run `make localize`. No structural change required.

The trigger to re-evaluate `flutter_gen` for assets is a project that moves to a significantly different asset pipeline - SVG sprites, Lottie animations managed by a separate tool - where string constants are generated by that tool rather than by `flutter_gen`. Until then, `flutter_gen` produces exactly what is needed with no extra tooling.
