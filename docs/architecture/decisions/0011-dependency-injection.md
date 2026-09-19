# ADR 0011 - Dependency injection with `injectable` and `get_it`

**Status:** Accepted · **Date:** 2026-09-03

## Context

A Flutter app of any real size needs to wire dependencies: a cubit needs a repository, a repository needs a data source, a data source needs the database, the database needs its config. With no framework, every `BlocProvider` and every test setup constructs the full chain by hand. That is manageable for three dependencies; it becomes a maintenance burden when a repository gains a second collaborator, or when a singleton needs to be swapped for a test double.

Three options were on the table:

**Manual construction everywhere.** Each `BlocProvider` in `app_router.dart` calls `TitleCubit(TitleRepositoryImpl(LocalTitleDataSource(getIt<AppDatabase>())))`. The chain is explicit and readable. It also has to be updated in every call site when a constructor changes, and there is no enforcement that singletons are actually single - two call sites constructing their own `AppDatabase` is a latent bug.

**`provider` / `riverpod` for DI.** These are also state-management solutions; using them only for DI is possible but imports their full mental model and their widget-tree coupling for a problem that does not need either. A repository has no reason to know it lives in a `Provider` tree.

**`get_it` + `injectable`.** `get_it` is a service locator - a typed registry. `injectable` is a code generator that reads annotations and writes the registration calls. The registry is a global, which is the usual objection to service locators; the counter is that `getIt<T>()` is called in exactly one place per dependency type (in `app_router.dart`'s `BlocProvider.create`), and everywhere else the dependency is passed as a constructor argument. That is the discipline that makes a service locator acceptable.

`injectable` was chosen over writing the registration code by hand because registration code is mechanical, changes whenever a constructor changes, and is invisible to the analyzer until runtime. A missed `registerFactory` call is a `StateError: get_it: T is not registered` at the first route push - a good failure mode, but later than an analyzer error.

## Decision

Use **`get_it`** as the service locator and **`injectable`** to generate the registration code. `make build` regenerates `lib/core/di/injection.config.dart` whenever annotations change.

### Annotations

Two lifecycle annotations cover every case in this app:

**`@lazySingleton`** - constructed once on first access, lives for the lifetime of the app. Use for: `AppDatabase`, `AppRouter`, repositories, data sources, app-wide cubits (e.g., a future `AuthCubit`).

**`@injectable`** - a new instance on every `getIt<T>()` call. Use for: feature-scoped cubits that should be closed when their route leaves the stack.

```dart
// @lazySingleton - one instance, lives forever
@LazySingleton(as: TitleRepository)
class TitleRepositoryImpl implements TitleRepository { … }

// @injectable - new instance per BlocProvider.create call
@injectable
class TitleCubit extends Cubit<TitleState> {
  TitleCubit(this._repository) : super(const TitleState());
  final TitleRepository _repository;
}
```

`@LazySingleton(as: TitleRepository)` registers the concrete class against the abstract interface. Call sites receive `TitleRepository`, never `TitleRepositoryImpl` - the interface is the contract, the impl is an internal detail.

### Constructor injection only

Every dependency is a constructor parameter. `injectable` reads the constructor signature and wires it automatically. A class that reaches for `getIt<T>()` inside a method is bypassing the injection graph and hiding a dependency from the type system.

```dart
// Correct - dependency is declared, injectable wires it
@injectable
class CheckoutCubit extends Cubit<CheckoutState> {
  CheckoutCubit(this._loans, this._copies, this._members) : super(…);
  final LoanRepository _loans;
  final CopyRepository _copies;
  final MemberRepository _members;
}

// Wrong - hidden dependency, not wirable, not mockable in tests
@injectable
class CheckoutCubit extends Cubit<CheckoutState> {
  Future<void> checkOut(String copyId) async {
    final loans = getIt<LoanRepository>(); // ← never do this
  }
}
```

### `getIt<T>()` in exactly one place

The service locator is accessed in `app_router.dart`'s `BlocProvider.create` callbacks - nowhere else. A widget, page, or cubit that calls `getIt<T>()` directly is coupled to the locator; it cannot be constructed in a test without setting up the full registry.

```dart
// app_router.dart - the one place getIt is called
GoRoute(
  path: Routes.catalogTitle,
  builder: (context, state) => BlocProvider(
    create: (_) => getIt<TitleCubit>(),
    child: TitleDetailPage(id: state.pathParameters['id']!),
  ),
),
```

App-wide singletons that are needed before the router exists (`AppDatabase`, `AppRouter` itself) are accessed in `bootstrap` via `getIt<T>()`, also the one legitimate exception.

### `@disposeMethod`

A `@lazySingleton` that owns a resource needing cleanup annotates its teardown method with `@disposeMethod`. `injectable` wires it into `GetIt.reset()`. In practice only `AppDatabase` uses this - `getIt.reset()` is never called in normal operation, but it is called in integration tests that need a clean slate.

```dart
@lazySingleton
@DriftDatabase()
class AppDatabase extends _$AppDatabase {
  …
  @disposeMethod
  Future<void> dispose() => close();
}
```

### Module for third-party types

Types the app does not own and cannot annotate go in a `@module` class:

```dart
// lib/core/di/app_module.dart
@module
abstract class AppModule {
  @lazySingleton
  AppConfig get config => AppConfig.fromEnvironment();
}
```

### Testing

Tests that need a real dependency graph call `configureDependencies()` (the generated initializer) in `setUpAll`. Tests that need a controlled graph skip `injectable` entirely and construct dependencies by hand:

```dart
final cubit = TitleCubit(FakeTitleRepository());
```

The fake implements the `TitleRepository` interface. Because every production class depends on interfaces, not impls, substituting a fake requires nothing beyond implementing the interface - no framework, no mock library unless you want one.

## Consequences

**What this buys**

- Adding a dependency to a constructor is one line. `injectable` regenerates the wiring; `make build` runs and the app works. No manual registration change required.
- Singletons are genuinely single. The registry enforces one instance per type; two call sites getting their own `AppDatabase` is impossible.
- Tests that construct cubits directly have zero framework overhead. The cubit is a plain Dart object that takes its repositories as constructor arguments.
- `@LazySingleton(as: Interface)` makes the concrete class invisible above the data layer.

**What this costs**

- `make build` is required after adding or changing an `@injectable` or `@lazySingleton` annotation. A missing build step produces a `StateError` at the first affected route push, which is a runtime error rather than a compile-time one.
- The service locator is a global. The discipline of calling `getIt<T>()` only in `app_router.dart` and `bootstrap` is a convention, not a compiler rule. A custom lint could enforce it; code review enforces it today.
- `injectable`'s generated file (`injection.config.dart`) is long and noisy. It is generated, not committed, and should never be hand-edited - but a contributor who opens it expecting readable code will be confused.

## Revisiting

The trigger to replace `injectable` is a codebase that needs truly scoped DI - subtrees with their own registry that can be torn down independently. `get_it` supports scopes, but `injectable` does not generate scoped registrations. At that point, either hand-writing the scoped registrations alongside `injectable`'s output, or switching to a scoped-DI library, is the path. That complexity does not exist yet and is unlikely to appear before sync or multi-tenancy lands.
