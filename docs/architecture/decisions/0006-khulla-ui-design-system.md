# ADR 0006 - Design system as a separate package (`khulla_ui`)

**Status:** Accepted · **Date:** 2026-09-03

## Context

Every Flutter app eventually accumulates UI primitives that drift from app to app: buttons with slightly different border radii, text styles that share a name but not a value, color literals sprinkled across a hundred widget files. For a project with multiple contributors, that drift compounds. Two features that look identical on a Figma frame diverge silently because each developer copied a color from a slightly different source.

There is a sharper problem specific to this app. The eventual plan is a public OPAC (catalog reader) that looks and feels different from the staff interface but shares the same visual language - same button shapes, same typography scale, same color system. If tokens are embedded in `lib/`, extracting them later means hunting down every `Color(0xFF1B4F72)` across hundreds of files. If they are in a separate package from the start, the second app is a new consumer of an already-isolated system.

The specific pressures that made separation the right call before the first feature existed:

- **Hex colors as magic literals** are the canonical case. A single `#1B4F72` written directly into a widget is a token without a name - its meaning (primary brand blue? an error background? a disabled state?) is invisible at the call site. If it needs to change, every instance must be found and changed by hand, and `grep` cannot guarantee completeness.
- **Spacing and radius values** have the same problem. A `BorderRadius.circular(8)` is not self-documenting. Is 8dp the card radius, the button radius, or a coincidence?
- **Component knowledge leaking into primitives.** A `Button` widget that imports a `Loan` domain model to format its label is not a primitive - it is a feature widget masquerading as one. The design system should compile without knowing that a book or a member exists.

The alternative - keeping tokens in a well-named file within `lib/` - was considered and rejected. The file boundary is a convention, not a compiler enforced rule. Any developer can import the wrong file. A separate pub package is a compiler-enforced boundary: `khulla_ui` cannot import `package:khulla/...` without a circular dependency, and a linter that runs on the package independently will catch the violation before it reaches the repo.

## Decision

Maintain the design system as a **separate Melos package** at `packages/khulla_ui`. The app imports `package:khulla_ui/khulla_ui.dart` for every primitive widget and token accessor. `khulla_ui` never imports `package:khulla/...`.

### What lives in `khulla_ui`

Everything that could exist in another app with the same brand belongs here:

- **`app_palette.dart`** - the only file in the entire repository allowed to contain a hex color. It is internal to the package (`src/theme/`), never exported. The rest of the package reads from the palette; the app never sees it.
- **Theme extensions** - `AppColors`, `AppSpacing`, `AppRadius`, `AppShadow`, `AppTypography` - registered in `AppTheme.light` and `AppTheme.dark` and consumed via `context.appColors`, `context.appSpacing`, etc.
- **Primitive widgets** - `AppButton`, `AppTextField`, `AppNavRail`, `AppNavBar`, `AppTopBar`, `AppEmptyView`, `AppErrorView`, `AppCard`, `AppDialog`. Each class is prefixed with `App`. This prefix is reserved - it must not appear in app or feature code.
- **Component contracts.** `AppErrorView` takes a `String message`, not an `AppException`. `AppEmptyView` takes a `String label`, not a localization key. The translation happens in the app, before the call: `AppErrorView(message: context.l10n.somethingFailed)`. The design system takes ready-made strings and knows nothing about exceptions or localizations.

### What does not live in `khulla_ui`

- **Domain models.** A widget that imports `Title`, `Loan`, `Member` or any other domain class goes in `shared/components/` or the owning feature's `presentation/widgets/`, not in the design system.
- **`AppException` or `l10n`.** See the contract above. `ErrorRetryView` (in `shared/components/`) resolves the exception and the retry label, then calls `AppErrorView`. `EmptyResultView` (same location) resolves the localized string and calls `AppEmptyView`. This split is the mechanism that keeps the design system domain-free.
- **Hard-coded spacing, color, or radius.** A widget in `khulla_ui` that writes `const EdgeInsets.all(16)` instead of `context.appSpacing.md` is violating the token contract. All values come from the theme.

### Token access pattern

Tokens are read from the theme, not from static constants:

```dart
// Correct - reads the live theme, supports dark mode and density changes
final spacing = context.appSpacing;
final colors  = context.appColors;
final radius  = context.appRadius;

// Wrong - bypasses the theme, cannot respond to dark mode
const color = AppPalette.brand500;   // AppPalette is internal and unexported
```

`context.appSpacing` and its siblings are extension getters on `BuildContext` in `khulla_ui`. They call `Theme.of(context).extension<AppSpacing>()!` and throw a named exception if the extension is not registered - a missing `AppTheme.light` in the widget tree is a programmer error, and a meaningful assertion beats a null cast.

### The UI placement rule

The design system is not a catch-all for widgets. The rule is a single question:

> Could this widget exist in another app with the same brand, with no library-domain knowledge?

| Answer                                   | Location                                |
| ---------------------------------------- | --------------------------------------- |
| Yes                                      | `packages/khulla_ui`                    |
| No - generic, no domain                  | `shared/widgets/`                       |
| No - library-domain, used in 2+ features | `shared/components/`                    |
| No - library-domain, one feature only    | `features/<name>/presentation/widgets/` |

Promotion works upward, never the reverse. A widget starts in the feature that needs it. When a second feature needs it, it moves to `shared/components/`. If it turns out to be domain-free, it moves to `shared/widgets/` or `khulla_ui`. Moving a widget into `khulla_ui` requires removing its domain imports, which is the audit that makes the promotion meaningful.

## Consequences

**What this buys**

- The compiler enforces the domain boundary. `khulla_ui` importing a `Loan` class is a circular dependency; `pub get` refuses it.
- `app_palette.dart` is the one file to find and edit when a brand color changes. `grep` on a hex value returns exactly one result in the entire repository.
- The design system can be analyzed and tested in isolation. `make check` runs `dart analyze` on each Melos package separately; a lint failure in `khulla_ui` surfaces as a package-level failure with a clear path.
- Dark mode, high-contrast mode, or a second theme can be added by implementing a second `AppColors` extension - no widget changes required.
- When a second app (a standalone OPAC, a mobile catalog reader) is built, it installs `khulla_ui` as a path or git dependency and gets the full design system for free.

**What this costs**

- Melos bootstrap is required before the first `flutter pub get`. A contributor who clones and runs `flutter pub get` in the root gets errors on `package:khulla_ui` imports. `dart run melos bootstrap` is the first command in every setup doc and in the README - it is also how the Flutter team structures multi-package repos, so contributors who have worked on plugin repos will recognize the pattern.
- A widget that starts in a feature and graduates to `khulla_ui` must be stripped of domain imports before it moves. That is not a cost; it is the audit. It is worth naming because contributors sometimes ask why they cannot just move the file.
- The `App`-prefix reservation makes naming explicit. A developer who names a feature widget `AppMemberCard` gets an analyzer warning from `avoid_app_prefix_on_non_design_system_widgets` (or, failing a lint, a code review comment). That is friction worth having.

## Revisiting

The trigger to merge `khulla_ui` back into `lib/` is a codebase that is always a single app, will never share its design system, and finds the Melos bootstrap overhead net-negative. That is not the current trajectory - the OPAC and possible mobile reader both benefit from the separation. The trigger to extract a _second_ design-system package (a `khulla_ui_opac`) is a second app whose visual language diverges significantly from the staff interface. At that point both packages depend on a shared token foundation, which might justify a third `khulla_tokens` package; that is a future decomposition, not a current problem.
