# ADR 0007 - Feature folder structure and the sub-feature split

**Status:** Accepted · **Date:** 2026-09-03

## Context

A library management system has a natural set of resources: titles, copies, authors, subjects, members, loans, fines, reservations, staff accounts. Each resource has its own table, its own queries, its own domain model, and its own UI. Naive feature organization puts all of catalog in one folder - titles, copies, authors and subjects side by side - and lets the data and domain layers grow until no one is sure which file owns which query.

The common response to that drift is a feature-level split: one top-level folder per screen. That works for small features but creates a different problem for a resource like `catalog` that owns several tables and has pages that span resources - a title detail page that shows its copies, or an author page that lists all titles by that author. Where do the cross-resource queries live? In the first feature that needed them? In a shared folder that starts to look like a mini-backend?

Three patterns were evaluated:

**Flat, one folder per screen.** `catalog_title/`, `catalog_copy/`, `catalog_author/`, `catalog_overview/` as siblings under `features/`. Simple to navigate, but cross-resource pages require importing across sibling folders. The `catalog` namespace appears in every folder name with no hierarchy to express the grouping.

**Deep, one folder per resource, all data hoisted.** `features/catalog/` with a shared `data/` and `domain/` at the root, and `presentation/` sub-folders per resource. The shared data layer seems convenient until a second developer needs to add a query - they reach for the shared folder, which now owns queries for titles, copies, and authors with no clear boundary on what belongs there.

**Sub-feature split: one folder per resource under a feature root, each sub-feature carrying its own full stack.** `features/catalog/title/`, `features/catalog/copy/`, `features/catalog/author/`, each with its own `data/`, `domain/`, and `presentation/`. Cross-resource coordination lives under `catalog/shared/`, which by construction contains only things that span sub-features, not things that one sub-feature grabbed for convenience.

The third pattern was chosen because it makes the boundary machine-readable: a symbol from `features/catalog/title/data/` reaching into `features/catalog/copy/domain/` is a cross-sub-feature import that can be tracked and questioned. The shared folder earns its contents; it does not accumulate them by default.

## Decision

Organize code under `features/` using a **two-level hierarchy**: a feature folder for each domain area, and sub-feature folders under it for each owned resource.

### Single-step feature (no sub-features)

A feature that owns one resource or one flow uses the flat presentation-first shape:

```
features/dashboard/
└── presentation/
    ├── cubit/
    │   ├── dashboard_cubit.dart
    │   └── dashboard_state.dart
    ├── pages/
    │   └── dashboard_page.dart
    └── widgets/
        ├── dashboard_stats_card.dart
        └── dashboard_recent_loans.dart
```

`data/` and `domain/` are added only when the feature needs a database query or a domain model. Starting without them is not a placeholder - it is the correct state for a feature that renders pre-loaded data from another cubit.

### Multi-step flow (one step per folder)

A flow with multiple steps nests one folder per step inside `presentation/`. Each step owns its cubit, its page, and its widgets:

```
features/staff_auth/presentation/
├── auth/                        # session cubit - no page
│   └── cubit/
│       ├── auth_cubit.dart
│       └── auth_state.dart
├── sign_in/
│   ├── cubit/
│   │   ├── sign_in_cubit.dart
│   │   └── sign_in_state.dart
│   ├── sign_in_page.dart
│   └── widgets/
│       └── sign_in_form.dart
├── forgot_password/
│   ├── cubit/
│   └── forgot_password_page.dart
└── widgets/                     # shared across steps in this flow only
    └── auth_logo_header.dart
```

A single-step feature drops the step folder and puts the page at the `presentation/` root.

### Sub-feature split (multiple owned resources)

When a feature owns multiple tables, it splits into sub-features. Each sub-feature has its own complete `data/`/`domain/`/`presentation/` stack. Nothing is hoisted to the feature root except what genuinely spans sub-features:

```
features/catalog/
├── shared/
│   ├── domain/
│   │   └── catalog_constants.dart    # ISBN format, call number max length, etc.
│   └── presentation/
│       ├── placeholder/
│       │   └── catalog_placeholder.dart
│       └── widgets/                  # domain-free UI only - no imports of Title, Copy…
│           ├── catalog_cover_image.dart
│           └── catalog_filter_chip.dart
├── title/
│   ├── data/
│   │   ├── mappers/
│   │   │   └── title_row_mappers.dart
│   │   ├── tables/
│   │   │   └── titles.dart
│   │   ├── title_local_data_source.dart
│   │   └── title_repository_impl.dart
│   ├── domain/
│   │   ├── models/
│   │   │   └── title.dart
│   │   └── title_repository.dart
│   └── presentation/
│       ├── cubit/
│       │   ├── title_cubit.dart
│       │   └── title_state.dart
│       ├── pages/
│       │   ├── title_detail_page.dart
│       │   └── title_list_page.dart
│       └── widgets/
│           ├── title_list_tile.dart
│           └── title_isbn_chip.dart
├── copy/
│   ├── data/ …
│   ├── domain/ …
│   └── presentation/ …
├── author/
│   ├── data/ …
│   ├── domain/ …
│   └── presentation/ …
└── catalog/
    └── presentation/
        └── pages/
            └── catalog_page.dart    # overview - no resource of its own
```

The `catalog/catalog/` nesting is intentional and worth naming. The overview page is part of the `catalog` feature but is not a sub-feature - it owns no resource. It lives in its own minimal folder to make the structure consistent rather than floating at the feature root.

### Rules that fall out of the structure

**Sub-features may import each other.** `copy/` querying the `title/` repository to display a title's copies is expected. The dependency is within the feature boundary.

**Cross-resource cascades live in `shared/presentation/`, not in individual cubits.** A checkout that updates loan records, member standing, and copy availability is not the responsibility of `loan/cubit/`, `member/cubit/`, and `copy/cubit/` independently broadcasting changes. The cascade lives in a coordinator under `catalog/shared/presentation/` (or `circulation/shared/presentation/`), where the scope is explicit.

**`shared/presentation/widgets/` is for UI with no domain imports.** A widget that imports `Title` or `Copy` belongs in a sub-feature's `presentation/widgets/`, not in the shared folder. The shared folder contains layout primitives, chips, and cards whose data is passed in as plain `String` or `int` - not as domain models.

**Never import another feature's `presentation/widgets/`.** `features/members/` reaching into `features/catalog/title/presentation/widgets/TitleListTile` for a display - even a read-only one - is a cross-feature UI coupling. If the widget is genuinely needed in two features, it graduates to `shared/components/` (if it carries domain knowledge) or `shared/widgets/` (if it does not).

**`placeholder/` is its own folder, not `widgets/`.** Mock data and preview models for development go in `presentation/placeholder/`, not beside production widgets. This makes it easy to `grep` for placeholder usage before a release.

### The `data/` layer stack

Every sub-feature that owns a table follows the same vertical path:

```
domain/<name>_repository.dart            - abstract interface class
domain/models/<name>.dart                - freezed domain model
data/<name>_repository_impl.dart         - @LazySingleton(as: <Name>Repository)
data/local_<name>_data_source.dart       - @LazySingleton(as: <Name>LocalDataSource)
data/mappers/<name>_row_mappers.dart     - toDomain() on drift rows, toCompanion() on writes
data/tables/<name>s.dart                 - drift Table class
```

A generated drift row class (`TitleData`, `CopyData`) never leaves `data/`. Mappers convert it to the domain model at the data-source boundary. The domain model is a `freezed` class with no drift imports.

## Consequences

**What this buys**

- Every symbol has exactly one right place. The question "where does this go?" has a rule-based answer, not a judgment call.
- `data/` and `domain/` of sub-feature A are invisible to sub-feature B's presentation layer at the import level. A linter rule (`always_use_package_imports`, directory-scoped) could enforce this statically; code review enforces it today.
- `shared/` earns its contents through promotion, not accumulation. A reviewer can ask "why is this in shared?" and the answer is always "because two sub-features need it."
- Adding a new resource to an existing feature (adding `subjects` to `catalog`) is mechanical: create the folder, follow the template, register the table. No existing structure changes.

**What this costs**

- The `data/`/`domain/`/`presentation/` full stack for a small resource is six to eight files before a query has been written. For a feature with a single table and a list page, that is boilerplate. It is also the correct structure - starting shallow (presentation-first, no data layer) and graduating is the mitigation, not a smaller structure.
- The `catalog/catalog/presentation/pages/` path for the overview page is awkward to read. The alternative - putting the overview page at `catalog/presentation/pages/` - blurs the boundary between the feature root and a sub-feature. The consistent rule is worth the odd path.
- Cross-sub-feature cascades in `shared/presentation/` require a coordinator that spans two cubits. That coordinator is more code than a direct call from one cubit to another. It is also the only way to express "this operation spans resources" without either cubit knowing about the other - which is the coupling the structure exists to prevent.

## Revisiting

The sub-feature split triggers when a feature owns more than one table. A feature that grows a second table without splitting accumulates exactly the shared-data-layer problem this structure was designed to avoid. The trigger to merge sub-features back is a feature that was over-split - two sub-features that always change together, always query together, and have no independent callers. That has not happened yet, but the merge is mechanical: collapse the two folders into one and update imports.
