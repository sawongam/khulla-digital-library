// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

/// How long an automatic check waits after the last one.
///
/// Elapsed time, not a calendar day: the throttle only has to keep a desk
/// machine that is opened twenty times a day from asking twenty times.
const Duration updateCheckInterval = Duration(hours: 24);

/// Whether a release at [releaseVersion]+[releaseBuild] is newer than the
/// running app at [runningVersion]+[runningBuild].
///
/// The build number decides: CI refuses a release into `prod` that has not
/// bumped it, and Android refuses an install whose `versionCode` did not
/// rise, so it only ever goes up. The dotted version is the fallback for a
/// running build that cannot report its number. A running version that
/// cannot be read at all is never offered an update - nagging an install
/// that does not know what it is helps nobody.
bool isNewerRelease({
  required String runningVersion,
  required int? runningBuild,
  required String releaseVersion,
  required int releaseBuild,
}) {
  if (runningBuild != null) return releaseBuild > runningBuild;

  final running = _parseVersion(runningVersion);
  final release = _parseVersion(releaseVersion);
  if (running == null || release == null) return false;
  for (var i = 0; i < 3; i++) {
    if (release[i] != running[i]) return release[i] > running[i];
  }
  return false;
}

/// Whether an automatic check should run now.
///
/// A [lastCheckedAt] in the future means the clock was wound back since; the
/// check runs rather than waiting out however far ahead the stamp is.
bool isUpdateCheckDue({
  required DateTime? lastCheckedAt,
  required DateTime now,
}) {
  if (lastCheckedAt == null || lastCheckedAt.isAfter(now)) return true;
  return now.difference(lastCheckedAt) >= updateCheckInterval;
}

/// `1.2.3` → `[1, 2, 3]`; anything after the third number (`-dev.abc`, a
/// `+build`) is ignored. Null when there are not three numbers to read.
List<int>? _parseVersion(String version) {
  final match = RegExp(r'^(\d+)\.(\d+)\.(\d+)').firstMatch(version.trim());
  if (match == null) return null;
  return [for (var i = 1; i <= 3; i++) int.parse(match.group(i)!)];
}
