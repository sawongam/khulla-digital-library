# Releasing

How a change on `dev` becomes something a librarian can download and run.

Everything here is GitHub Actions. Khulla is a local-first app, so a release
is four builds, a page to put them on, and an upload to each store. The only
secrets are signing keys and store credentials, listed under
[Store uploads](#store-uploads) and [Signing the APK](#signing-the-apk).

## The workflows

| Workflow                                                     | Runs when                            | Does                                                                                                                       |
| ------------------------------------------------------------ | ------------------------------------ | -------------------------------------------------------------------------------------------------------------------------- |
| [`ci.yaml`](../../.github/workflows/ci.yaml)                 | Push to `dev`/`prod`, PR into either | `make ci` (format, copyright, analyze, test) and a web build; on a PR into `prod`, also checks the version and build number were bumped and `CHANGELOG.md` has notes for it |
| [`release.yaml`](../../.github/workflows/release.yaml)       | Push to `prod`, or run by hand       | Builds Windows, Linux, Android and web; publishes a GitHub Release; uploads to Google Play and the Microsoft Store         |
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
PR into prod (version bumped, notes written)  →  merge  →  release.yaml builds
all four targets  →  GitHub Release, tagged v<version>  →  Google Play and
Microsoft Store submissions
```

So the whole of releasing is two things in the pull request that goes into
`prod`:

1. **Bump `version:` in `pubspec.yaml`** - both halves.

   ```yaml
   version: 1.0.0+2 # <major>.<minor>.<patch>+<build>
   ```

   The Store reads only `<major>.<minor>.<patch>`, and Play and Android only
   `+<build>` (the `versionCode`). Each refuses a number it has seen, so both
   have to climb. CI checks both.

2. **Add the version's notes to `CHANGELOG.md`**, at the top:

   ```md
   ## 1.3.0

   What's new:
   - Renew a loan from the member page
   - Fixed fines showing twice
   ```

   Written by hand, for librarians, not a commit log. The same text is the
   GitHub release page, Play's *What's new* and the Store's *What's new in
   this version*, so keep it short. Play allows 500 characters and CI fails
   the PR above that. Read it back with `tools/release_notes.sh <version>`.

Keep upcoming notes under `## Unreleased` while you work, and rename the
heading to the version when you bump it.

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
them into `SHA256SUMS.txt`, writes the update manifest `latest.json` (see
[How installed copies update](#how-installed-copies-update)), and publishes a
GitHub Release tagged `v1.0.0` whose body is the `CHANGELOG.md` notes and a
short list of where to get each build. Roughly 15–25 minutes end to end. Nobody
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
| Windows | `khulla-<version>-windows-x64-store.msix` | **Not on the release page.** A workflow artifact (`microsoft-store`) the release submits to Partner Center - see [Store uploads](#store-uploads). |
| Android | `khulla-<version>-android.aab` | **Not on the release page.** A workflow artifact (`google-play`), signed with the upload key, the release uploads to Play - see [Store uploads](#store-uploads). |
| Android | `khulla-<version>-android.apk`           | For phones without Google Play, which the release notes recommend first. One universal APK, signed with the sideload key - see below.     |
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

## How installed copies update

Every release carries `latest.json`, and every installed copy finds it at
`<repo>/releases/latest/download/latest.json` - a plain redirect to the newest
non-prerelease, with none of the REST API's per-address rate limit. The app
compares the release's `build` with its own `+build` and, from **Account menu
→ Check for updates** (or on its own once a day, which the dialog can switch
off), does what fits how it was installed:

| Installed from                | What *update* does                                                                                                                                                                                                                  |
| ----------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Windows installer             | Downloads the next `setup.exe`, checks its SHA-256 and size against `latest.json`, snapshots the catalogue into `backups/` beside it, starts the installer with `/SILENT /UPDATE=1` and exits. The installer reopens the app. |
| Microsoft Store               | Never asks GitHub, for the same reason as Play. Opens the Store's *Downloads and updates* page; the Store installs the update itself. Told apart by running from under `WindowsApps`.                                            |
| Windows portable zip, Linux   | Says a newer version exists and opens the release page. Replacing files wherever the folder happens to live is not safe.                                                                                                           |
| Web                           | Compares the server's `version.json` (written by `flutter build web`) with the running build, and offers a reload.                                                                                                                  |
| Android (Google Play)         | Never asks GitHub - Play reviews a build after the release lands, so GitHub would announce an update Play cannot deliver yet. Opens the store listing.                                                                              |
| Android (release-page APK)    | Says a newer version exists and opens the release page, to install the new APK over the old one. Android records who installed the app, which is how it is told apart from a Play install.                                       |

`latest.json` is a contract with every build ever shipped. `version`, `build`
and `notes` must never change meaning; anything new is an added field, which
old readers ignore. The installer is told apart from the portable zip by
`unins000.exe` beside `khulla.exe`.

**The updater only helps from the release that contains it.** An install
older than that has to be updated by hand once.

Google Play and the Microsoft Store are uploaded to by the release itself -
see [Store uploads](#store-uploads).

## Signing the APK

Android installs an APK over an existing install only when both are signed
with the same key. A GitHub runner's debug key is generated fresh on every
run, so a debug-signed APK can never update the previous release's - the
only way forward is uninstalling, which deletes the library's data on that
phone. The release APK is therefore signed with one **sideload key**, kept in
repository secrets and never changed.

Use a key of its own, not the Play upload key: the APK and the Play build
cannot update each other anyway (Play re-signs with its app signing key). The
upload key is a separate set of secrets - see [Store uploads](#store-uploads).
If it ever leaks, Play can reset it; the sideload key cannot be replaced.

Once:

```sh
keytool -genkeypair -v -keystore sideload-keystore.jks -alias sideload \
  -keyalg RSA -keysize 4096 -validity 36500
base64 -w0 sideload-keystore.jks   # the value of ANDROID_KEYSTORE_BASE64
```

Add four repository secrets (**Settings → Secrets and variables → Actions**):
`ANDROID_KEYSTORE_BASE64`, `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_ALIAS`
(`sideload`), `ANDROID_KEY_PASSWORD`. Keep the `.jks` and its passwords
somewhere safe off GitHub too: **losing the key means every APK install has to
be uninstalled to take the next release.**

Without the secrets the `android` job warns and falls back to the debug key.
APKs from before the key existed were debug-signed, so their users have to
back up, uninstall and reinstall once.

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

## Store uploads

After the GitHub release is published, two jobs submit the same version to the
stores. They run after the release on purpose: a store outage or a refused
submission never holds back the downloads, and either job can be re-run on
its own from the run page.

| Job               | Uploads                                     | Notes from                    | Then                                    |
| ----------------- | ------------------------------------------- | ----------------------------- | --------------------------------------- |
| `google-play`     | the app bundle, signed with the upload key  | `CHANGELOG.md` → *What's new* | Play reviews it, then rolls it out      |
| `microsoft-store` | the MSIX                                    | `CHANGELOG.md` → every listing language's *What's new in this version* | Certification, usually 1-3 days |

Each is skipped until it is set up, and the rest of the release ships
regardless.

### Google Play, once

1. **Upload key.** Base64 the `.jks` you already upload to Play with
   (`base64 -w0 khulla-upload-keystore.jks`) and add four secrets:
   `ANDROID_UPLOAD_KEYSTORE_BASE64`, `ANDROID_UPLOAD_KEYSTORE_PASSWORD`,
   `ANDROID_UPLOAD_KEY_ALIAS`, `ANDROID_UPLOAD_KEY_PASSWORD`. Without them the
   `android` job builds no app bundle.
2. **Service account.** In Google Cloud, create a project (or reuse one),
   enable the **Google Play Android Developer API**, create a service account
   and download a JSON key for it.
3. In the **Play Console → Users and permissions**, invite the service
   account's email and give it the app with *Release to production, exclude
   devices, and use Play App Signing* (and *Release apps to testing tracks*).
4. Add the JSON file's whole contents as the secret
   `GOOGLE_PLAY_SERVICE_ACCOUNT_JSON`.
5. Add the variable `GOOGLE_PLAY_TRACK`: `production`, or `internal` /
   `beta` to try the pipeline first. Setting it is what switches the job on.

### Microsoft Store, once

1. In the **Microsoft Entra admin center**, register an app (single tenant)
   and create a client secret under *Certificates & secrets*. Note its expiry:
   when it expires, the job fails until the secret is replaced.
2. In **Partner Center → Account settings → User management → Microsoft
   Entra applications**, add that app and give it the **Manager** role. (The
   Partner Center account has to be associated with the Entra tenant first,
   under *Tenants*.)
3. Add four secrets: `MS_STORE_TENANT_ID` (the Entra tenant ID),
   `MS_STORE_SELLER_ID` (Partner Center → Account settings → *Legal info* →
   Seller ID), `MS_STORE_CLIENT_ID` (the app's client ID) and
   `MS_STORE_CLIENT_SECRET`.
4. Add the variable `MS_STORE_PRODUCT_ID`: `9NPZBD22X2L7`, the ID in the
   Store link. Setting it is what switches the job on, and the release page's
   Store link reads it too.

The job uploads the package as a draft with `msstore publish`, writes the
notes into the submission with `msstore submission update`, and submits it
with `msstore submission publish`. A submission already pending in Partner
Center is replaced.

## Microsoft Store

The Store build exists because **Smart App Control** blocks the unsigned
installer outright. Unlike SmartScreen, it has no *Run anyway*. The Store
signs the package on certification, so a Store install runs wherever Smart
App Control is on.

**One-time setup**

1. Open a Partner Center developer account (free for individuals) and
   reserve the app name.
2. In the product, open **Product management → Product identity**. Copy three
   values into **repository variables** (Settings → Secrets and variables →
   Actions → *Variables*). They are public, so they are not secrets:

   | Variable                      | Product identity field          |
   | ----------------------------- | ------------------------------- |
   | `MSIX_IDENTITY_NAME`          | `Package/Identity/Name`         |
   | `MSIX_PUBLISHER`              | `Package/Identity/Publisher` (`CN=…`) |
   | `MSIX_PUBLISHER_DISPLAY_NAME` | `Package/Properties/PublisherDisplayName` |

Until `MSIX_IDENTITY_NAME` is set, the release skips the Store package and
builds everything else.

**Each release**

The `windows` job packages the same `Release/` folder with
`dart run msix:create`. The config is `msix_config` in `pubspec.yaml`. The job
uploads the result as the `microsoft-store` artifact, and the
`microsoft-store` job submits it - see [Store uploads](#store-uploads). The
package version is `<major>.<minor>.<patch>.0` from `version:`.

To build one locally on Windows:

```sh
flutter build windows --release -t lib/main_prod.dart
dart run msix:create --identity-name <…> --publisher "CN=…" --publisher-display-name "<…>"
```

**Data and uninstall.** A packaged app's writes under `%AppData%` are
redirected into the package's own folder. Windows deletes that folder when
the app is uninstalled, so uninstalling the Store app takes the catalogue
with it. This is unlike the installer and the zip. The Store listing and the
guide must tell libraries to export a backup first. The same redirection
means a Store install and an installer install on the same machine may not
see the same catalogue. Move between them with Settings → Backup.

## Signing, when it matters

The Windows build ships unsigned today, which is honest for a pre-1.0
open-source tool a librarian installs deliberately. It costs the user one
"unknown publisher" dialog. Android is signed: the release APK with the
sideload key (above), the Play build with the upload key.

That stopped being true with **Smart App Control**, on by default on many
fresh Windows 11 installs. It blocks an unsigned `khulla.exe` with no way
past, so the installer and the zip cannot run there at all. The
[Microsoft Store](#microsoft-store) build is the route around it until the
releases are signed. The plan is the SignPath Foundation's free open-source
certificate; the publisher would then read *SignPath Foundation*.

To sign: sign `build/windows/x64/runner/Release/khulla.exe` before the
packaging step, so the zip and the installer both carry the signed exe. Then
sign the installer itself. (The in-app updater is not affected
either way - a file the app downloads itself carries no mark-of-the-web.)

Do not commit a keystore, a certificate, or a password. If a key does get
committed, rotate it - a rewrite of history is not a revocation.
