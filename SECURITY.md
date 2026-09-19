# Security policy

Khulla is a local-first app: the catalogue - titles, members, loans, fines - lives in a SQLite file on the library's own machine and is never uploaded anywhere. That design removes whole classes of risk, but the app still handles sensitive data (member records, staff credentials), so reports are welcome.

## Reporting a vulnerability

Please **do not open a public issue** for anything that could put a library's data at risk - authentication, password hashing, recovery codes, backup/restore, or anything that reads or writes outside the catalogue file.

Instead, use **GitHub's private vulnerability reporting** on this repository (Security tab → Report a vulnerability). It opens a private channel with the maintainers.

If private reporting is unavailable to you, open a regular issue with the sensitive details removed and say you have more to share privately.

## What to include

- The version from Settings → About (or `version:` in `pubspec.yaml` if you build from source)
- The platform (Windows, web, Linux, Android)
- Steps to reproduce, and what you expected to happen instead

## What happens next

Reports are read by the maintainers. There is no paid bounty program - Khulla is a volunteer open-source project - but every report gets a response and, where confirmed, a fix and credit in the release notes.
