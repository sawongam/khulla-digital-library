# Releasing

How a change on `dev` becomes something a librarian can download and run.

Everything here is GitHub Actions. There are no secrets to configure, no
signing certificates, and no deployment target to provision - Khulla is a
local-first app, so a release is four builds and a page to put them on.

## The workflows

| Workflow                                                     | Runs when                            | Does                                                                                                                       |
| ------------------------------------------------------------ | ------------------------------------ | -------------------------------------------------------------------------------------------------------------------------- |
| [`ci.yaml`](../../.github/workflows/ci.yaml)                 | Push to `dev`/`prod`, PR into either | `make ci` (format, copyright, analyze, test) and a web build; on a PR into `prod`, also checks the version has been bumped |
| [`release.yaml`](../../.github/workflows/release.yaml)       | Push to `prod`, or run by hand       | Builds Windows, Linux, Android and web; publishes a GitHub Release                                                         |
| [`deploy-web.yaml`](../../.github/workflows/deploy-web.yaml) | Push to `prod`, or run by hand       | Publishes the web build to GitHub Pages                                                                                    |

All three share [`.github/actions/setup-flutter`](../../.github/actions/setup-flutter/action.yml),
which installs the SDK version pinned in `.fvmrc`, resolves dependencies and
runs code generation. Generated sources are not committed, so no job can skip
that step.

CI runs `make ci`, not `make check`. They run the same gates; the difference is
that `make ci` fails on unformatted code rather than rewriting it on a runner
nobody will commit from.

## Cutting a release

**Landing on `prod` is the release.** There is no tag to push and no button to
press afterwards:

```
PR into prod (with the version bumped)  →  merge  →  release.yaml builds all
four targets  →  GitHub Release published, tagged v<version>
```

So the whole of releasing is one thing: **bump `version:` in `pubspec.yaml` in
the pull request that goes into `prod`.**

```yaml
version: 1.0.0+2 # <major>.<minor>.<patch>+<build>
```

Bump the build number as well as the version. Android refuses to install an APK
whose `versionCode` did not increase, and `+<build>` is where that comes from.

### One version, three readers

`version:` in `pubspec.yaml` is the only copy of the version, and everything
that needs the number reads that line or what the Flutter tool bakes from it:

| Reader                  | How                                                                                                                   |
| ----------------------- | --------------------------------------------------------------------------------------------------------------------- |
| The release workflow    | greps `^version:` out of `pubspec.yaml` - names the release and its tag                                               |
| CI, on a PR into `prod` | the same grep - fails the PR if that version is already released                                                      |
| The app                 | `package_info_plus` reads the baked-in version back at runtime (`AppVersion`); the help dialog's About panel shows it |

So the version a librarian reads in the app names the download they installed
and the tag you can check out. There is no second copy to update and no
codegen step to forget - bumping `version:` is enough, on every target,
because the Flutter tool carries it into the build.

The workflow reads that version, builds all four targets in parallel, checksums
them into `SHA256SUMS.txt`, and publishes a GitHub Release tagged `v1.0.0` with
generated notes and a download table. Roughly 15–25 minutes end to end. Nobody
creates the tag by hand - the release job does, and that tag is the record of
what shipped.

### When you merge without bumping

Nothing is published, and the run says so with a warning rather than a red
tick. The tag `v<version>` already exists, so re-releasing over it would change
what a download at that version contains - which is the one thing a version
number is supposed to rule out.

CI catches this earlier: a pull request into `prod` whose version is already
released **fails** its `Version bumped for release` check. Fix it while it is
still one commit, not one merge, away.

To ship a merge that landed without a bump, bump the version and merge again.

### What does _not_ release

- Merging into `dev`. Only `prod` releases.
- A push to `prod` that changes nothing else - same version, no release.
- A manual run of the workflow, whatever branch it is fired from.

## Sending someone a test build

From the **Actions** tab, pick **Release** → **Run workflow** → the branch you
want. It builds the same four targets and attaches them as workflow artifacts,
versioned `0.1.0-dev.<sha>`, and publishes nothing. Send the run's URL - anyone
signed into GitHub can download from it.

This is the way to get a build of unreleased work in front of a librarian. It
does not touch `prod`, the releases page, or the version.

## What each target produces

| Target  | Artifact                                 | Notes                                                                                                                                     |
| ------- | ---------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------- |
| Windows | `khulla-<version>-windows-x64-setup.exe` | Per-user installer (Inno Setup) - Start Menu entry + uninstaller, no admin required. Same build as the zip, just easier for normal users. |
| Windows | `khulla-<version>-windows-x64.zip`       | Portable fallback. Unzip anywhere and run `khulla.exe`. Useful when an installer is blocked.                                              |
| Android | `khulla-<version>-android.apk`           | One universal APK, not per-ABI splits - a tester sideloading should not need to know what an ABI is.                                      |
| Web     | `khulla-<version>-web.tar.gz`            | Built for the site root. Serve the extracted folder from any static host.                                                                 |
| Linux   | `khulla-<version>-linux-x64.tar.gz`      | Extract, run `./khulla`.                                                                                                                  |

Both Windows artifacts bundle the same `build/windows/x64/runner/Release/` output and
share the same data location (`%AppData%` / application-support directory), so a
library can switch from portable to installed without losing data. The installer
is defined in `windows/installer.iss` and built with Inno Setup (`iscc`) in the
`windows` job - no extra secrets needed until code-signing is added. SmartScreen
still warns about an unknown publisher while the binaries are unsigned.

macOS and iOS build from the same source but are not released: both need an
Apple Developer account to produce anything a user can open.

## The web demo

`deploy-web.yaml` publishes to GitHub Pages on every push to `prod`. It needs
one manual step, once: **Settings → Pages → Source: GitHub Actions**.

It is built with `--base-href /<repo>/`, because a project site is served from
a subpath. Routing uses the hash strategy (`/#/catalog`), which deep-links
correctly on Pages with no rewrite rules; switching to path URLs would mean
calling `usePathUrlStrategy()` _and_ configuring a server-side rewrite to
`index.html`. See [ADR 0005](../architecture/decisions/0005-gorouter-for-navigation.md).

Treat it as a demo, not a service. The catalogue lives in the browser's own
storage, so every visitor gets a fresh empty library and clearing site data
wipes it.

## Signing, when it matters

Both desktop and Android ship unsigned today, which is honest for a pre-1.0
open-source tool a librarian installs deliberately. It costs the user one
"unknown publisher" dialog.

Signing becomes worth the cost when Khulla goes on Google Play (which refuses
debug keys outright) or when the SmartScreen warning starts costing installs.
Both follow the same shape: put the key in repository secrets, decode it in the
job, and point the build at it.

- **Android** - replace the debug `signingConfig` in
  `android/app/build.gradle.kts` with one reading a `key.properties` file, and
  write that file in the `android` job from a base64 secret.
- **Windows** - sign `build/windows/x64/runner/Release/khulla.exe` with
  `signtool` before the packaging step, using an EV or OV code-signing
  certificate.

Do not commit a keystore, a certificate, or a password. If a key does get
committed, rotate it - a rewrite of history is not a revocation.
