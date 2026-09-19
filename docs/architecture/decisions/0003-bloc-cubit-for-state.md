# ADR 0003 - flutter_bloc (Cubit) for state management

**Status:** Accepted · **Date:** 2026-09-03

## Context

A local-first Flutter app with no network layer still needs a clear contract for:

- triggering database reads and writes from the UI,
- surfacing loading and error states without coupling widgets to imperative callbacks,
- coordinating screens that react to the same underlying data (a checkout that updates the member's page and the dashboard counts).

Several options were on the table at the time the first feature was about to land:

**Provider / ChangeNotifier.** Familiar, low ceremony. But `ChangeNotifier` is mutable and imperative - callers mutate shared state and call `notifyListeners()`. Testing requires constructing widgets or mocking the provider. State transitions are not tracked anywhere unless logging is added by hand.

**Riverpod.** Stronger compile-time guarantees than Provider and avoids the BuildContext dependency. But its mental model - providers as global singletons that compose - makes lifecycle tricky: a cubit that should die with its page keeps stale state across navigations unless the scope is carefully chosen. The generated code and annotation system are another layer contributors have to learn before writing a feature.

**MobX.** Reactions and observables give auto-updating derived state, but the generated `*.g.dart` files are another build step, the debugging story relies on reading reactive traces, and the error-boundary model is implicit - a reaction that throws can be surprisingly hard to surface.

**`flutter_bloc` (Cubit).** Each piece of UI state is an immutable `freezed` value. The only way to change state is to emit a new one from a cubit method. The cubit has no BuildContext dependency, so it can be instantiated and tested as a plain Dart object. `BlocObserver` logs every transition and every error app-wide from a single hook. And because every emission is an equality-checked value, `BlocBuilder` only rebuilds when the state actually changed.

The deciding factors for this app specifically:

- **Testability without Flutter.** A data-layer test can construct a cubit, call a method, and assert on the emitted states with no widget tree. On a local-first app where the database is the source of truth, this is where most interesting behaviour lives.
- **Explicit, traceable transitions.** A circulation desk is not a CRUD toy - returning a copy changes loan records, fine accrual, member standing and possibly reservation queues. Having the state machine in one class, with every transition an explicit method call, makes the sequence auditable.
- **Ecosystem convention.** `flutter_bloc` is the de-facto standard in the Dart ecosystem; contributors from other Flutter projects already know it, and the documentation is thorough.

## Decision

Use **`flutter_bloc`** with the **Cubit variant** throughout. The full `Bloc` variant (event classes + `mapEventToState`) is not used unless a feature genuinely models a complex state machine - currently none do.

### State shape

States are **single-class `freezed` types** - one `const factory`, never a sealed union. Most states carry `formz` inputs that must survive every status transition. A sealed union would force every variant to redeclare every shared field, which is duplication with no payoff.

```dart
@freezed
abstract class CatalogState with _$CatalogState {
  const factory CatalogState({
    @Default(LoadStatus.initial) LoadStatus status,
    @Default(<Title>[]) List<Title> titles,
    AppException? error,
  }) = _CatalogState;

  const CatalogState._();             // required for getters and methods

  bool get isLoading => status == LoadStatus.loading;
}
```

The private `const XState._()` constructor is required before any getter or method can be declared. It goes **after** the unnamed `const factory` - `sort_unnamed_constructors_first` enforces that order. Using `// ignore:` there costs a mandatory doc comment, so the ordering rule is the right fix.

### Load status

`LoadStatus` (`lib/shared/models/load_status.dart`) is one enum for the whole app - never a per-feature copy. States that back a database read expose exactly three getters, so the vocabulary is identical at every call site:

```dart
bool get isLoading => status.isLoading;  // covers `initial` too
bool get hasError  => status.hasError;
bool get isEmpty   => status.isLoaded && items.isEmpty;
```

`initial` counts as loading on purpose: a screen that has not read yet has nothing to show, and treating `initial` as loaded-and-empty flashes a false empty state before the query fires.

### Reads swallow; writes rethrow

- **Reads** (`loadTitles()`) emit the failure into `state.error` and return normally - the page is already watching that field.
- **Writes** (`saveTitle`, `addCopy`, `removeMember`) emit _and_ rethrow. A write responded to a gesture and needs a gesture-level answer - a toast, not a silent state update.
- A read the caller _awaits for its value_ (`loadTitle(id)`) also rethrows: swallowing it leaves the caller suspended on a record that never arrives.

By convention a cubit clears `error` whenever it starts fresh: every `copyWith` that sets `status` to `initial`, `loading` or `loaded` also passes `error: null`. A failure passes the error, and everything else leaves it alone so a visible error is not silently wiped.

### `isClosed` guards

`@injectable` cubits are factories scoped to the widget that creates them - they are closed when the route leaves the stack. **Every `await` in a factory cubit is followed by `if (isClosed) return;`** to avoid emitting into a dead stream.

`@lazySingleton` cubits are never closed (`getIt.reset()` is never called), so they carry no `isClosed` guards. An `isClosed` check there is dead code that implies a lifecycle the cubit does not have.

An app-wide singleton holding data scoped to a thing that can change - the active branch, an import session - gets an explicit `reset<Noun>()` method called when that scope changes.

### DI and provision

Cubits are wired through `injectable` annotations (`@injectable` for route-scoped, `@lazySingleton` for app-wide) and provided through `BlocProvider` in `app_router.dart`. A widget never calls `getIt<T>()` directly: that couples the widget to the service locator and defeats the purpose of the injection setup.

### Method naming

Every public cubit method is **verb + the noun it acts on**, so the call site is readable without knowing which cubit the variable holds:

```dart
context.read<TitleCubit>().loadTitles();
cubit.saveTitle(title);
cubit.removeCopy(id);
```

- **Reads:** `load<Noun>s()` for the fetch a page triggers on entry; `refresh<Noun>s()` when a separate re-fetch exists; `load<Noun>(id)` for one record.
- **Writes:** `add<Noun>`, `save<Noun>`, `remove<Noun>`, `duplicate<Noun>`, `toggle<Noun><Flag>`, `set<Noun><Field>`.
- **Form submits** name the outcome, not the gesture: `checkOutCopy()`, `returnCopy()`, `renewLoan()` - never a bare `submit()`.
- **Field changes** keep the `<field>Changed(value)` shape (`titleChanged`, `isbnChanged`); the field name already carries the noun.

Private helpers follow the same rule (`_saveCopy`, `_searchTitles`).

### Streams and drift

`drift`'s `watch()` turns any query into an auto-updating stream; drift tracks which tables a query reads and re-runs it when a write touches one. A cubit that subscribes to a `watch()` stream must cancel: `StreamSubscription` stored in the cubit, cancelled in `close()`. The reads-swallow rule applies to streams: the error goes into `state.error` via `stream.listen(onData, onError: …)`, not as an unhandled stream error that takes down the zone.

## Consequences

**What this buys**

- State transitions are immutable, equality-checked, and logged through `BlocObserver`. Debugging is reading a list of state values, not setting breakpoints in callbacks.
- Cubits are plain Dart objects. Unit tests construct one, call a method, and use `bloc_test`'s `expect:` to assert on the emitted sequence - no widget tree required.
- The reads-swallow / writes-rethrow split gives the UI exactly two error patterns to handle, and nothing in between.
- `BlocBuilder`'s `buildWhen` parameter allows fine-grained rebuilds without extra boilerplate.
- `bloc_lint` enforces naming conventions and the `isClosed` guard statically.

**What this costs**

- More files per feature than Provider: a cubit and a state file in a `cubit/` folder per screen. The naming convention makes them predictable, but the count is real.
- `make build` is required after adding or changing a state class. Contributors unused to codegen have an extra step to learn.
- `freezed` states cannot carry `const` list defaults of domain types - `@Default(<Title>[])` compiles, but `@Default([Title(...)])` does not. Initial data must be seeded by the cubit, not the state constructor.

## Revisiting

The trigger to switch from Cubit to `Bloc` for a specific feature is a state machine that genuinely has multi-step branching - an import flow that validates, previews, confirms and rolls back, or a sync with strictly ordered phases. If that cubit becomes a giant `switch` on an enum, event classes are the right tool. That is a single-feature change and does not affect the rest of the app.
