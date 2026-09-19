# ADR 0009 - Adaptive layout shell

**Status:** Accepted · **Date:** 2026-09-03

## Context

Khulla targets Windows (a typical desk machine at 1280px or wider), web (anything from a phone browser at 390px to a widescreen monitor), and eventually mobile (360–428px wide). The navigation structure has eight top-level sections. A bottom navigation bar fits four or five items before it becomes unusable. A navigation drawer is one tap further than a rail and collapses the available content area on desktop. Three different navigators - one per platform - means three code paths and three maintenance burdens.

The choices considered:

**Platform-specific navigators.** Detect `Platform.isWindows` or `kIsWeb` and render entirely different shells. Simple to reason about in isolation, brittle in practice: a web user on a 1440px monitor gets the same bottom bar as a user on a phone. The mismatch is wrong, and fixing it requires branching on both platform _and_ window width, at which point the platform branch bought nothing.

**Always bottom bar.** A bottom bar with a "More" sheet works at any width, including desktop. This is what many apps do. It is wrong for a desk machine: a navigation rail at 1280px gives every section a one-tap target and wastes no horizontal space.

**Always navigation drawer.** A Material 3 navigation drawer is appropriate at wide widths but is a persistent extra tap on every narrow screen. It is also not what users of desk software expect - they expect a persistent sidebar.

**Single adaptive shell, breakpoint-driven.** One shell widget that changes its navigation component based on window width, using a `formFactor` abstraction over `MediaQuery.sizeOf`. This is the Flutter team's recommended approach for apps that genuinely target multiple form factors, and it is what `AppShell` implements.

## Decision

Use a **single adaptive shell** - `app/shell/app_shell.dart` - that renders one of three navigation layouts based on window width:

| `FormFactor` | Width range  | Navigation component                            |
| ------------ | ------------ | ----------------------------------------------- |
| `compact`    | < 600px      | `AppNavBar` (bottom bar) + `showShellMoreSheet` |
| `medium`     | 600px–1199px | `AppNavRail` (side rail, icons only)            |
| `expanded`   | ≥ 1200px     | `AppNavRail` extended (icons + labels)          |

### `FormFactor` and reading it

`FormFactor` is a three-value enum in `packages/khulla_ui`. `context.formFactor` is a `BuildContext` extension that reads it from a `FormFactorProvider` set at the root by the shell, based on `MediaQuery.sizeOf(context).width`.

**Never use a raw `MediaQuery` width inside a component.** A component that reads `MediaQuery.sizeOf(context).width` and compares it to `600` is duplicating the breakpoint logic in a call site that will not update if the breakpoints change. Read `context.formFactor` for window-level decisions.

**Use `LayoutBuilder` inside a component that adapts to its slot, not to the window.** A card that renders a two-column layout when it has enough horizontal space does not care about the window - it cares about its own width. `LayoutBuilder` gives it that; `MediaQuery` gives it the wrong thing.

### `AppTopBar`

Every width has `AppTopBar` above the content area - title, breadcrumbs, search, notifications, account chip. It is placed outside the page's scroll view at the shell level, which makes it sticky without any page needing to opt in. A page **must not** draw its own title row; the shell owns that space.

### `AppNavBar` and the `More` sheet

At compact width, `AppNavBar` shows the four `primary` destinations. All other destinations are reachable through a "More" item that opens `showShellMoreSheet` - a bottom sheet listing the remaining sections. This keeps the bar uncluttered while making every section reachable without a drawer.

The `primary` flag lives in `ShellDestination`:

```dart
// app/shell/widgets/shell_destinations.dart
const destinations = [
  ShellDestination(label: 'Dashboard', icon: …, primary: true),
  ShellDestination(label: 'Catalog',   icon: …, primary: true),
  ShellDestination(label: 'Circulation', icon: …, primary: true),
  ShellDestination(label: 'Members',   icon: …, primary: true),
  ShellDestination(label: 'OPAC',      icon: …, primary: false),
  ShellDestination(label: 'Reports',   icon: …, primary: false),
  ShellDestination(label: 'Staff',     icon: …, primary: false),
  ShellDestination(label: 'Settings',  icon: …, primary: false),
];
```

If the `primary` distribution needs to change - e.g., circulation grows in importance and OPAC is demoted - it is a one-field change in this list, with no router or page changes required.

### `shell_destinations.dart` as single source of truth

`shell_destinations.dart` is the authoritative list for navigation. Index `i` in that list corresponds to `StatefulShellBranch` `i` in `AppRouter`. These two lists must stay in sync: adding a destination means adding an entry in `shell_destinations.dart` **first**, then adding the matching `StatefulShellBranch` to `AppRouter`. Reversing the order leaves the router with a branch that no destination points to.

The shell reads from `shell_destinations.dart`; the router reads its own branch list. They are not derived from each other at compile time. A test that asserts `destinations.length == router.configuration.branches.length` catches a mismatch before it becomes a navigation bug at runtime.

### `AppNavRail`

At medium and expanded widths, `AppNavRail` replaces the bottom bar. It shows all eight destinations, no overflow sheet. At expanded width it adds text labels beside each icon. The transition is handled by the shell based on `context.formFactor` - no page is aware of it.

`AppNavRail` is in `packages/khulla_ui`. It takes a list of `AppNavDestination` objects (label, icon, selectedIcon) and a current index. It does not know about `ShellDestination` or `GoRouter`.

### No `if (kIsWeb)` or `Platform.*` in the shell

The shell adapts to window width, not to the platform. A web user on a 1440px monitor sees the extended rail; a Windows user who resizes the window below 600px sees the bottom bar. This is intentional - the form factor is a property of the window, not the OS. Every platform check would need to be cross-referenced with a width check anyway, making the platform check noise.

The only code path that legitimately branches on platform is `database_platform.dart` (file location, WAL) and `window_setup.dart` (window management on native). Neither is in the shell.

## Consequences

**What this buys**

- One shell to maintain, not three. Adding a ninth section means updating `shell_destinations.dart` and `app_router.dart` - not one file per platform.
- A Windows user on a narrow window gets the mobile layout; a web user on a wide monitor gets the desktop layout. The form factor matches what the user sees, not what the developer assumed about their device.
- `AppTopBar` is guaranteed to be present at all widths. Pages cannot accidentally omit it or duplicate it.
- Design tokens drive the breakpoints. Changing `600px` or `1200px` means changing the values passed to `FormFactorProvider`, not hunting for raw numbers across widget files.

**What this costs**

- `StatefulShellRoute.indexedStack` keeps all eight branch subtrees alive simultaneously. This is correct for persistent navigation state but means eight branch root widgets are in the tree even on a phone. Cubits that would load eagerly on creation need to defer their loads until the page is visible - `LoadStatus.initial` as the starting state, with the cubit load triggered by the page's `initState` or `didChangeDependencies`, not by the cubit's constructor.
- The bottom bar's four-primary-item limitation is a design constraint, not a technical one. If a product decision adds a ninth section with `primary: true`, one of the existing primary items must become secondary or the bar overflows. That is a future product conversation, not a code problem - the structure supports it either way.
- `shell_destinations.dart` and `AppRouter`'s branch list being two separate lists is a source of drift. The test that asserts their lengths is cheap and should be written early.

## Revisiting

The trigger is a product decision to support a layout that the three-level breakpoint model cannot express - a tablet-split view where the list and detail pane sit side by side on medium widths, for instance. That is a per-page layout change, not a shell change: the shell continues to provide the navigation rail, and the page uses `LayoutBuilder` to decide whether to show one or two panes. If the split view spans features and becomes a cross-cutting concern, a second shell variant (a `TwoPaneShell`) is the natural extension - the routing decision for which shell to use based on the current route and form factor would live in `AppRouter`.
