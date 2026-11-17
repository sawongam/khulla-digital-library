# Research: backup sync, multi-device sync, and funding a server

> Status: **research draft for review** — 2026-11-17. Nothing here is decided.
> Figures marked *(verify)* came from secondary sources (blogs, aggregators) and
> should be confirmed on the vendor's own page before anyone relies on them.

## 1. The question

Khulla is local-first: one SQLite file per device, no server (ADR 0001). Two
things people will ask for:

1. **Off-device backup** — "if this laptop dies, the library doesn't lose its records."
2. **Sync between devices** — the front-desk Windows PC, the librarian's phone,
   the web app at home, all seeing the same catalogue.

Both need *somewhere* outside the device. The idea is to fund that somewhere
through open-source sponsorship, so libraries that can't pay still get it.

The short answer: **yes, it is doable, and the codebase is already in better
shape for it than most apps** — but "backup" and "sync" are very different
amounts of work, and circulation (two desks lending the same copy offline) is
the hard part, not the server.

---

## 2. What the codebase already gives us

Checked against the code, not assumed:

| Prerequisite for sync | State today | Where |
| --- | --- | --- |
| Globally unique IDs (no autoincrement collisions across devices) | ✅ Text UUID primary keys everywhere, `uuid` package, no `autoIncrement` | `titles.dart`, `members.dart`, `loans.dart`, … |
| `updatedAt` per row (needed for last-writer-wins) | ⚠️ Most tables have it; **`Loans` does not** (only `createdAt`, `returnedAt`) | `circulation/loan/data/tables/loans.dart` |
| Soft deletes / tombstones (a hard delete can't be synced) | ⚠️ `Members` has `archivedAt`, but there are ~7 hard-delete call sites | `grep '.delete(\|deleteWhere'` |
| Consistent snapshot export | ✅ `VACUUM INTO` on native, table dump on web, verified restore with `.pre-restore` fallback | `features/settings/data/backup_*` |
| Writes funnel through one layer | ✅ Every write goes Repository → LocalDataSource inside `guardDatabase` | Data layer section of `CLAUDE.md` |
| Business rules as pure functions | ✅ `circulation_rules.dart` — can be re-run when merging remote changes | `circulation/shared/domain/` |
| Trigger infrastructure | ✅ FTS tables are trigger-maintained; the same technique can fill a change log | `titles_fts.drift`, `members_fts.drift` |

**Things that will bite:**

- **Unique constraints across devices.** `Members.barcode` is `unique()`. Two
  offline desks registering members can mint the same barcode; sync then fails
  on the constraint, not on a "conflict". Same for any copy accession number.
- **Member data is sensitive.** `Members` carries date of birth, blood group,
  guardian, phone, address, ID verification — for school libraries, about
  minors. Whatever server we run should **never see this in plaintext** (see §4).
- **Staff password hashes and recovery codes** live in `Staff` /
  `StaffRecoveryCodes`. Syncing them is necessary for "sign in on any device",
  and is another reason for end-to-end encryption.
- **Schema version skew.** Device A on schema v16, device B on v17. The sync
  protocol must carry `schemaVersion` and refuse/hold changes a device can't
  apply — same spirit as the existing "refuse to open a newer schema" guard.

---

## 3. Options

Ordered roughly from least to most work.

### Option A — "Bring your own cloud" backup (no server at all)

Reuse the existing export. Add **scheduled automatic backups** to a folder,
plus optional direct upload targets.

- **Native (Windows/Linux/macOS):** just let the operator pick a folder that
  their Google Drive / OneDrive / Dropbox / Nextcloud desktop client already
  syncs. Write a timestamped `VACUUM INTO` snapshot there daily and keep the
  last N. *Zero* cloud code, zero server, zero cost. Never point a cloud client
  at the **live** file — only at snapshots.
- **Direct targets (works on web too):** WebDAV (Nextcloud, many NAS boxes), S3-
  compatible (Backblaze B2, Cloudflare R2, MinIO). Joplin proves this model:
  it supports Nextcloud, WebDAV, S3, Dropbox, OneDrive and local filesystem as
  sync targets, and only *optionally* sells its own cloud.
  Web caveat: the browser needs CORS on the target; many WebDAV servers need configuring.
- **Google Drive `appDataFolder`:** hidden per-app folder, counts against the
  user's own quota. Flutter packages exist (`local_first_gdrive_backup`,
  `drive_sync_flutter`, `locorda_gdrive`). Caveats: Google sign-in on Windows
  desktop/web is the painful part; OAuth app verification; and someone on
  Google's dev forum flagged a Workspace policy line about backing up app
  content to Drive — needs reading before shipping. *(verify)*

**Gives:** real disaster recovery. **Doesn't give:** live multi-device use —
at best "restore yesterday's catalogue on another machine", one-way.

**Effort:** small (days). **Cost to you:** $0. **Fits current architecture:**
perfectly — it's an extension of `BackupRepository`.

> Recommendation: **do this first regardless of everything else.** It solves
> the scariest problem (data loss) for every library today, and needs no money.

### Option B — Custom op-log sync with a thin relay server (the "Actual Budget" model)

Actual Budget is the closest open-source analogue to Khulla: local-first app,
SQLite on each device, and an optional, tiny, self-hostable sync server
(Node + SQLite, one Docker image) that only *relays* changes between devices.
Each local write is recorded as a message (table, row, column, value, hybrid
logical clock timestamp), applied locally, and pushed; devices pull others'
messages and merge per-field with last-writer-wins. Encryption is optional
and end-to-end — the server stores opaque blobs.

How it maps onto Khulla:

1. A `sync_changes` table filled by triggers on every synced table (we already
   do trigger-maintained tables for FTS), or written from data sources.
2. A hybrid logical clock (HLC) per device — not wall-clock time, because
   library PCs have wrong clocks.
3. Push/pull to a relay keyed by a **library ID** ("sync group"), with
   per-device tokens. Payloads encrypted client-side with a library key
   derived from a passphrase (or a QR code shown on an already-paired device).
4. Merge = apply remote changes, then **re-run domain rules** and surface
   anything that no longer holds (see §5).

**Server:** genuinely small. Could be Dart (`shelf`) so contributors only need
one language, or a Cloudflare Worker + Durable Object per library (one DO per
library is a natural fit for ordering messages; Cloudflare's Project Alexandria
gives OSS credits). Ship it as a Docker image too, so a library or a district
can self-host — that matters a lot for trust and for the FOSS pitch.

**Pros:** stays truly local-first; works on web/Windows/everything because it's
our Dart code over the existing drift DB; AGPL-clean end to end; E2EE means
the hosted service can't leak member data; hosting cost is tiny.
**Cons:** we own the sync correctness. CRDT/LWW is per-field, so it's chatty;
we need compaction/snapshots for new devices instead of replaying years of
messages.

**Effort:** medium-large (weeks to a couple of months for a solid v1). This is
the option I'd recommend for real sync.

### Option C — PowerSync (managed sync engine, Postgres in the middle)

PowerSync syncs a Postgres (or MongoDB/MySQL/SQL Server) backend into client
SQLite. Official Flutter SDK; drift support via `drift_sqlite_async`, listed
as **Beta** on their feature-status page. *(verify)*

- Licensing: client SDKs Apache-2.0/MIT; the **server is FSL** (Functional
  Source License — source-available, *not* OSI open source). A free
  self-hosted "Open Edition" exists. Cloud has a free tier and paid plans
  (~$49/mo Pro per an aggregator). *(verify)*
- Architecture change: Postgres becomes the source of truth. Writes are
  uploaded to **your own backend API**, which must re-validate them — so we'd
  need a real backend (rules duplicated or moved server-side), plus Postgres,
  plus the PowerSync service.
- Drift integration means swapping the connection to `sqlite_async`; our web
  setup (sqlite3 wasm + `drift_worker.js`) and `database_platform.dart`
  would need rework.

**Verdict:** powerful and mature for server-authoritative apps, but it's the
most infrastructure to run, the most architecture change, and an FSL
dependency in the core path is awkward for a project asking FOSS sponsors for
money. Not recommended for v1.

### Option D — ElectricSQL

There's an unofficial Dart client (`electricsql` on pub.dev) that integrates
with drift. However it targeted Electric's older design; Electric was
rewritten (read-path "shapes" over HTTP, writes are your own API). The Dart
port looks stale. *(verify activity on pub.dev/GitHub)* Same Postgres-in-the-
middle cost as PowerSync. **Not recommended.**

### Option E — Turso / libSQL embedded replicas

`libsql_dart` gives embedded replicas with `sync()`, but: it replaces our
`sqlite3`/drift executor with a Rust bridge, embedded replicas need a real
filesystem (**no web**, which is a primary target), and a libSQL commit from
April 2026 deprecates the `sync()` family of APIs in favour of a newer "Turso
Sync" with no Dart binding found. **Not a fit.**

### Option F — cr-sqlite (CRDT SQLite extension)

Elegant idea (multi-writer SQLite via CRDTs), but last push to the repo found
was **Oct 2024**, and loading a native extension on web/wasm and through drift
is non-trivial. Too risky to build a library's only records on. *(verify)*
Worth stealing ideas from, not depending on.

### Option G — PocketBase / Supabase as the backend

Straightforward BaaS with Dart SDKs; PocketBase runs on a tiny VPS, Supabase
self-hosted wants 4–8 GB RAM. *(verify)* But neither does offline sync — we'd
build the local cache and conflict handling anyway, *and* the server would
become the source of truth. That's a different product (cloud library system),
not local-first Khulla. Keep in mind only for a future "hosted multi-branch
edition".

### Option H — Sync the SQLite file with Syncthing/Dropbox

Don't. Syncing a live SQLite (especially WAL) file between two writers
corrupts it or silently drops one side. Only snapshots (Option A) are safe.

### Comparison

| | A. BYO-cloud backup | B. Op-log relay | C. PowerSync | G. BaaS |
| --- | --- | --- | --- | --- |
| Off-device backup | ✅ | ✅ | ✅ | ✅ |
| Live multi-device | ❌ | ✅ | ✅ | ✅ (online only) |
| Works on web | ✅ (WebDAV/S3/Drive) | ✅ | ⚠️ rework | ✅ |
| Stays local-first | ✅ | ✅ | ✅ | ❌ |
| Server sees member PII | user's own cloud | ❌ (E2EE) | ✅ | ✅ |
| Fully OSI open source | ✅ | ✅ | ❌ server is FSL | ✅ |
| Your hosting cost | $0 | low | medium | low–medium |
| Effort | days | weeks–months | weeks + backend | weeks + offline layer |

---

## 4. Privacy and trust (why E2EE matters here specifically)

A hosted sync service run by one maintainer, holding thousands of children's
names, birthdays and phone numbers, is a liability: legal (data protection
law in whichever country the library is), security, and reputational. With
end-to-end encryption the relay stores ciphertext only — if the server is
breached, nothing useful leaks, and you can honestly say "we can't read your
library". It also makes self-hosting optional rather than required for
privacy-conscious libraries. Trade-off: if a library loses its passphrase and
every device, the hosted copy is unrecoverable — the onboarding must make the
operator save a recovery key (we already have the recovery-code pattern for
staff).

---

## 5. The hard part: circulation conflicts

Catalogue edits merge fine with last-writer-wins (two people fixing a title's
spelling — last one wins, nobody cares). Circulation does not:

- Desk A and desk B, both offline, lend **the same copy** to two members.
- A member hits their borrowing limit on desk A while desk B also lends to them.
- Two devices mint the same member **barcode**.

No sync engine solves these for us — they're domain invariants. Options,
probably combined:

1. **Detect and surface, don't silently resolve.** After merge, re-run
   `circulation_rules.dart` checks; anything violated goes into a "Needs
   attention" list for staff (a real library resolves this by finding the book).
2. **Device-scoped identifiers** — barcode/accession sequences prefixed per
   device, or allocated in blocks, so they can't collide.
3. **A "primary desk" mode** — only one device does circulation; others are
   read-mostly (catalogue browsing, reports, member lookup). Much simpler and
   matches many small libraries' reality. Could be v1.
4. **Online-preferred circulation** — when the relay is reachable, circulation
   writes go through it first (a lightweight lock on the copy); offline still
   works, with conflicts surfaced as in (1).

Recommendation: ship v1 with (2) + (1), and offer (3) as a setting.

---

## 6. Funding the server

### What it would actually cost

For Option B, the relay stores small encrypted change messages per library.
Rough estimate *(mine, not measured)*: a few hundred small libraries fit on a
single $5–10/month VPS, or a Cloudflare Workers paid plan (~$5/month base) with
Durable Objects + R2 for snapshots. Hosting is not the expensive part —
**your time** (ops, support, on-call when a library can't sync) is. Fund that.

### Ways to raise money

| Channel | Notes |
| --- | --- |
| **GitHub Sponsors** | Lowest friction for devs. Reported: no fee on personal-account sponsorships, fees on org sponsorships. Add `.github/FUNDING.yml` (repo doesn't have one yet). *(verify fees)* |
| **Open Collective** | Transparent public ledger — "here's exactly what the sync server costs" is a strong pitch for a library tool. Fiscal hosts take ~up to 10%. Good for schools/NGOs that need invoices/receipts. *(verify)* |
| **Liberapay** | Recurring donations, very low/no platform fee; popular with FOSS. |
| **Polar** | ~7% all-in reported, but acts as merchant of record (handles tax/VAT) and can sell a "hosted sync" subscription directly. *(verify)* |
| **FLOSS/fund (Zerodha)** | Grants for FOSS projects globally; planned another $1M for 2026. You apply by publishing a `funding.json` manifest in the repo/site and submitting it to their directory. Reported grant sizes vary $10k–$100k *(verify)*. Strong fit for a South-Asian library tool. |
| **NLnet / NGI Zero** | €5k–50k grants historically; as of late 2026 NLnet says it is **temporarily not accepting proposals** while transitioning to a new "Open Internet Stack" effort. Watch for the next call. |
| **Cloudflare Project Alexandria** | OSS credits; Cloudflare also announced another $1M OSS funding in Aug 2026. Small projects can often run on the free tier anyway. |
| **Vultr Open Source Credits** | Launched Oct 2026. **DigitalOcean ended its OSS credits** program in Oct 2026 — don't plan on it. |
| **Local / sector grants** | Library associations, education NGOs, digital-public-goods programs, Rotary/Lions-type library drives — likely the most aligned money for a school-library tool. Worth separate research. |

### Product models that work for FOSS sync (precedents)

- **Joplin:** free sync to any of your own targets (Nextcloud, WebDAV, S3,
  Dropbox, OneDrive); optional paid Joplin Cloud (~€2.40–3/month) for people
  who don't want to configure anything. *(verify)*
- **Actual Budget:** free, self-hostable sync server only; hosted instances
  are provided by third parties (managed-hosting providers) rather than the project.
- Suggested for Khulla — **"free to self-host, free hosted for those who can't
  pay, sponsored by those who can"**:
  - Option A backup: free forever, in the app.
  - Sync server: AGPL, one Docker image, documented self-hosting.
  - Hosted Khulla Sync: free for small/under-resourced libraries; a modest
    sponsorship tier (or Polar subscription) for schools/orgs that can pay
    and need an invoice. Publish the running cost on Open Collective.

---

## 7. Suggested roadmap

1. **Now (no money needed):** scheduled auto-backup to a chosen folder +
   WebDAV/S3 target (Option A). Add `.github/FUNDING.yml` and `funding.json`.
   Write an ADR deciding sync approach.
2. **Schema groundwork (one migration batch):** `updatedAt` on `Loans`;
   tombstones instead of hard deletes on synced tables; per-device
   barcode/accession prefixes; a stable `libraryId` in `LibrarySettings`.
   All append-only migrations — cheap to do early, painful later.
3. **Sync v1 (Option B):** change log + HLC, E2EE, relay server + Docker
   image, device pairing via QR, "primary desk" circulation mode, conflict
   "needs attention" list.
4. **Hosted service:** stand it up once there's enough sponsorship to cover
   ~1 year of hosting + your time; apply to FLOSS/fund with sync as the
   funded milestone (grants like concrete deliverables).

## 8. Open questions for you

- Is multi-device mostly "one desk + a phone for lookups", or genuinely
  several desks lending at once? That decides how much of §5 v1 needs.
- Are target libraries mostly offline/patchy internet (pushes toward
  Option A + B with long offline windows)?
- Would you rather run the hosted relay yourself, or only ship self-host +
  BYO-cloud and let partners host it?
- Server language: Dart (one language for contributors) vs. TypeScript on
  Cloudflare Workers (cheapest hosting, credits available)?

## Sources

- PowerSync: [Open Edition release](https://powersync.com/blog/powersync-open-edition-release.md), [open-source/licensing](https://powersync.com/open-source), [feature status](https://docs.powersync.com/resources/feature-status.md), [pricing (aggregator)](https://toolradar.com/tools/powersync/pricing)
- Drift maintainer on sync: [simolus3/drift#2880](https://github.com/simolus3/drift/discussions/2880)
- ElectricSQL Dart client: [pub.dev/electricsql](https://pub.dev/documentation/electricsql/latest/)
- Turso/libSQL: [Flutter quickstart](https://docs.turso.tech/sdk/flutter/quickstart), [Flutter reference](https://docs.turso.tech/sdk/flutter/reference), [embedded replicas](https://docs.turso.tech/features/embedded-replicas), [libsql_dart](https://github.com/arlyon/libsql_dart)
- cr-sqlite: [GitHub](https://github.com/vlcn-io/cr-sqlite), [ecosyste.ms snapshot](https://awesome.ecosyste.ms/projects/github.com%2Fvlcn-io%2Fcr-sqlite)
- Actual Budget: [sync docs](https://actualbudget.org/docs/getting-started/sync/), [FAQ](https://actualbudget.org/docs/FAQ), [James Long — Using CRDTs in the wild](https://jlongster.com/using-crdts-in-the-wild)
- Joplin: [sync docs](https://joplinapp.org/help/apps/sync/), [WebDAV](https://joplinapp.org/help/apps/sync/webdav), [pricing summary](https://www.itechguides.com/is-joplin-free-what-joplin-cloud-sync-plans-include/)
- Google Drive app data: [Google docs](https://developers.google.com/workspace/drive/api/guides/appdata), [local_first_gdrive_backup](https://pub.dev/packages/local_first_gdrive_backup), [drive_sync_flutter](https://pub.dev/packages/drive_sync_flutter), [policy question](https://discuss.google.dev/t/policy-clarification-complete-android-app-data-recovery-using-drive-appdata/407046)
- PocketBase/Supabase: [Leanware comparison](https://leanware.co/insights/supabase-vs-pocketbase), [elest.io comparison](https://blog.elest.io/supabase-vs-appwrite-vs-pocketbase-which-open-source-backend-for-your-next-app/)
- Funding platforms: [2026 OSS funding deep dive](https://www.youngju.dev/blog/culture/2026-05-14-oss-funding-2026-github-sponsors-open-collective-polar-tidelift-ko-fi-developer-sponsorship-deep-dive.en), [GitHub Sponsors vs Open Collective fees](https://www.codenote.net/en/posts/github-sponsors-vs-open-collective-fees-comparison/), [Polar](https://tinystartups.com/tools/polar), [F-Droid forum on fees](https://forum.f-droid.org/t/donation-platform-with-lowest-fees/29422)
- FLOSS/fund: [The Register](https://www.theregister.com/2024/10/17/zerodha_open_source_fund/), [Zerodha 2025 report](https://zerodha.com/open-source/2025-report/), [grants listing](https://grantsdatabase.org/2026/01/19/floss-fund-a-global-funding-initiative-supporting-open-source-software/)
- NLnet: [funding page](https://nlnet.nl/funding.html), [2026 call notice](https://nlnet.nl/news/2026/20260601-call.html)
- Infra credits: [Cloudflare Project Alexandria](https://www.cloudflare.com/lp/project-alexandria), [Cloudflare community refresh](https://blog.cloudflare.com/community-program-refresh/), [DigitalOcean ends OSS credits](https://itsfoss.com/news/digitalocean-open-source-credits-end.md), [Vultr OSS credits](https://www.abiresearch.com/blog/vultr-open-source-ai-cloud)
