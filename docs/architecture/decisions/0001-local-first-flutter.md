# ADR 0001 - A local-first Flutter app, not a web stack

**Status:** Accepted · **Date:** 2026-08-29

## Context

The original plan was three moving parts: a NestJS API, a Next.js frontend, and an Electron wrapper to hand end users something installable. `docs/architecture/backend-architecture.md` describes that API in detail and predates this decision.

That plan carries costs a small library cannot absorb:

- **Three runtimes to build and ship.** A Node server, a browser bundle, and a Chromium wrapper - each with its own build, its own dependency tree, and its own way to break.
- **A server to host.** Someone has to run Postgres and keep it running. For a school or community library, that is a recurring bill and a recurring outage.
- **A network dependency at the desk.** Circulation has to work at 9am whether or not the connection does.
- **Data leaving the building.** Circulation records - who borrowed what, and when - are exactly the kind of data that should not sit on someone else's server by default.

## Decision

Build a single **local-first Flutter application**. The catalogue lives in SQLite on the user's own machine. There is no backend.

- **Windows and web are the primary targets**; Linux, macOS, Android and iOS build from the same source.
- **Persistence is `sqflite`**, over three backends behind one API: the platform channel on mobile, `dart:ffi` on desktop, and SQLite compiled to WebAssembly on web. _(Superseded by [ADR 0002](0002-drift-for-persistence.md): drift over sqlite3, same three targets, before any schema had shipped. Everything else in this ADR stands, including the promise that a downgrade refuses to open.)_
- **The repository root is the app.** With one application and no server, nesting it under `apps/` buys nothing. The `apps/api`, `apps/web`, `docker-compose.yml` and Docker scripts from the previous plan were removed.

## Consequences

**What this buys**

- One codebase, one build system, one language for every target.
- Installation is a copy of an executable. No hosting, no accounts, no migration path to worry about when funding changes.
- The app works offline because there is no online.
- Flutter's rendering is identical across platforms, so the desktop build and the web build genuinely look the same.

**What this costs**

- **No multi-device sync.** Two machines are two libraries. Adding sync later means a server after all, and the repository layer is where that seam would go - a `RemoteDataSource` alongside the local one, with presentation untouched.
- **Backup is the operator's problem.** A single SQLite file is easy to copy, which is a feature, but nothing copies it automatically yet. Export and backup are the first non-catalogue features worth building.
- **Web storage is per-browser.** The IndexedDB-backed database belongs to one browser profile on one machine. The web build is best understood as a convenient reader and second terminal, not the system of record.
- **No concurrent multi-user access.** SQLite handles concurrent readers on one machine; it does not make two librarians on two machines share a catalogue.

## Revisiting

The trigger to revisit is a library that genuinely needs more than one workstation writing to the same catalogue. At that point the repository interfaces already exist, `docs/architecture/backend-architecture.md` is still a reasonable starting point for the server, and this app becomes its offline-capable client rather than being rewritten.
