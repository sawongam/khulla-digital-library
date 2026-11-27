# Demo data

A ready-made sample library so you can try Khulla with real-looking records
instead of an empty catalogue. All people, emails and phone numbers are fake.

| File | Use it on |
| --- | --- |
| `khulla-demo.sqlite` | Windows, Linux, macOS, Android, iOS |
| `khulla-demo.json` | Web (app.khulladigitallibrary.com) |

## Load it

1. Open Khulla and finish onboarding (any details — they get replaced).
2. Go to **Settings → Backup and restore**, and under **Restore from a
   backup** click **Choose a file**.
3. Pick the file for your platform.
4. Sign in with a demo account below.

Restoring **replaces everything** in the app. Don't do it on a library you
care about without exporting a backup first.

## Accounts

All passwords are `khulla@123`.

| Email | Role |
| --- | --- |
| `admin@khulladigitallibrary.com` | Administrator |
| `librarian@khulladigitallibrary.com` | Librarian |
| `assistant@khulladigitallibrary.com` | Assistant |

## What's inside

- **Khulla Demo Library**, Nepalese rupee, default loan rules
- 123 titles: classics, Nepali literature, Class 6–10 textbooks, journals,
  and reference-only items
- 262 copies: on loan, available, on the hold shelf, lost, and damaged
- 120 members: students, teachers, public and children, plus one archived
  and two suspended
- About 3,500 loans over the last ten months, around 110 still out, some overdue
- Overdue, lost, damage and membership fines: paid, waived, part-paid and
  outstanding
- Reservations waiting in queue, ready on the hold shelf, and closed

## Version

Built for **schema v16** (app 1.2.x). The web restore only accepts a file at
the app's exact schema version, so these files need regenerating whenever
the schema changes.

Dates were generated relative to 18 November 2026. Over time, the loans that
are still out will drift into overdue.
