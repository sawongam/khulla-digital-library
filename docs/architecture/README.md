# Architecture

This folder documents how Khulla is built and why it is built that way. It is split into two sections:

- **`decisions/`** - Architecture Decision Records (ADRs). Each file explains a significant technical choice: what the options were, what was decided, and why. Read these to understand the reasoning behind the stack.
- **`guides/`** - Day-to-day reference. Each file explains how to use a specific pattern correctly. Read these while writing code.

If you are new to the codebase, start with the decisions in order - they build on each other. Then keep the guides open as a reference while working on your first feature.

---

## Decisions

The big calls, in the order they were made.

| #                                                      | Title                          | One-liner                                                                      |
| ------------------------------------------------------ | ------------------------------ | ------------------------------------------------------------------------------ |
| [0001](decisions/0001-local-first-flutter.md)          | Local-first Flutter            | No backend, no server, SQLite on the device                                    |
| [0002](decisions/0002-drift-for-persistence.md)        | Drift for persistence          | Type-safe SQLite with compile-checked schema and tested migrations             |
| [0003](decisions/0003-bloc-cubit-for-state.md)         | flutter_bloc (Cubit)           | Immutable states, traceable transitions, testable without a widget tree        |
| [0004](decisions/0004-money-extension-type.md)         | Money as an extension type     | Zero-cost type over minor units - no floats, no ambiguous ints                 |
| [0005](decisions/0005-gorouter-for-navigation.md)      | GoRouter for navigation        | Deep links, persistent shell branches, auth redirect hook                      |
| [0006](decisions/0006-khulla-ui-design-system.md)      | khulla_ui design system        | Separate package enforces the domain-free boundary at compile time             |
| [0007](decisions/0007-feature-folder-structure.md)     | Feature folder structure       | Sub-feature split - each resource owns its full data/domain/presentation stack |
| [0008](decisions/0008-app-exception-error-handling.md) | AppException and guardDatabase | Sealed error hierarchy; driver types never cross the data-source boundary      |
| [0009](decisions/0009-adaptive-layout-shell.md)        | Adaptive layout shell          | One shell, three breakpoints - bottom bar, rail, extended rail                 |
| [0010](decisions/0010-localization-and-assets.md)      | Localization and assets        | ARB-first strings, generated Assets class - no literals anywhere               |
| [0011](decisions/0011-dependency-injection.md)         | Dependency injection           | injectable + get_it, constructor injection only, getIt called in one place     |

---

## Guides

Pattern references for day-to-day development. No particular reading order - open the one relevant to what you are building.

| Guide                                                          | What it covers                                                                                     |
| -------------------------------------------------------------- | -------------------------------------------------------------------------------------------------- |
| [naming-conventions](guides/naming-conventions.md)             | Files, classes, prefixes, cubit methods, routes, ARB keys - the full reference                     |
| [freezed-state-patterns](guides/freezed-state-patterns.md)     | Single-class states, constructor ordering, copyWith with nullables, the error: null convention     |
| [formz-validation](guides/formz-validation.md)                 | FormzInput anatomy, pure/dirty, built-in inputs, state shape, the mark-all-dirty-on-submit pattern |
| [dispose-bag](guides/dispose-bag.md)                           | textController / focusNode factory methods, what DisposeBag doesn't cover                          |
| [sliver-scrolling](guides/sliver-scrolling.md)                 | Why shrinkWrap is banned on unbounded lists, CustomScrollView composition                          |
| [code-generation-pipeline](guides/code-generation-pipeline.md) | The four generators, what is committed vs not, make build vs make migrate order                    |
| [melos-monorepo](guides/melos-monorepo.md)                     | Workspace bootstrap, why dart format from root is wrong, adding a package                          |

---

## Adding a new ADR

Copy this template into `decisions/` as `NNNN-short-title.md` where `NNNN` is the next number:

```markdown
# ADR NNNN - Title

**Status:** Accepted · **Date:** YYYY-MM-DD

## Context

What situation or pressure led to this decision?

## Decision

What was decided, and how does it work?

## Consequences

**What this buys**
**What this costs**

## Revisiting

What would trigger revisiting this decision?
```

ADRs are append-only once accepted. If a decision is superseded, mark the old one with `**Status:** Superseded by [ADR NNNN](NNNN-…)` and reference it from the new one.

## Adding a new guide

Add a file to `guides/` named `kebab-case-topic.md`. Guides have no required structure - use headers that match the content. Update the table above.
