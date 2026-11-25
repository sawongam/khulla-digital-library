#!/usr/bin/env bash
# Prints the CHANGELOG.md section for one version - the release notes that
# the GitHub release, Google Play and the Microsoft Store all show.
#
#   tools/release_notes.sh 1.3.0          # the section as written
#   tools/release_notes.sh 1.3.0 --store  # without the "What's new:" line,
#                                         # which both stores already print
#
# Exits non-zero when the version has no section, or an empty one.
set -euo pipefail

version="${1:?usage: tools/release_notes.sh <version> [--store]}"
mode="${2:-}"
changelog="$(dirname "$0")/../CHANGELOG.md"

notes="$(awk -v heading="## $version" -v store="$mode" '
  $0 == heading { found = 1; next }
  found && /^## / { exit }
  found && store == "--store" && $0 == "What'\''s new:" { next }
  found {
    lines[++n] = $0
    if ($0 ~ /[^[:space:]]/) { if (!first) first = n; last = n }
  }
  END { if (first) for (i = first; i <= last; i++) print lines[i] }
' "$changelog")"

if [ -z "$notes" ]; then
  echo "CHANGELOG.md has no notes under \"## $version\"." >&2
  exit 1
fi

printf '%s\n' "$notes"
