# Khulla Digital Library

An open-source library management system, built as a **local-first Flutter app**. Your catalogue lives in a SQLite database on your own machine — no server to run, no account to create, no data leaving the building.

*Khulla* (खुल्ला) is Nepali for "open".

**[khulladigitallibrary.com](https://khulladigitallibrary.com)** · **[Try it in your browser](https://app.khulladigitallibrary.com/)**

## What it does

- **Dashboard** — overdue, due today and inventory at a glance.
- **Catalog** — titles, physical copies and printable spine/barcode labels.
- **Circulation** — check-out, returns, active loans, holds queue and fines.
- **Members** — patron registry with member types.
- **Reports** — circulation insights.
- **Staff & roles** — local accounts with per-section view/manage permissions.
- **Settings** — library profile, loan rules, appearance, and backup export/restore.
- **Guide** — an in-app manual, available offline.

## Screenshots

<table>
  <tr>
    <td width="50%" align="center">
      <img src="docs/screenshots/dashboard.png" alt="Dashboard" />
      <br />
      <sub><b>Dashboard</b> — overdue, due today & inventory at a glance</sub>
    </td>
    <td width="50%" align="center">
      <img src="docs/screenshots/catalog.png" alt="Catalog" />
      <br />
      <sub><b>Catalog</b> — titles, copies & availability</sub>
    </td>
  </tr>
  <tr>
    <td width="50%" align="center">
      <img src="docs/screenshots/checkout.png" alt="Checkout" />
      <br />
      <sub><b>Checkout</b> — circulation desk</sub>
    </td>
    <td width="50%" align="center">
      <img src="docs/screenshots/loans.png" alt="Loans" />
      <br />
      <sub><b>Loans</b> — active & overdue</sub>
    </td>
  </tr>
  <tr>
    <td width="50%" align="center">
      <img src="docs/screenshots/members.png" alt="Members" />
      <br />
      <sub><b>Members</b> — patron registry</sub>
    </td>
    <td width="50%" align="center">
      <img src="docs/screenshots/reports.png" alt="Reports" />
      <br />
      <sub><b>Reports</b> — circulation insights</sub>
    </td>
  </tr>
  <tr>
    <td width="50%" align="center">
      <img src="docs/screenshots/barcode.png" alt="Barcodes" />
      <br />
      <sub><b>Barcodes</b> — print & scan</sub>
    </td>
    <td width="50%" align="center">
      <em><a href="https://app.khulladigitallibrary.com/">Try the live demo →</a><br />no install, data stays in your browser</em>
    </td>
  </tr>
</table>

## Download

Ready-to-run builds are attached to every release: **[latest release](https://github.com/sawongam/khulla-digital-library/releases/latest)**.

| Platform | File | How to run it |
| --- | --- | --- |
| Windows | `khulla-<version>-windows-x64-setup.exe` | **Recommended.** Run the installer — Start Menu entry + uninstaller, no admin required. SmartScreen warns about an unknown publisher because the build is unsigned — *More info* → *Run anyway*. |
| Windows (portable) | `khulla-<version>-windows-x64.zip` | Unzip anywhere and run `khulla.exe`. Same app, without an installer. |
| Android | `khulla-<version>-android.apk` | Sideload it, allowing installs from your browser or file manager. It is one universal APK signed with debug keys — fine for sideloading, not for Google Play. |
| Web | `khulla-<version>-web.tar.gz` | Serve the extracted folder from any static host. |
| Linux | `khulla-<version>-linux-x64.tar.gz` | Extract and run `./khulla`. |

Verify a download against `SHA256SUMS.txt` attached to the same release. The installer and portable zip share the same data location, so you can switch between them.

### System requirements

- **Windows:** 10 or 11, 64-bit.
- **Linux:** a distribution with the GTK 3 runtime installed.
- **Android:** sideloading with installs from unknown sources allowed.
- **Web:** a current Chromium, Firefox or Safari.

You can also **[try it in a browser](https://app.khulladigitallibrary.com/)** — a demo with no server behind it, where the catalogue lives in that browser's storage and clearing site data wipes it.

Your catalogue is a SQLite file on your own machine, so uninstalling does not delete it and nothing is uploaded anywhere. Take a backup from **Settings → Backup** before moving between machines; on a new machine, choose Restore during setup to adopt that backup.

## Why local-first

A small library's catalogue is not big data — it is a few thousand rows that must be available at the circulation desk at 9am whether or not the internet is. Running it out of a local database means no hosting bill, no outage, no migration when a grant runs out, and no third party holding a record of who borrowed what.

The same codebase compiles to a Windows executable and to a web app, so a library can install it on the desk machine and still open the catalogue from a browser on the floor.

## Platforms

| Target | Status | SQLite backend |
| --- | --- | --- |
| Windows | Primary, released | drift on a background isolate, over bundled SQLite |
| Web | Primary, released | drift over SQLite in WebAssembly, in a worker |
| Android | Released | drift on a background isolate |
| Linux | Released | drift on a background isolate |
| macOS, iOS | Builds, not released | drift on a background isolate |

Releases are built by CI for the four released targets. macOS and iOS compile from the same source but are not published — both need an Apple Developer account to produce anything a user can open. See [docs/contributing/releasing.md](./docs/contributing/releasing.md).

## Getting started

**Prerequisites** — [FVM](https://fvm.app) to pin the Flutter SDK, plus platform toolchains: Visual Studio with the *Desktop development with C++* workload for Windows; `clang`, `cmake`, `ninja-build`, `libgtk-3-dev` for Linux; Xcode for macOS/iOS; Java 17 plus the Android SDK for the APK.

```sh
git clone https://github.com/sawongam/khulla-digital-library.git
cd khulla-digital-library

dart pub global activate fvm   # once, if you do not have FVM yet
fvm install                    # downloads the SDK pinned in .fvmrc
make bootstrap                 # resolve deps and link local packages
make build                     # generate code (freezed, injectable, assets)
make localize                  # generate localizations

make run-windows               # or: make run-web, make run-linux
```

The Flutter version is pinned in `.fvmrc`. After pulling a change that bumps it, run `fvm install`.

Generated sources are not committed, so `make build` and `make localize` are required on a fresh clone before anything will analyze or run.

## Repository structure

```
khulla-digital-library/
├── lib/
│   ├── app/              # Root widget, router, adaptive navigation shell
│   ├── bootstrap.dart main_dev.dart main_prod.dart
│   ├── core/             # DI, database, errors, routing, logging, window
│   ├── features/         # One folder per feature
│   ├── gen/ l10n/        # Generated code and localization (ARB source of truth)
│   └── shared/           # Cross-feature models, widgets, components
├── packages/
│   └── khulla_ui/        # Design system — tokens, theme, primitives
├── assets/               # Icons and images
├── docs/
│   ├── architecture/     # Design decisions and ADRs
│   ├── database/         # Data layer: overview, how-to, schema diagram
│   └── contributing/     # How to contribute
├── test/                 # Unit, migration and widget tests
├── android/ ios/ linux/ macos/ web/ windows/
├── melos.yaml            # Workspace scripts
└── Makefile              # Everyday commands
```

## Common commands

| Command | What it does |
| --- | --- |
| `make bootstrap` | Resolve dependencies across the workspace |
| `make build` | Run code generation |
| `make localize` | Regenerate localizations from `lib/l10n/arb/` |
| `make migrate` | Regenerate migrations after a table change + `schemaVersion` bump |
| `make check` | Format, copyright, analyze and test — run this before a PR |
| `make ci` | The same gates CI runs, failing on unformatted code instead of rewriting it |
| `make run-web` / `run-windows` / `run-linux` | Run the dev flavor |
| `make build-web` / `build-windows` / `build-linux` / `build-apk` | Release builds |

## Architecture

The full guide lives in [docs/architecture](./docs/architecture/) — folder conventions, the data-layer stack, migration rules, state management, and naming. In short:

- **State** — `flutter_bloc` cubits with single-class `freezed` states and `formz` inputs.
- **Data** — `Page → Cubit → Repository → LocalDataSource → AppDatabase → SQLite`. Driver errors are converted to a small sealed `AppException` set at the data-source boundary.
- **Schema** — append-only migrations on a hardcoded `schemaVersion`. A database written by a newer build refuses to open rather than being deleted.
- **Design system** — `khulla_ui` holds every token; `app_palette.dart` is the only file in the repository allowed to contain a hex color.
- **Layout** — one adaptive shell: a bottom bar below 600px, a navigation rail above, extended with labels at 1200px.

## Contributing

Contributions are welcome. See [docs/contributing](./docs/contributing/) for setup, conventions and the pull-request flow.

Commits follow a conventional format — `type(scope): message` with types `feat`, `fix`, `chore`, `refactor`, `sync`, `ci` — enforced by a git hook. Branch off `dev`; direct commits to `dev` and `prod` are blocked.

Found a bug? Open an issue with the platform, the version from Settings → About, and steps to reproduce. For anything security-sensitive, use private vulnerability reporting instead — see [SECURITY.md](./SECURITY.md).

Merging into `prod` publishes a release at the version in `pubspec.yaml` and redeploys the web demo — see [releasing](./docs/contributing/releasing.md).

## License

Khulla is dual-licensed:

- **[AGPL-3.0-only](./LICENSE)** — free for everyone. Libraries, schools and NGOs can install, use, change and share it at no cost. If you distribute a modified version, or run one as a hosted service, you must publish its source under the same licence.
- **Commercial licence** — for selling Khulla as closed software, white-labelling it, or offering it as a SaaS without sharing your source. See [COMMERCIAL-LICENSE.md](./COMMERCIAL-LICENSE.md).

The design system in `packages/khulla_ui` stays [MIT](./packages/khulla_ui/LICENSE). Releases published before the switch to AGPL remain available under MIT. Contributions need the [Contributor License Agreement](./CLA.md).
