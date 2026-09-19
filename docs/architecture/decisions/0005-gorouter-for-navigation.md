# ADR 0005 - GoRouter for navigation

**Status:** Accepted · **Date:** 2026-09-03

## Context

A Flutter app with eight top-level sections, nested sub-features, a shared adaptive shell, and a future authentication layer needs a routing solution that can handle:

- **Deep links and browser navigation.** The web build is a first-class target. Back/forward buttons, typed URLs, and shareable paths all have to work without special cases.
- **Nested navigation within an adaptive shell.** The shell (bottom bar, nav rail, extended rail) keeps its own state while individual branches navigate. Selecting the catalog tab and drilling into a title should not reset the members tab.
- **Type-safe paths.** A hard-coded `Navigator.pushNamed(context, '/catalog/titles/42')` string is an untested contract between the call site and the route declaration. A renamed path silently stops navigating.
- **A redirect guard for authentication.** There is no sign-in yet, but the architecture anticipates it. Wiring the redirect after the fact should be a small addition, not a refactor.
- **No nested Navigators by hand.** Managing route stacks across an adaptive shell requires a mechanism that handles branch history without bespoke bookkeeping in every page.

The options considered:

**`Navigator` 1.0 (imperative).** `push()`, `pop()`, `pushNamed()`. Fine for simple linear flows; collapses under a shell with independent branch histories and no built-in deep-link handling. Browser back/forward on web requires additional scaffolding that must be written and maintained by hand.

**`Navigator` 2.0 (declarative, raw).** The `RouterDelegate` / `RouteInformationParser` model gives full control over the route stack as a data structure. The API surface is large, the boilerplate high, and every package that builds on top of it (including `go_router`) exists precisely because raw 2.0 is impractical to use directly.

**`auto_route`.** Code-generated routes from annotations. Handles nested stacks, generates type-safe calls, and integrates with Navigator 2.0. The generation step means a route change requires `build_runner` - which is already in the stack, so this is not a blocker in isolation, but it is additional generated code for a problem `go_router` also solves without it.

**`go_router`.** The Flutter team's Navigator 2.0 wrapper. Ships with Flutter's SDK-level testing and tooling support. `StatefulShellRoute.indexedStack` handles persistent branch state across an adaptive shell with no bespoke bookkeeping. `GoRouterRefreshStream` wires a stream-based guard into the redirect callback. Paths are string constants, not generated classes - less magic, but the discipline of keeping them in one file makes them navigable.

`go_router` was chosen because it solves every item on the list, it is the Flutter team's own recommendation, and it needs no additional code generation beyond what `injectable` already demands.

## Decision

Use **`go_router`** as the sole navigation layer. All route configuration lives in **`AppRouter`** (`lib/app/router/app_router.dart`), a `@lazySingleton` that owns the `GoRouter` instance. Path strings are constants in **`Routes`** (`lib/core/router/routes.dart`). Navigation at call sites is always `context.go(Routes.xxx)` - never a hard-coded string, never `Navigator.push`.

### Route tree

```
/                                → redirects to /dashboard
/dashboard                       DashboardPage
/catalog                         CatalogPage (StatefulShellBranch)
  /catalog/titles/:id            TitleDetailPage
  /catalog/copies/:id            CopyDetailPage
/circulation                     CirculationPage (StatefulShellBranch)
  /circulation/checkout          CheckoutPage
  /circulation/return            ReturnPage
/members                         MembersPage (StatefulShellBranch)
  /members/:id                   MemberDetailPage
/opac                            OpacPage (StatefulShellBranch)
/reports                         ReportsPage (StatefulShellBranch)
/staff                           StaffPage (StatefulShellBranch)
  /staff/:id                     StaffDetailPage
/settings                        SettingsPage (StatefulShellBranch)
/startup-failure                 StartupFailureApp - error before navigation exists
```

Creating and editing a record has **no route**: those forms open as modals
through `AppFormModal.show` - a centred panel on a window, a full-screen page on a phone - which is why there is no
`/titles/new` or `/members/:id/edit` here.

All eight main sections are `StatefulShellBranch` entries under one `StatefulShellRoute`. `AppShell` is the shell widget; it receives the `StatefulNavigationShell` and renders the adaptive layout around it.

### `Routes` constants

```dart
// lib/core/router/routes.dart
abstract final class Routes {
  static const dashboard        = '/dashboard';
  static const catalog          = '/catalog';
  static const catalogTitle     = '/catalog/titles/:id';
  static const catalogTitleNew  = '/catalog/titles/new';
  static const members          = '/members';
  static const member           = '/members/:id';
  // …
}
```

Call sites write `context.go(Routes.member.replaceFirst(':id', id))` or use `context.goNamed(…)` with the named parameter approach once routes have names. Constants are the source of truth - the tab order in `ShellDestinations` and the branch index in `AppRouter` must stay in sync; if they diverge, tapping the catalog tab navigates to the wrong branch silently.

### `AppRouter` as a singleton

`AppRouter` is a `@lazySingleton`. The `GoRouter` instance is constructed once and stored. Cubits that need to navigate (an auth cubit that redirects to the sign-in page after a session expires) take `AppRouter` via constructor injection - they do not reach for a `BuildContext`.

```dart
@lazySingleton
class AppRouter {
  AppRouter(/* AuthCubit auth */) {
    _router = GoRouter(
      initialLocation: Routes.dashboard,
      routes: _buildRoutes(),
      // redirect: _guard,            ← added with sign-in
      // refreshListenable: …,        ← GoRouterRefreshStream over auth stream
    );
  }

  late final GoRouter _router;
  GoRouter get router => _router;
}
```

The `redirect` and `refreshListenable` lines are commented stubs. Adding the auth guard means uncommenting them and supplying the stream - no structural change to the router.

### Cubit provision

Cubits are provided in `app_router.dart` via `BlocProvider` at the route that introduces them, not globally. A detail page that needs a `TitleCubit` gets it at the `GoRoute.builder` for that path:

```dart
GoRoute(
  path: Routes.catalogTitle,
  builder: (context, state) => BlocProvider(
    create: (_) => getIt<TitleCubit>(),
    child: TitleDetailPage(id: state.pathParameters['id']!),
  ),
),
```

The cubit lives as long as the route. When the user navigates back, the `BlocProvider` is removed from the tree and the cubit is closed. This is why route-scoped cubits use `@injectable` (factory) and not `@lazySingleton`, and why `isClosed` guards follow every `await` in those cubits.

### Web URL strategy

The web build uses the default **hash URL strategy** (`/#/catalog`). This deep-links correctly on any static host - S3, GitHub Pages, a local web server - without server-side rewrite rules. Switching to path URLs requires both `usePathUrlStrategy()` in `main_*.dart` **and** a server rewrite of every path to `index.html`, because a browser refresh on `/catalog` sends that path to the host, which has no file there. Hash URLs defer that coupling to later.

### No `Navigator.push` in feature code

Feature code never calls `Navigator.push`, `Navigator.pushNamed`, `showDialog`, or `showModalBottomSheet` directly on the root navigator. Dialogs and sheets use `showDialog` / `showModalBottomSheet` against `context` (which is a local navigator at that point), which is fine - they are not routes. Route transitions are always `context.go` or `context.push` with a `Routes` constant. This rule exists so that the router owns every state that can be expressed in a URL; it is a precondition for browser back/forward to work correctly.

## Consequences

**What this buys**

- Browser navigation (back, forward, typed URLs, deep links) works on web without extra code.
- Branch histories are preserved across adaptive shell transitions - drilling into a title in the catalog tab, switching to members, switching back, and finding the title still open.
- The redirect guard for authentication is a two-line addition, not a refactor.
- Path constants in one file make `grep` for a path correct across the whole codebase.
- `go_router`'s `GoRouterObserver` integrates with the existing `BlocObserver` logging pattern for navigation events.

**What this costs**

- `StatefulShellRoute.indexedStack` keeps all branch states in memory simultaneously, even branches the user has never visited. This is intentional for the adaptive shell but means eight branch subtrees are alive at all times. Branches with heavy cubits (an OPAC search with a large result set) need to be written with this in mind - do not load data eagerly in a singleton cubit for a branch the user may never open.
- Tab synchronization is manual: the index in `ShellDestinations` and the branch index in the router are two separate lists that must agree. A test that asserts `ShellDestinations.destinations.length == router.branches.length` costs little and catches the drift.
- `go_router`'s API does evolve; breaking changes landed between v5, v6 and v12. Pin the version in `pubspec.yaml` and review the changelog before upgrading.

## Revisiting

The trigger is a feature that needs truly independent navigation history below a branch - a wizard inside the catalog branch that pushes and pops multiple pages without those pages appearing in the app's URL history. `go_router`'s `ShellRoute` (non-stateful) nests a local navigator but does not preserve state; that use case would likely stay within `go_router` using a local `Navigator` or a nested shell. If deep linking to wizard steps becomes a requirement, that is the moment to re-evaluate.

The auth redirect, when it lands, extends rather than replaces this setup. The only structural question is whether the refresh listenable wraps the auth cubit's stream or its state - `GoRouterRefreshStream` takes any `Stream<Object?>`, and a cubit's stream is exactly that.
