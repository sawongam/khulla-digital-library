# Docs

Everything you need to understand, contribute to, and build on Khulla.

```
docs/
├── architecture/      How the app is built and why - ADRs and pattern guides
├── database/          The data layer explained - schema, migrations, how-to
└── contributing/      Setup, conventions, PR flow
```

---

## Where to start

**New to the codebase?** Read in this order:

1. [`../README.md`](../README.md) - what Khulla is, how to get it running
2. [`architecture/`](architecture/README.md) - how the codebase is organized and the rules for working in it: the eleven decisions that shaped the stack, then the guides as you need them
3. [`contributing/`](contributing/README.md) - branch conventions, commit format, PR flow

**Looking for something specific?**

| I want to…                                  | Go to                                                                                                                                                |
| ------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------- |
| Understand why there's no backend           | [ADR 0001 - Local-first Flutter](architecture/decisions/0001-local-first-flutter.md)                                                                 |
| Understand the database setup               | [ADR 0002 - Drift](architecture/decisions/0002-drift-for-persistence.md) · [Database overview](database/overview.md)                                 |
| Add a table or column                       | [Database guide](database/guide.md)                                                                                                                  |
| Understand state management                 | [ADR 0003 - Cubit](architecture/decisions/0003-bloc-cubit-for-state.md) · [freezed patterns](architecture/guides/freezed-state-patterns.md)          |
| Handle money amounts                        | [ADR 0004 - Money](architecture/decisions/0004-money-extension-type.md)                                                                              |
| Add a route                                 | [ADR 0005 - GoRouter](architecture/decisions/0005-gorouter-for-navigation.md)                                                                        |
| Build a UI component                        | [ADR 0006 - Design system](architecture/decisions/0006-khulla-ui-design-system.md) · [Naming conventions](architecture/guides/naming-conventions.md) |
| Add a feature or sub-feature                | [ADR 0007 - Feature structure](architecture/decisions/0007-feature-folder-structure.md)                                                              |
| Handle errors from the database             | [ADR 0008 - AppException](architecture/decisions/0008-app-exception-error-handling.md)                                                               |
| Write a form with validation                | [formz guide](architecture/guides/formz-validation.md)                                                                                               |
| Build a scrollable list page                | [Sliver scrolling guide](architecture/guides/sliver-scrolling.md)                                                                                    |
| Wire up dependencies                        | [ADR 0011 - DI](architecture/decisions/0011-dependency-injection.md)                                                                                 |
| Run code generation                         | [Code generation guide](architecture/guides/code-generation-pipeline.md)                                                                             |
| Understand the monorepo setup               | [Melos guide](architecture/guides/melos-monorepo.md)                                                                                                 |
| Open a pull request                         | [Contributing](contributing/README.md)                                                                                                               |
| Cut a release, or send someone a test build | [Releasing](contributing/releasing.md)                                                                                                               |

---

## Folder map

### `architecture/`

Technical decisions and patterns. Split into:

- **`decisions/`** - ADRs. Why the stack looks the way it does. Numbered and append-only.
- **`guides/`** - How-to references. How to use the patterns correctly day-to-day.

See [`architecture/README.md`](architecture/README.md) for the full index and instructions for adding new docs.

### `database/`

- [`overview.md`](database/overview.md) - a walkthrough of every database file: what it does, why it's there, how it connects
- [`guide.md`](database/guide.md) - how to add tables, write queries, run migrations, and remove things safely
- [`schema.md`](database/schema.md) - the visual schema: generated Mermaid ER diagram (`make db-diagram`)

### `contributing/`

- [`README.md`](contributing/README.md) - setup, code conventions, branch and commit rules, how to open a PR
- [`releasing.md`](contributing/releasing.md) - the CI workflows, cutting a tagged release, sending someone a test build
