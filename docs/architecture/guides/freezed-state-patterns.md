# ADR 0025 - `freezed` state patterns

**Status:** Accepted · **Date:** 2026-09-03

## Context

Cubit states need three properties: immutability (a widget rebuild is triggered by a new state value, not by a mutation), value equality (so `BlocBuilder` can check whether a rebuild is warranted), and `copyWith` (so a cubit can emit a state that differs from the current one by a single field without reconstructing everything).

Writing these by hand is boilerplate-heavy and error-prone. A hand-written `copyWith` that forgets to default a nullable field to `keep the existing value` will silently wipe that field on every transition. A hand-written `==` that misses a new field after a refactor will suppress a rebuild when the state actually changed.

`freezed` generates `copyWith`, `==`, `hashCode`, and `toString` from annotated class declarations. More importantly for this codebase, it offers two shapes: a **sealed union** (multiple `const factory` variants, each a different subclass) and a **single-class** shape (one `const factory`, with `copyWith` generated over all fields). The choice between them is architectural, not cosmetic.

### Why not a sealed union

Sealed unions (`@freezed class S { const factory S.initial() = _Initial; const factory S.loaded({…}) = _Loaded; … }`) fit state machines where each state is genuinely structurally different - a loading state that has no data and a loaded state that has data, with no overlap between variants.

Most states in this app are not like that. A form state transitions through `initial → loading → loaded/error` but carries `formz` inputs at every step. If the inputs lived only on the `loaded` variant, the cubit would have to copy them out before emitting `loading` and restore them after. That is manual field forwarding that `copyWith` exists to prevent. A sealed union forces you to redeclare every shared field in every variant, which is exactly the duplication the single-class shape avoids.

## Decision

All cubit states are **single-class `freezed` types** - one `const factory`, all fields in one place, `copyWith` across all of them.

### Canonical shape

```dart
@freezed
abstract class TitleFormState with _$TitleFormState {
  const factory TitleFormState({
    @Default(FormzSubmissionStatus.initial) FormzSubmissionStatus status,
    @Default(RequiredText.pure())           RequiredText title,
    @Default(RequiredText.pure())           RequiredText isbn,
    @Default(RequiredText.pure())           RequiredText callNumber,
    AppException?                           error,
  }) = _TitleFormState;

  const TitleFormState._();

  bool get isValid      => Formz.validate([title, isbn, callNumber]);
  bool get isSubmitting => status.isInProgress;
}
```

Every field has a default. The state can be constructed with `const TitleFormState()` and reach any other state via `copyWith`. No variant requires duplicating any field.

### The private constructor ordering rule

`freezed` requires a private `const ClassName._()` constructor to allow getters and methods on the class. The lint `sort_unnamed_constructors_first` requires unnamed constructors before named ones. These two requirements collide: the usual freezed example puts `._()` before the `const factory`, but `sort_unnamed_constructors_first` rejects that ordering.

**The correct ordering is `const factory` first, then `._()` second:**

```dart
@freezed
abstract class CatalogState with _$CatalogState {
  // 1. unnamed const factory - sort_unnamed_constructors_first is satisfied
  const factory CatalogState({
    @Default(LoadStatus.initial) LoadStatus status,
    @Default(<Title>[])          List<Title> titles,
    AppException?                error,
  }) = _CatalogState;

  // 2. private constructor - required for getters/methods below
  const CatalogState._();

  bool get isLoading => status.isLoading;
  bool get hasError  => status.hasError;
  bool get isEmpty   => status.isLoaded && titles.isEmpty;
}
```

An `// ignore: sort_unnamed_constructors_first` would suppress the lint but requires a doc comment under `document_ignores`. The ordering above satisfies both rules without an ignore.

### `copyWith` and nullable fields

`freezed`'s generated `copyWith` preserves fields that are not passed. To **clear** a nullable field, pass it explicitly:

```dart
// Clears the error - correct
emit(state.copyWith(status: LoadStatus.loading, error: null));

// Does NOT clear the error - error keeps its current value
emit(state.copyWith(status: LoadStatus.loading));
```

This is the source of the `error: null` convention: every `copyWith` that sets status to `initial`, `loading`, or `loaded` also passes `error: null`. A failure passes the error. Everything else leaves it alone so a visible error is not silently wiped by an unrelated state transition.

**Never add `clearX` boolean parameters.** A `clearError: true` workaround for this behaviour is a pattern that `copyWith` already handles - it just requires passing `error: null` explicitly. Extra boolean parameters on the state or the cubit method add API surface for a problem that has no solution at all.

### `@Default` for collection fields

`@Default(<Title>[])` initializes a list field to an empty list. The angle-bracket type annotation is required - `@Default([])` is inferred as `List<dynamic>`. More importantly, `@Default([Title('some', 'value')])` does **not** compile: constant collection literals containing non-`const` values are not valid `const` expressions, and `@Default` requires a compile-time constant. Initial collection data is seeded by the cubit, not the state constructor:

```dart
// In the cubit
emit(state.copyWith(titles: loadedTitles));  // seeded after the query

// Not in the state
// @Default([Title(id: '…', name: '…')]) - does not compile
```

### Getters that expose derived booleans

States expose exactly three boolean getters for `LoadStatus`-backed states:

```dart
bool get isLoading => status.isLoading;   // covers initial too
bool get hasError  => status.hasError;
bool get isEmpty   => status.isLoaded && items.isEmpty;
```

`isLoaded` is intentionally not exposed as a getter. A widget that checks `state.isLoaded` is usually about to check `state.isEmpty` or `state.hasError` separately - expose the meaningful combinations, not the raw enum value. A widget that needs `isLoaded` for a reason not covered by the three getters is a signal that a fourth getter is warranted, with a name that describes what the UI is deciding.

Form states expose `isValid` (delegates to `Formz.validate`) and `isSubmitting` (delegates to `FormzSubmissionStatus`). The naming mirrors the UI decision: "can I submit?" and "am I already submitting?", not "what is the raw status enum value?".

### `run build` after state changes

`make build` must be run after adding or changing a state class. The `*.freezed.dart` file is generated, not committed. A state change without a subsequent `make build` leaves the generated class stale; the app will either not analyze or exhibit behavior that does not match the state definition. CI runs `make build` before `make analyze`, so a stale generated file fails the build rather than reaching a reviewer silently.

## Consequences

**What this buys**

- `copyWith` across all fields means a three-field state change is one call. No field forwarding, no manual copy constructor.
- Value equality is generated and complete. `BlocBuilder` rebuilds when and only when the state actually changed. A missing field in a hand-written `==` is not possible.
- The `error: null` convention is enforceable in code review: every `copyWith` that sets a non-error status should show `error: null` in its arguments.
- Getters on the state (through the `._()` constructor) mean the widget reads `state.isLoading`, not `state.status == LoadStatus.loading` repeated across every `BlocBuilder`.
- The single-class shape means `formz` inputs survive every status transition with no manual forwarding.

**What this costs**

- `make build` after every state change. A new contributor who adds a field and does not run codegen will see analyzer errors that look like the state is broken, not like a missing build step.
- The `const factory` / `._()` ordering is not the order shown in most `freezed` documentation. A contributor copying from an example outside this repo will put `._()` first and hit a lint failure. The correct ordering needs to be in the contributing guide and in code review comments until it is muscle memory.
- The `@Default(<Title>[])` angle-bracket requirement and the no-`@Default`-with-non-const-values rule are subtle. Both produce cryptic error messages if violated (`The default value of an optional parameter must be constant` is not obviously about `@Default`).

## Revisiting

The trigger to consider sealed unions for a specific state is a feature whose states are genuinely structurally different - a state machine where the `loading` variant truly carries no data and the `loaded` variant carries none of the `loading` variant's fields. An import flow with a multi-step preview-confirm-rollback structure might qualify. A single-feature switch to a sealed union does not affect any other state in the app.

The trigger to replace `freezed` is a Dart language feature that generates `copyWith`, `==` and `hashCode` natively - a `@value` annotation or a sealed data class syntax. Until that lands, `freezed` is the standard and the generated code is reliable enough that the `*.freezed.dart` files are never hand-edited.
