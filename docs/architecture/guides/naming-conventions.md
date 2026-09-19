# ADR 0033 - Naming conventions

**Status:** Accepted · **Date:** 2026-09-03

## Context

A codebase with several contributors and several features needs naming conventions that answer two questions without ambiguity: where does a file live, and what does a name mean? Without those answers, two developers add a widget called `TitleCard` (one in `shared/`, one in the title feature), a cubit method called `load()` appears in three cubits for three different things, and a reviewer has to open a file to know whether `AppButton` is a design-system primitive or a feature widget that happened to get a bad prefix.

Naming conventions also determine searchability. `grep TitleCubit.loadTitles` returns exactly one definition and its call sites. `grep .load(` returns every cubit in the codebase plus every HTTP client that was never deleted from the reference copy.

## Decision

The following conventions apply across the entire repository. They are a single reference - the authoritative source is this document.

---

### Files

- **`snake_case.dart`** for every Dart file.
- **One public class per file.** The filename matches the class it exports.

```
BookListTile   → book_list_tile.dart
AppButton      → app_button.dart
TitleCubit     → title_cubit.dart
TitleState     → title_state.dart   (own file, same cubit/ folder)
```

- **Private helpers** (extension methods, small data classes used only in one file) may live in the same file as the class they support. A helper that grows beyond one screenful is its own file.

---

### Class prefixes

| Prefix          | Where                                   | Meaning                            |
| --------------- | --------------------------------------- | ---------------------------------- |
| `App`           | `packages/khulla_ui` only               | Design-system primitive. Reserved. |
| `<FeatureName>` | Feature `presentation/widgets/`         | Feature-scoped UI widget.          |
| _(none)_        | `shared/widgets/`, `shared/components/` | Generic or multi-feature widget.   |

`App` is the one prefix with a hard rule: a class outside `packages/khulla_ui` must never start with `App`. A `AppMemberCard` in a feature widget folder is wrong on two counts - it is not a design-system primitive and it falsely implies it is.

Feature widgets take the feature or resource name as a prefix, not `App`:

```
CatalogFilterBar      ✓   features/catalog/shared/presentation/widgets/
TitleListTile         ✓   features/catalog/title/presentation/widgets/
MemberStatusChip      ✓   features/members/member/presentation/widgets/
AppTitleListTile      ✗   wrong prefix for a feature widget
```

---

### Pages

- Named `<feature>_page.dart`, class `<Feature>Page`.
- Live under `presentation/pages/` or at the step root inside a multi-step flow.
- A page composes sections and has a shallow `build()`. Business logic belongs in the cubit; layout belongs in child widgets.

```
catalog_page.dart         →  CatalogPage
title_detail_page.dart    →  TitleDetailPage
sign_in_page.dart         →  SignInPage
```

---

### Cubit / state pairs

- Always together in a `cubit/` folder.
- `<name>_cubit.dart` + `<name>_state.dart`.
- Never loose beside a page or widget file.

```
features/catalog/title/presentation/cubit/
├── title_cubit.dart     →  TitleCubit
└── title_state.dart     →  TitleState
```

---

### Cubit method names

Every public cubit method is **verb + the noun it acts on**. The call site is readable without knowing which cubit the variable holds.

#### Reads

| Pattern                | Example               | Use                                              |
| ---------------------- | --------------------- | ------------------------------------------------ |
| `load<Noun>s()`        | `loadTitles()`        | Fetch a collection; triggered by a page on entry |
| `load<Noun>(id)`       | `loadTitle(id)`       | Fetch one record by identifier                   |
| `refresh<Noun>s()`     | `refreshTitles()`     | Re-fetch when a separate pull-to-refresh exists  |
| `search<Noun>s(query)` | `searchTitles(query)` | Filter a collection                              |

#### Writes

| Pattern                   | Example                   |
| ------------------------- | ------------------------- |
| `add<Noun>(data)`         | `addCopy(companion)`      |
| `save<Noun>(data)`        | `saveTitle(form)`         |
| `remove<Noun>(id)`        | `removeMember(id)`        |
| `duplicate<Noun>(id)`     | `duplicateCopy(id)`       |
| `toggle<Noun><Flag>()`    | `toggleTitleFeatured(id)` |
| `set<Noun><Field>(value)` | `setMemberStatus(status)` |

#### Form submits - name the outcome, not the gesture

```
checkOutCopy()    ✓
returnCopy()      ✓
renewLoan()       ✓
saveMember()      ✓
submit()          ✗  - which cubit? what outcome?
confirm()         ✗  - same problem
```

#### Field changes

`<field>Changed(value)` - the field name carries the noun, so no extra noun is required:

```
titleChanged(value)      ✓
isbnChanged(value)       ✓
memberIdChanged(value)   ✓
onChange(value)          ✗
updateField(value)       ✗
```

#### The one-noun exception

Drop the noun only when the cubit owns a single unnamed thing and the verb is globally unambiguous:

```
signOut()         ✓   AuthCubit - nothing else "signs out"
restoreSession()  ✓   AuthCubit - nothing else "restores a session"
```

Private helpers follow the same rule. `_saveCopy` is correct; `_save` beside a renamed public method is the same ambiguity one level down.

---

### Placeholder / mock data

- `<feature>_placeholder.dart` under `presentation/placeholder/`.
- Never under `presentation/widgets/`.
- Contains preview models and mock collections for use before the real data layer exists.

```
features/catalog/shared/presentation/placeholder/catalog_placeholder.dart
```

---

### Shared widgets and components

- `shared/widgets/` and `shared/components/` use plain descriptive names with no prefix.
- One widget per file; filename matches the class.

```
shared/widgets/
├── labeled_divider.dart       →  LabeledDivider
└── section_header.dart        →  SectionHeader

shared/components/
├── error_retry_view.dart      →  ErrorRetryView
└── empty_result_view.dart     →  EmptyResultView
```

---

### Drift tables

- Class name is **plural** (`Titles`, `Copies`, `Members`, `Loans`).
- File is named for the class in `data/tables/`: `Titles` → `titles.dart`.
- The generated data class is singular (`TitleData`, `CopyData`) - drift derives it from the table class name.

```
features/catalog/title/data/tables/
└── titles.dart     →  class Titles extends Table { … }
                        generated: TitleData, TitlesCompanion
```

---

### Domain models

- Singular class name matching the resource (`Title`, `Copy`, `Member`, `Loan`).
- `@freezed`, lives in `domain/models/`.
- No drift imports.

```
features/catalog/title/domain/models/title.dart   →  Title
```

---

### Repository and data source interfaces

- `abstract interface class <Name>Repository` in `domain/<name>_repository.dart`.
- `abstract interface class <Name>LocalDataSource` in `data/<name>_local_data_source.dart`.
- Implementations: `<Name>RepositoryImpl` in `data/<name>_repository_impl.dart`, `Local<Name>DataSource` in `data/local_<name>_data_source.dart`.

```
title_repository.dart              →  TitleRepository (interface)
title_repository_impl.dart         →  TitleRepositoryImpl (@LazySingleton(as: TitleRepository))
title_local_data_source.dart       →  TitleLocalDataSource (interface)
local_title_data_source.dart       →  LocalTitleDataSource (@LazySingleton(as: TitleLocalDataSource))
```

---

### Mapper files

- `data/mappers/<feature>_row_mappers.dart`.
- Contains `extension` methods: `toDomain()` on the drift data class, `toCompanion()` where needed.
- No class declaration - just extension methods on the generated row type.

```
features/catalog/title/data/mappers/title_row_mappers.dart

extension TitleRowMappers on TitleData {
  Title toDomain() => Title(id: id, name: name, …);
}
```

---

### `Routes` constants

- `lowerCamelCase` constant names matching the resource.
- Path segments are `kebab-case` if multi-word (e.g., `'/catalog/new-title'`), singular for detail routes, plural for list routes.

```dart
abstract final class Routes {
  static const dashboard   = '/dashboard';
  static const catalog     = '/catalog';
  static const catalogTitle    = '/catalog/titles/:id';
  static const catalogTitleNew = '/catalog/titles/new';
}
```

---

### ARB keys

- `lowerCamelCase`.
- Named by **context and meaning**, not by current English wording.

```json
"addTitle":              "Add title"          ✓  stable if copy changes
"addTitleButtonLabel":   "Add title"          ✗  tied to current wording
"errorDuplicateRecord":  "Already exists."    ✓
```

---

### Asset constants (generated)

- Accessed via `Assets.<folder>.<name>` from `lib/gen/assets.gen.dart`.
- Never as string literals.

```dart
Assets.icons.book           ✓
'assets/icons/book.png'     ✗
```

---

## Consequences

**What this buys**

- `grep TitleCubit.loadTitles` returns exactly one definition. `grep .loadTitles(` returns every call site. Neither returns noise.
- File location is derivable from the class name alone. A reviewer looking for `TitleListTile` opens `features/catalog/title/presentation/widgets/title_list_tile.dart` without searching.
- The `App` prefix reservation makes design-system violations visible in code review without opening a file - a class outside `khulla_ui` starting with `App` is wrong by inspection.
- Cubit method names at the call site are self-documenting: `context.read<CheckoutCubit>().checkOutCopy()` describes an outcome; `context.read<CheckoutCubit>().submit()` describes a gesture.

**What this costs**

- Strict one-class-per-file produces more files than a looser convention. A cubit and its state are two files in a `cubit/` folder, not one. This is deliberate - the filename is part of the navigation system. The file count is manageable; the ambiguity of "which cubit is in this file?" is not.
- Feature-prefix for widgets means renaming a feature renames its widget files too. This is correct: the prefix signals scope, and a widget that no longer belongs to one feature should be promoted to `shared/` at that point.
- The verb+noun method rule occasionally produces slightly awkward names (`toggleTitleFeatured`, `duplicateCopy`). These are always preferred over the bare verb - the awkwardness is a signal that the cubit may be doing too much, not that the rule is wrong.

## Revisiting

Naming conventions evolve with the codebase. A new resource type or architectural layer that has no clear mapping to these rules gets its own sub-section added here. The trigger is a code review where two developers independently reach different answers for the same naming question - that gap belongs in this document.
